/* src/systems/ProjectManager.res - Consolidated Project Manager System */

open ReBindings
open Types

// --- TYPES ---

type onProgress = (int, int, string) => unit
type apiError = string
type saveRecoveryContext = {
  sceneCount: option<int>,
  tourName: option<string>,
}

// --- INTERNAL LOGIC ---

module Logic = {
  external asJson: 'a => JSON.t = "%identity"

  // Duplicated to match snapshot signature
  let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    field.required("validationReport", JsonParsers.Shared.validationReport)
  })

  let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
    ProjectSystem.validateProjectStructure(data)
  }

  let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
    result<Blob.t, apiError>,
  > => {
    ProjectSystem.createSavePackage(state, ~signal?, ~onProgress?)
  }

  let processLoadedProjectData = (
    resultSessionData: result<(string, JSON.t), apiError>,
    ~loadStartTime: float,
    ~onProgress: option<onProgress>=?,
  ): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
    ProjectSystem.processLoadedProjectData(resultSessionData, ~loadStartTime, ~onProgress?)
  }

  let loadProjectZip = (
    zipFile: File.t,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onProgress: option<onProgress>=?,
  ) => {
    ProjectSystem.loadProjectZip(zipFile, ~signal?, ~onProgress?)
  }
}

// --- FACADE ---

external asJson: 'a => JSON.t = "%identity"

let saveRecoveryContextDecoder = JsonCombinators.Json.Decode.object((
  field
): saveRecoveryContext => {
  {
    sceneCount: field.optional("sceneCount", JsonCombinators.Json.Decode.int),
    tourName: field.optional("tourName", JsonCombinators.Json.Decode.string),
  }
})

let updateSaveContext = (
  ~journalId: string,
  ~state: state,
  ~stage: string,
  ~filename: option<string>=?,
  ~error: option<string>=?,
) => {
  OperationJournal.updateContext(
    journalId,
    asJson({
      "sceneCount": Array.length(state.scenes),
      "tourName": state.tourName,
      "stage": stage,
      "filename": filename->Option.getOr(""),
      "error": error->Option.getOr(""),
      "timestamp": Date.now(),
    }),
  )
}

let classifySaveError = (msg: string) => {
  let lowered = msg->String.toLowerCase
  if String.includes(msg, "AbortError") || String.includes(lowered, "aborted") {
    ("cancelled", "Save cancelled by user.")
  } else if String.includes(msg, "TimeoutError") || String.includes(lowered, "timed out") {
    ("timeout", "Save request timed out while communicating with backend. Please try again.")
  } else if (
    String.includes(lowered, "no space left") ||
    String.includes(lowered, "quota") ||
    String.includes(lowered, "disk")
  ) {
    ("disk", "Save failed because storage appears full or unavailable. Free up space and retry.")
  } else if (
    String.includes(lowered, "network") ||
    String.includes(lowered, "failed to fetch") ||
    String.includes(lowered, "httperror") ||
    String.includes(lowered, "http error")
  ) {
    ("network", "Save failed due to a backend/network issue. Please retry in a moment.")
  } else if (
    String.includes(lowered, "notallowederror") || String.includes(lowered, "securityerror")
  ) {
    ("permission", "Save failed because file write permission was rejected.")
  } else {
    ("unknown", "Save failed due to an unexpected error. Please retry.")
  }
}

let notifySaveFailure = (~message: string, ~details: string) => {
  NotificationManager.dispatch({
    id: "",
    importance: Error,
    context: Operation("project_save"),
    message,
    details: Some(details),
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Error),
    dismissible: true,
    createdAt: Date.now(),
  })
}

