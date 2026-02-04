/* src/systems/UploadProcessor.res */
// @efficiency-role: orchestrator

open UploadTypes

// No direct Actions dependency if using Logic module?
// Actually Logic handles EventBus dispatching.
// We just need the orchestrator code.

let processUploads = (
  files: array<UploadTypes.file>,
  progressCallback: option<(float, string, bool, string) => unit>,
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

  let journalId = OperationJournal.startOperation(
    ~operation="UploadImages",
    ~context=UploadProcessorLogic.castToJson({"fileCount": Belt.Array.length(files)}),
    ~retryable=true,
  )

  Resizer.checkBackendHealth()->Promise.then(isUp => {
    if !isUp {
      updateProgress(100.0, "Error: Backend Offline", false, "Error")
      UploadProcessorLogic.Utils.notify(
        "Backend Server Not Connected! Port 8080 is not running.",
        "error",
      )
      OperationJournal.failOperation(journalId, "Backend Offline")
      Promise.resolve(emptyResult)
    } else {
      let startTime = Date.now()
      if Belt.Array.length(files) == 0 {
        OperationJournal.completeOperation(journalId)
        Promise.resolve(emptyResult)
      } else {
        let validFiles = ImageValidator.validateFiles(files, msg =>
          UploadProcessorLogic.Utils.notify(msg, "warning")
        )
        if Belt.Array.length(validFiles) == 0 {
          UploadProcessorLogic.Utils.notify("No valid image files selected!", "error")
          OperationJournal.completeOperation(journalId)
          Promise.resolve(emptyResult)
        } else {
          UploadProcessorLogic.handleFingerprinting(
            validFiles,
            startTime,
            updateProgress,
            journalId,
          )
          ->Promise.then(result => {
            OperationJournal.completeOperation(journalId)
            Promise.resolve(result)
          })
          ->Promise.catch(err => {
            let (msg, _) = Logger.getErrorDetails(err)
            OperationJournal.failOperation(journalId, msg)
            Promise.reject(err)
          })
        }
      }
    }
  })
}
