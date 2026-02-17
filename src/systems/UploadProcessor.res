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
): Promise.t<UploadTypes.processResult> => {
  let updateProgress = (pct, msg, isProc, phase) => {
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

  updateProgress(0.0, "Checking backend...", true, "Health Check")

  OperationJournal.startOperation(
    ~operation="UploadImages",
    ~context=UploadProcessorLogic.castToJson({"fileCount": Belt.Array.length(files)}),
    ~retryable=true,
  )->Promise.then(journalId => {
    if !NetworkStatus.isOnline() {
      updateProgress(100.0, "Error: No Internet Connection", false, "Error")
      UploadProcessorLogic.Utils.notify(
        "You appear to be offline. Please check your internet connection and try again.",
        "warning",
      )
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
          OperationJournal.failOperation(journalId, "Backend Offline")->Promise.then(
            () => Promise.resolve(emptyResult),
          )
        } else {
          let startTime = Date.now()
          if Belt.Array.length(files) == 0 {
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
                  OperationJournal.completeOperation(journalId)->Promise.then(
                    () => Promise.resolve(result),
                  )
                },
              )
              ->Promise.catch(
                err => {
                  let (msg, _) = Logger.getErrorDetails(err)
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
