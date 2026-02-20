open Types

type onProgress = (int, int, string) => unit

external asJson: 'a => JSON.t = "%identity"

let saveProject = (
  state: state,
  ~signal=?,
  ~onProgress: option<onProgress>=?,
  ~opId: option<OperationLifecycle.operationId>=?,
) => {
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

    opId->Option.forEach(id =>
      OperationLifecycle.progress(id, 0.0, ~message="Preparing save...", ~phase="Initializing", ())
    )

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
        let _ = ProjectUtils.updateSaveContext(~journalId, ~state, ~stage="handle_ready", ~filename)

        // Progress starts after file handle confirmation
        let progress = (curr, total, msg) => {
          opId->Option.forEach(
            id => {
              let pct = if total > 0 {
                Float.fromInt(curr) /. Float.fromInt(total) *. 100.0
              } else {
                0.0
              }
              OperationLifecycle.progress(id, pct, ~message=msg, ())
            },
          )
          switch onProgress {
          | Some(cb) => cb(curr, total, msg)
          | None => ()
          }
        }
        progress(0, 100, "Initializing save...")

        let _ = ProjectUtils.updateSaveContext(~journalId, ~state, ~stage="packaging", ~filename)

        ProjectUtils.Logic.createSavePackage(state, ~signal?, ~onProgress?, ~opId?)->Promise.then(
          resultRes => {
            switch resultRes {
            | Ok(blob) =>
              let _ = ProjectUtils.updateSaveContext(
                ~journalId,
                ~state,
                ~stage="writing_file",
                ~filename,
              )
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
                    let _ = ProjectUtils.updateSaveContext(
                      ~journalId,
                      ~state,
                      ~stage="completed",
                      ~filename,
                    )
                    opId->Option.forEach(id => OperationLifecycle.complete(id, ~result="Saved", ()))

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
                    let _ = ProjectUtils.updateSaveContext(
                      ~journalId,
                      ~state,
                      ~stage="failed",
                      ~filename,
                      ~error=reason,
                    )
                    ProjectUtils.notifySaveFailure(~message="Project save failed", ~details=reason)
                    opId->Option.forEach(id => OperationLifecycle.fail(id, reason))
                    OperationJournal.failOperation(journalId, reason)->Promise.then(
                      () => Promise.resolve(success),
                    )
                  }
                },
              )
            | Error(msg) =>
              if String.includes(msg, "AbortError") {
                let _ = ProjectUtils.updateSaveContext(
                  ~journalId,
                  ~state,
                  ~stage="cancelled",
                  ~filename,
                  ~error=msg,
                )
                opId->Option.forEach(id => OperationLifecycle.cancel(id))
                OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
                  () => {
                    Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED", ())
                    Promise.resolve(false)
                  },
                )
              } else {
                let (_, userMessage) = ProjectUtils.classifySaveError(msg)
                let _ = ProjectUtils.updateSaveContext(
                  ~journalId,
                  ~state,
                  ~stage="failed",
                  ~filename,
                  ~error=msg,
                )
                ProjectUtils.notifySaveFailure(~message=userMessage, ~details=msg)
                opId->Option.forEach(id => OperationLifecycle.fail(id, msg))
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
          let _ = ProjectUtils.updateSaveContext(
            ~journalId,
            ~state,
            ~stage="cancelled",
            ~filename,
            ~error=msg,
          )
          opId->Option.forEach(id => OperationLifecycle.cancel(id))
          OperationJournal.updateStatus(journalId, Cancelled)->Promise.then(
            () => {
              Logger.info(~module_="ProjectManager", ~message="SAVE_CANCELLED_PICKER", ())
              Promise.resolve(false)
            },
          )
        } else {
          let (_, userMessage) = ProjectUtils.classifySaveError(msg)
          let _ = ProjectUtils.updateSaveContext(
            ~journalId,
            ~state,
            ~stage="failed",
            ~filename,
            ~error=msg,
          )
          ProjectUtils.notifySaveFailure(~message=userMessage, ~details=msg)
          opId->Option.forEach(id => OperationLifecycle.fail(id, msg))
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
