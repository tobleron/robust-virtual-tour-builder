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

  Resizer.checkBackendHealth()->Promise.then(isUp => {
    if !isUp {
      updateProgress(100.0, "Error: Backend Offline", false, "Error")
      UploadProcessorLogic.Utils.notify(
        "Backend Server Not Connected! Port 8080 is not running.",
        "error",
      )
      Promise.resolve(emptyResult)
    } else {
      let startTime = Date.now()
      if Belt.Array.length(files) == 0 {
        Promise.resolve(emptyResult)
      } else {
        let validFiles = ImageValidator.validateFiles(files, msg =>
          UploadProcessorLogic.Utils.notify(msg, "warning")
        )
        if Belt.Array.length(validFiles) == 0 {
          UploadProcessorLogic.Utils.notify("No valid image files selected!", "error")
          Promise.resolve(emptyResult)
        } else {
          UploadProcessorLogic.handleFingerprinting(validFiles, startTime, updateProgress)
        }
      }
    }
  })
}
