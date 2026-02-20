/* src/systems/UploadProcessor.res */
// @efficiency-role: orchestrator

open UploadTypes

// No direct Actions dependency if using Logic module?
// Actually Logic handles EventBus dispatching.
// We just need the orchestrator code.

let processUploads = (
  files: array<UploadTypes.file>,
  progressCallback: option<(float, string, bool, string) => unit>,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~opId: option<OperationLifecycle.operationId>=?,
): Promise.t<UploadTypes.processResult> => {
  // Start OperationLifecycle
  let opId = switch opId {
  | Some(id) => id
  | None =>
    OperationLifecycle.start(
      ~type_=Upload,
      ~scope=Ambient,
      ~phase="Initializing",
      ~meta=UploadProcessorLogic.castToJson({
        "fileCount": Belt.Array.length(files),
        "totalSizeBytes": files->Belt.Array.reduce(0.0, (acc, f) =>
          acc +. BrowserBindings.File.size(f)
        ),
      }),
      (),
    )
  }

  let updateProgress = (pct, msg, isProc, phase) => {
    OperationLifecycle.progress(opId, pct, ~message=msg, ~phase=phase, ())
    switch progressCallback {
    | Some(cb) => cb(pct, msg, isProc, phase)
    | None => ()
    }
  }

  let emptyResult = (
    {
      qualityResults: [],
      duration: "0.0",
      report: {success: [], skipped: []},
    }: UploadTypes.processResult
  )

  updateProgress(0.0, "Connecting to server...", true, "Health Check")

  OperationJournal.startOperation(
    ~operation="UploadImages",
    ~context=UploadProcessorLogic.castToJson({
      "fileCount": Belt.Array.length(files),
      "fileNames": files
      ->Belt.Array.map(f => BrowserBindings.File.name(f))
      ->Belt.Array.slice(~offset=0, ~len=20),
      "totalSizeBytes": files->Belt.Array.reduce(0.0, (acc, f) =>
        acc +. BrowserBindings.File.size(f)
      ),
    }),
    ~retryable=true,
  )->Promise.then(journalId => {
    if !NetworkStatus.isOnline() {
      updateProgress(100.0, "Error: No Internet Connection", false, "Error")
      UploadProcessorLogic.Utils.notify(
        "You appear to be offline. Please check your internet connection and try again.",
        "warning",
      )
      OperationLifecycle.fail(opId, "Browser Offline")
      OperationJournal.failOperation(journalId, "Browser Offline")->Promise.then(() =>
        Promise.resolve(emptyResult)
      )
    } else {
      Resizer.checkBackendHealth()->Promise.then(isUp => {
        if !isUp {
          updateProgress(100.0, "Error: Backend Offline", false, "Error")
          UploadProcessorLogic.Utils.notify(
            "Backend Server Not Connected! Port 8080 is not running.",
            "error",
          )
          OperationLifecycle.fail(opId, "Backend Offline")
          OperationJournal.failOperation(journalId, "Backend Offline")->Promise.then(
            () => Promise.resolve(emptyResult),
          )
        } else {
          let startTime = Date.now()
          if Belt.Array.length(files) == 0 {
            OperationLifecycle.complete(opId, ~result="No files", ())
            OperationJournal.completeOperation(journalId)->Promise.then(
              () => Promise.resolve(emptyResult),
            )
          } else {
            let validFiles = ImageValidator.validateFiles(
              files,
              msg => UploadProcessorLogic.Utils.notify(msg, "warning"),
            )
            if Belt.Array.length(validFiles) == 0 {
              UploadProcessorLogic.Utils.notify("No valid image files selected!", "error")
              OperationLifecycle.complete(opId, ~result="No valid files", ())
              OperationJournal.completeOperation(journalId)->Promise.then(
                () => Promise.resolve(emptyResult),
              )
            } else {
              UploadProcessorLogic.handleFingerprinting(
                validFiles,
                startTime,
                updateProgress,
                journalId,
                ~getState,
                ~dispatch,
              )
              ->Promise.then(
                result => {
                  OperationLifecycle.complete(opId, ~result="Success", ())
                  OperationJournal.completeOperation(journalId)->Promise.then(
                    () => Promise.resolve(result),
                  )
                },
              )
              ->Promise.catch(
                err => {
                  let (msg, _) = Logger.getErrorDetails(err)
                  OperationLifecycle.fail(opId, msg)
                  OperationJournal.failOperation(journalId, msg)->Promise.then(
                    () => Promise.reject(err),
                  )
                },
              )
            }
          }
        }
      })
    }
  })
}
