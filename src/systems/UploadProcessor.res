/* src/systems/UploadProcessor.res */
// @efficiency-role: orchestrator

open UploadTypes

// No direct Actions dependency if using Logic module?
// Actually Logic handles EventBus dispatching.
// We just need the orchestrator code.

let processUploads = (
  files: array<UploadTypes.file>,
  progressCallback: option<(~eta: string=?, float, string, bool, string) => unit>,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~opId: option<OperationLifecycle.operationId>=?,
  ~onCancel: option<unit => unit>=?,
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

  let cancelled = ref(false)
  let journalIdRef: ref<option<string>> = ref(None)

  OperationLifecycle.registerCancel(opId, () => {
    if !cancelled.contents {
      cancelled := true
      onCancel->Option.forEach(cb => cb())
      switch journalIdRef.contents {
      | Some(journalId) =>
        let _ = OperationJournal.removeOperation(journalId)
      | None => ()
      }
      Logger.info(
        ~module_="UploadProcessor",
        ~message="UPLOAD_CANCELLED_BY_USER",
        ~data=Some({"opId": opId}),
        (),
      )
    }
  })

  let updateProgress = (~eta as _eta=?, pct, msg, isProc, phase) => {
    if !cancelled.contents {
      OperationLifecycle.progress(opId, pct, ~message=msg, ~phase, ())
      switch progressCallback {
      | Some(cb) => cb(~eta=?_eta, pct, msg, isProc, phase)
      | None => ()
      }
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
    journalIdRef := Some(journalId)

    if cancelled.contents {
      OperationJournal.removeOperation(journalId)->Promise.then(() => Promise.resolve(emptyResult))
    } else if !NetworkStatus.isOnline() {
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
            ImageValidator.validateFilesAsync(
              files,
              msg => UploadProcessorLogic.Utils.notify(msg, "warning"),
              ~signal?,
            )->Promise.then(
              validFiles => {
                if Belt.Array.length(validFiles) == 0 {
                  UploadProcessorLogic.Utils.notify("No valid image files selected!", "error")
                  OperationLifecycle.complete(opId, ~result="No valid files", ())
                  OperationJournal.removeOperation(journalId)->Promise.then(
                    () => Promise.resolve(emptyResult),
                  )
                } else {
                  UploadProcessorLogic.handleFingerprinting(
                    validFiles,
                    startTime,
                    updateProgress,
                    journalId,
                    ~signal?,
                    ~getState,
                    ~dispatch,
                  )
                  ->Promise.then(
                    result => {
                      OperationLifecycle.complete(opId, ~result="Success", ())
                      OperationJournal.removeOperation(journalId)->Promise.then(
                        () => Promise.resolve(result),
                      )
                    },
                  )
                  ->Promise.catch(
                    err => {
                      let (msg, _) = Logger.getErrorDetails(err)
                      if cancelled.contents || msg == "CANCELLED" {
                        OperationJournal.removeOperation(journalId)->Promise.then(
                          () => Promise.resolve(emptyResult),
                        )
                      } else {
                        OperationLifecycle.fail(opId, msg)
                        OperationJournal.failOperation(journalId, msg)->Promise.then(
                          () => Promise.reject(err),
                        )
                      }
                    },
                  )
                }
              },
            )
          }
        }
      })
    }
  })
}