let saveProject = (state: state, ~signal=?, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Logger.warn(~module_="ProjectManager", ~message="SAVE_SKIPPED_NO_SCENES", ())
    Promise.resolve(false)
  } else {
    let saveStartTime = Date.now()
    let tourName = if state.tourName == "" {
      "Virtual_Tour"
    } else {
      state.tourName
    }
    let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
    let dateParts = String.split(Date.toISOString(Date.make()), "T")
    let dateStr = Belt.Array.get(dateParts, 0)->Option.getOr("unknown_date")
    let filename =
      "Saved_RMX_" ++ safeName ++ "_v" ++ Version.version ++ "_" ++ dateStr ++ ".vt.zip"

    Logger.startOperation(
      ~module_="ProjectManager",
      ~operation="PROJECT_SAVE",
      ~data=Some({
        "sceneCount": Array.length(state.scenes),
        "tourName": tourName,
        "filename": filename,
      }),
      (),
    )

    OperationJournal.startOperation(
      ~operation="SaveProject",
      ~context=asJson({
        "sceneCount": Array.length(state.scenes),
        "tourName": state.tourName,
        "filename": filename,
        "stage": "started",
      }),
      ~retryable=true,
    )->Promise.then(journalId => {
      Logger.debug(
        ~module_="ProjectManager",
        ~message="SAVE_OPERATION_LOGGED",
        ~data=Some(Logger.castToJson({"journalId": journalId})),
        (),
      )
      let useFileHandle = %raw(`typeof window.showSaveFilePicker !== 'undefined'`)
      let handlePromise = if useFileHandle {
        DownloadSystem.getFileHandle(filename, "application/zip")
        ->Promise.then(h => Promise.resolve(Some(h)))
        ->Promise.catch(exn => {
          let (msg, _) = Logger.getErrorDetails(exn)
          if String.includes(msg, "AbortError") {
            Promise.reject(exn)
          } else {
            Promise.resolve(None)
          }
        })
      } else {
        Promise.resolve(None)
      }

      handlePromise
      ->Promise.then(fileHandle => {
        let _ = updateSaveContext(~journalId, ~state, ~stage="handle_ready", ~filename)

        // Progress starts after file handle confirmation
        let progress = (curr, total, msg) => {
          switch onProgress {
          | Some(cb) => cb(curr, total, msg)
          | None => ()
          }
        }
        progress(0, 100, "Initializing save...")

        let _ = updateSaveContext(~journalId, ~state, ~stage="packaging", ~filename)

        Logic.createSavePackage(state, ~signal?, ~onProgress?)->Promise.then(
          resultRes => {
            switch resultRes {
            | Ok(blob) =>
              let _ = updateSaveContext(~journalId, ~state, ~stage="writing_file", ~filename)
              if useFileHandle {
                switch fileHandle {
                | Some(h) =>
                  DownloadSystem.writeFileToHandle(h, blob)->Promise.then(
                    () => Promise.resolve(true),
                  )
                | None =>
                  // This can only happen if useFileHandle was true but handle was skipped (not AbortError)
                  DownloadSystem.saveBlob(blob, filename)
                  Promise.resolve(true)
                }
              } else {
                DownloadSystem.saveBlob(blob, filename)
                Promise.resolve(true)
              }->Promise.then(
                success => {
                  if success {
                    let _ = updateSaveContext(~journalId, ~state, ~stage="completed", ~filename)
                    OperationJournal.completeOperation(journalId)->Promise.then(
                      () => {
                        Logger.endOperation(
                          ~module_="ProjectManager",
                          ~operation="PROJECT_SAVE",
                          ~data=Some({"durationMs": Date.now() -. saveStartTime}),
                          (),
                        )
                        Promise.resolve(success)
                      },
                    )
                  } else {
                    let reason = "Save failed during file write"
                    let _ = updateSaveContext(
                      ~journalId,
                      ~state,
                      ~stage="failed",
                      ~filename,
                      ~error=reason,
                    )
                    notifySaveFailure(~message="Project save failed", ~details=reason)
                    OperationJournal.failOperation(journalId, reason)->Promise.then(
                      () => Promise.resolve(success),
                    )
                  }
                },
              )
            | Error(msg) =>
              if String.includes(msg, "AbortError") {
                let _ = updateSaveContext(
                  ~journalId,
                  ~state,
                  ~stage="cancelled",
                  ~filename,
                  ~error=msg,
                )
                OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
                  () => {
                    Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED", ())
                    Promise.resolve(false)
                  },
                )
              } else {
                let (_, userMessage) = classifySaveError(msg)
                let _ = updateSaveContext(
                  ~journalId,
                  ~state,
                  ~stage="failed",
                  ~filename,
                  ~error=msg,
                )
                notifySaveFailure(~message=userMessage, ~details=msg)
                OperationJournal.failOperation(journalId, msg)->Promise.then(
                  () => {
                    Logger.error(
                      ~module_="ProjectManager",
                      ~message="SAVE_FAILED_PACKAGE",
                      ~data={"error": msg},
                      (),
                    )
                    Promise.resolve(false)
                  },
                )
              }
            }
          },
        )
      })
      ->Promise.catch(exn => {
        let (msg, _) = Logger.getErrorDetails(exn)
        if String.includes(msg, "AbortError") {
          let _ = updateSaveContext(~journalId, ~state, ~stage="cancelled", ~filename, ~error=msg)
          OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
            () => {
              Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED_PICKER", ())
              Promise.resolve(false)
            },
          )
        } else {
          let (_, userMessage) = classifySaveError(msg)
          let _ = updateSaveContext(~journalId, ~state, ~stage="failed", ~filename, ~error=msg)
          notifySaveFailure(~message=userMessage, ~details=msg)
          OperationJournal.failOperation(journalId, msg)->Promise.then(
            () => {
              Logger.error(
                ~module_="ProjectManager",
                ~message="SAVE_FAILED",
                ~data={"error": msg},
                (),
              )
              Promise.resolve(false)
            },
          )
        }
      })
    })
  }
}

