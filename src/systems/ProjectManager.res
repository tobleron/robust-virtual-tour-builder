/* src/systems/ProjectManager.res - Consolidated Project Manager System */

open ReBindings
open Types

// --- TYPES ---

type onProgress = (int, int, string) => unit
type apiError = string

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

let saveProject = (state: state, ~signal=?, ~onProgress: option<onProgress>=?) => {
  if Array.length(state.scenes) == 0 {
    Promise.resolve(false)
  } else {
    OperationJournal.startOperation(
      ~operation="SaveProject",
      ~context=asJson({
        "sceneCount": Array.length(state.scenes),
        "tourName": state.tourName,
      }),
      ~retryable=true,
    )->Promise.then(journalId => {
      Logger.debug(
        ~module_="ProjectManager",
        ~message="SAVE_OPERATION_LOGGED",
        ~data=Some(Logger.castToJson({"journalId": journalId})),
        (),
      )
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

      let saveStartTime = Date.now()
      handlePromise
      ->Promise.then(fileHandle => {
        // Progress starts AFTER the file handle (confirmation) is received
        let progress = (curr, total, msg) => {
          switch onProgress {
          | Some(cb) => cb(curr, total, msg)
          | None => ()
          }
        }
        progress(0, 100, "Initializing save...")

        // Delegate to Logic.createSavePackage (which delegates to ProjectSaver)
        Logic.createSavePackage(state, ~signal?, ~onProgress?)->Promise.then(
          resultRes => {
            switch resultRes {
            | Ok(blob) =>
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
                    OperationJournal.failOperation(
                      journalId,
                      "Save failed during file write",
                    )->Promise.then(() => Promise.resolve(success))
                  }
                },
              )
            | Error(msg) =>
              if String.includes(msg, "AbortError") {
                OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
                  () => Promise.resolve(false),
                )
              } else {
                OperationJournal.failOperation(journalId, msg)->Promise.then(
                  () => Promise.resolve(false),
                )
              }
            }
          },
        )
      })
      ->Promise.catch(exn => {
        let (msg, _) = Logger.getErrorDetails(exn)
        if String.includes(msg, "AbortError") {
          OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
            () => {
              Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED_PICKER", ())
              Promise.resolve(false)
            },
          )
        } else {
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
  (_entry: OperationJournal.journalEntry) => {
    let waitForStateUpdate = () => {
      Promise.make((resolve, _reject) => {
        let unsubscribeRef = ref(() => ())
        let timerId: ref<int> = ref(0)

        let callback = (newState: state) => {
          if Array.length(newState.scenes) > 0 {
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

    let restorePromise = if Array.length(state.scenes) > 0 {
      Promise.resolve(Some(state))
    } else {
      PersistenceLayer.checkRecovery()->Promise.then(recovery => {
        switch recovery {
        | Some(session) =>
          dispatch(Actions.LoadProject(session.projectData))
          waitForStateUpdate()->Promise.then(s => Promise.resolve(Some(s)))
        | None => Promise.resolve(None)
        }
      })
    }

    restorePromise->Promise.then(finalStateOpt => {
      switch finalStateOpt {
      | Some(finalState) => saveProject(finalState)
      | None => Promise.resolve(false)
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
