open SidebarBase
open ReBindings

type etaRuntimeMetrics = SidebarUploadMetrics.etaRuntimeMetrics

type exportRuntimeMetrics = SidebarUploadMetrics.exportRuntimeMetrics

let parseProcessingMetrics = (msg: string): option<etaRuntimeMetrics> =>
  SidebarUploadMetrics.parseProcessingMetrics(msg)

let parseExportMetrics = (msg: string): exportRuntimeMetrics =>
  SidebarUploadMetrics.parseExportMetrics(msg)

let performUpload = async (
  ~progressToastId,
  files,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let fileArray = JsHelpers.from(files)
  let tracker = SidebarUploadEta.makeTracker(
    ~progressToastId,
    ~initialItems=Belt.Array.length(fileArray),
  )
  let wasCancelled = ref(false)
  let cancelToastSent = ref(false)

  let cleanup = () => {
    SidebarUploadEta.cleanup(tracker)
  }

  try {
    SidebarUploadEta.startCountdown(tracker)
    EtaSupport.dispatchCalculatingEtaToast(
      ~id=progressToastId,
      ~contextOperation="eta_upload",
      ~prefix="Uploading",
      (),
    )
    let result: UploadTypes.processResult = await UploadProcessor.processUploads(
      fileArray,
      Some(
        (~eta as processorEta=?, pct, msg, isProc, phase) => {
          SidebarUploadEta.markCancelledIfNeeded(~tracker, ~phase, ~msg)
          wasCancelled := tracker.wasCancelled.contents

          let currentEta = SidebarUploadEta.currentEtaLabel(~tracker, ~processorEta, ~isProc, ~pct)

          updateProgress(~dispatch, ~eta=?currentEta, pct, msg, isProc, phase)
          if isProc && pct > 0.0 && pct < 100.0 {
            SidebarUploadEta.ingestProcessingSample(~tracker, ~pct, ~msg)
          }
        },
      ),
      ~getState,
      ~dispatch,
      ~onCancel=() => {
        wasCancelled := true
        cleanup()
        updateProgress(~dispatch, 0.0, "Cancelled", false, "Cancelled")
        if !cancelToastSent.contents {
          cancelToastSent := true
          NotificationManager.dispatch({
            id: "",
            importance: Info,
            context: Operation("sidebar_upload"),
            message: "Upload cancelled",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Info),
            dismissible: true,
            createdAt: Date.now(),
          })
        }
      },
    )

    cleanup()

    if !wasCancelled.contents {
      let qualityResults = result.qualityResults
      let report = result.report
      let successfulCount = Belt.Array.length(report.success)
      let hasAnySuccess = successfulCount > 0

      if hasAnySuccess {
        dispatch(DispatchAppFsmEvent(UploadComplete(report, qualityResults)))
        let processedCount = successfulCount + Belt.Array.length(report.skipped)
        if processedCount > 1 {
          UploadReport.show(report, qualityResults, ~getState, ~dispatch)
        } else {
          let state = getState()
          if (
            state.activeIndex == -1 &&
              Array.length(SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)) > 0
          ) {
            dispatch(Actions.SetActiveScene(0, 0.0, 0.0, None))
          }
        }
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("sidebar_upload"),
          message: "Upload Complete",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
      } else {
        dispatch(
          Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Upload failed: no files processed")),
        )
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_upload"),
          message: "Upload failed: no files processed",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 100.0, "Upload failed", false, "Error")
      }
    }
    Promise.resolve(Ok(result))
  } catch {
  | JsExn(obj) => {
      cleanup()
      let msg = switch JsExn.message(obj) {
      | Some(m) => m
      | None => "Unknown error"
      }
      if msg == "CANCELLED" || wasCancelled.contents {
        updateProgress(~dispatch, 0.0, "Cancelled", false, "Cancelled")
        if !cancelToastSent.contents {
          cancelToastSent := true
          NotificationManager.dispatch({
            id: "",
            importance: Info,
            context: Operation("sidebar_upload"),
            message: "Upload cancelled",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Info),
            dismissible: true,
            createdAt: Date.now(),
          })
        }
      } else {
        dispatch(Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Upload Failed: " ++ msg)))
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_upload"),
          message: NotificationTypes.truncateForToast("Upload failed: " ++ msg),
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
      }
      Promise.resolve(Error(msg))
    }
  | _ => {
      cleanup()
      dispatch(Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Unknown Upload Error")))
      Promise.resolve(Error("Unknown error"))
    }
  }
}