let recoverSaveProject = (
  ~getState: unit => state,
  ~dispatch: Actions.action => unit,
  ~subscribe: (state => unit) => unit => unit,
) =>
  (entry: OperationJournal.journalEntry) => {
    let expectedSceneCount = switch JsonCombinators.Json.decode(
      entry.context,
      saveRecoveryContextDecoder,
    ) {
    | Ok(decoded) => decoded.sceneCount
    | Error(_) => None
    }

    let hasRecoverableScenes = (candidate: state) => {
      let count = Array.length(candidate.scenes)
      switch expectedSceneCount {
      | Some(expected) => expected > 0 && count >= expected
      | None => count > 0
      }
    }

    let waitForStateUpdate = () => {
      Promise.make((resolve, _reject) => {
        let unsubscribeRef = ref(() => ())
        let timerId: ref<int> = ref(0)

        let callback = (newState: state) => {
          if hasRecoverableScenes(newState) {
            unsubscribeRef.contents()
            DomBindings.Window.clearTimeout(timerId.contents)
            resolve(newState)
          }
        }

        unsubscribeRef := subscribe(callback)

        timerId := DomBindings.Window.setTimeout(() => {
            unsubscribeRef.contents()
            resolve(getState())
          }, 5000)
      })
    }

    let state = getState()
    Logger.info(
      ~module_="ProjectManager",
      ~message="SAVE_RECOVERY_START",
      ~data=Some({
        "entryId": entry.id,
        "expectedSceneCount": expectedSceneCount->Option.getOr(-1),
        "currentSceneCount": Array.length(state.scenes),
      }),
      (),
    )

    let restorePromise = if hasRecoverableScenes(state) {
      Promise.resolve(Some(state))
    } else {
      PersistenceLayer.checkRecovery()->Promise.then(recovery => {
        switch recovery {
        | Some(session) =>
          Logger.info(
            ~module_="ProjectManager",
            ~message="SAVE_RECOVERY_RESTORE_SESSION",
            ~data=Some({"entryId": entry.id}),
            (),
          )
          dispatch(Actions.LoadProject(session.projectData))
          waitForStateUpdate()->Promise.then(s => Promise.resolve(Some(s)))
        | None =>
          Logger.warn(
            ~module_="ProjectManager",
            ~message="SAVE_RECOVERY_NO_SESSION",
            ~data=Some({"entryId": entry.id}),
            (),
          )
          Promise.resolve(None)
        }
      })
    }

    restorePromise->Promise.then(finalStateOpt => {
      switch finalStateOpt {
      | Some(finalState) =>
        Logger.info(
          ~module_="ProjectManager",
          ~message="SAVE_RECOVERY_RETRY",
          ~data=Some({"entryId": entry.id, "sceneCount": Array.length(finalState.scenes)}),
          (),
        )
        saveProject(finalState)
      | None =>
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: SystemEvent("recovery"),
          message: "Unable to recover interrupted save. Please save again manually.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
        Promise.resolve(false)
      }
    })
  }

let loadProject = (
  zipFile: File.t,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onProgress: option<onProgress>=?,
): Promise.t<BackendApi.apiResult<(string, JSON.t)>> => {
  Logic.loadProjectZip(zipFile, ~signal?, ~onProgress?)
}
