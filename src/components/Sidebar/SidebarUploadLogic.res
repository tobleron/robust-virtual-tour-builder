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
  let startedAtMs = Date.now()
  let knownTotalItems = ref(Belt.Array.length(fileArray))
  let lastPctSample = ref(0.0)
  let lastSampleAtMs = ref(startedAtMs)
  let emaProgressPerSecond = ref(0.0)
  let lastCompletedSample = ref(0)
  let lastCompletedAtMs = ref(startedAtMs)
  let emaSecondsPerItem = ref(0.0)
  let completionSampleCount = ref(0)
  let stableEtaSeconds = ref(0.0)
  let etaReady = ref(false)
  let wasCancelled = ref(false)
  let cancelToastSent = ref(false)
  let lastEtaToastAtMs = ref(0.0)
  let lastEtaToastValue = ref(0)
  let countdownTimerId = ref(None)

  let stopCountdown = () => {
    countdownTimerId.contents->Option.forEach(id => ReBindings.Window.clearInterval(id))
    countdownTimerId := None
  }

  let startCountdown = () => {
    stopCountdown()
    countdownTimerId := Some(ReBindings.Window.setInterval(() => {
          if stableEtaSeconds.contents > 1.0 && etaReady.contents && !wasCancelled.contents {
            stableEtaSeconds := stableEtaSeconds.contents -. 1.0
            let seconds = Belt.Float.toInt(stableEtaSeconds.contents)

            let now = Date.now()

            // Throttle toast updates to avoid rapid flickering, but ensure it counts down.
            if now -. lastEtaToastAtMs.contents >= 900.0 && seconds != lastEtaToastValue.contents {
              lastEtaToastAtMs := now
              lastEtaToastValue := seconds
              EtaSupport.updateEtaToast(
                ~id=progressToastId,
                ~contextOperation="eta_upload",
                ~prefix="Uploading",
                ~etaSeconds=seconds,
                (),
              )
            }
          }
        }, 1000))
  }

  let cleanup = () => {
    stopCountdown()
    EtaSupport.dismissEtaToast(progressToastId)
  }

  try {
    startCountdown()
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
          if phase == "Cancelled" || String.startsWith(msg, "Cancelled") {
            wasCancelled := true
            cleanup()
          }

          let currentEta = if etaReady.contents {
            Some("ETA " ++ EtaSupport.formatEta(Belt.Float.toInt(stableEtaSeconds.contents)))
          } else if isProc && pct > 0.0 && pct < 100.0 {
            Some("Calculating...")
          } else {
            processorEta
          }

          updateProgress(~dispatch, ~eta=?currentEta, pct, msg, isProc, phase)
          if isProc && pct > 0.0 && pct < 100.0 {
            let now = Date.now()
            let parsedMetrics = parseProcessingMetrics(msg)

            parsedMetrics->Option.forEach(m => {
              knownTotalItems := m.total
              if m.completed > lastCompletedSample.contents {
                let deltaItems = m.completed - lastCompletedSample.contents
                let deltaSeconds = (now -. lastCompletedAtMs.contents) /. 1000.0
                if deltaItems > 0 && deltaSeconds > 0.4 {
                  let instSecondsPerItem = deltaSeconds /. Belt.Int.toFloat(deltaItems)
                  if emaSecondsPerItem.contents <= 0.0 {
                    emaSecondsPerItem := instSecondsPerItem
                  } else {
                    emaSecondsPerItem :=
                      0.60 *. emaSecondsPerItem.contents +. 0.40 *. instSecondsPerItem
                  }
                  completionSampleCount := completionSampleCount.contents + 1
                }
                lastCompletedSample := m.completed
                lastCompletedAtMs := now
              }
            })

            let deltaPct = pct -. lastPctSample.contents
            let deltaSec = (now -. lastSampleAtMs.contents) /. 1000.0
            if deltaPct > 0.0 && deltaSec > 0.4 {
              let instRate = deltaPct /. deltaSec
              if emaProgressPerSecond.contents <= 0.0 {
                emaProgressPerSecond := instRate
              } else {
                emaProgressPerSecond := 0.7 *. emaProgressPerSecond.contents +. 0.3 *. instRate
              }
              lastPctSample := pct
              lastSampleAtMs := now
            }

            let elapsedSec = (now -. startedAtMs) /. 1000.0
            if (
              !etaReady.contents &&
              completionSampleCount.contents >= 2 &&
              elapsedSec >= 15.0 &&
              pct >= 10.0 &&
              emaProgressPerSecond.contents > 0.0
            ) {
              etaReady := true
              // Initial dispatch once ready
              let seconds = Belt.Float.toInt(stableEtaSeconds.contents)
              if seconds > 0 {
                EtaSupport.updateEtaToast(
                  ~id=progressToastId,
                  ~contextOperation="eta_upload",
                  ~prefix="Uploading",
                  ~etaSeconds=seconds,
                  (),
                )
              }
            }

            let processedItems = lastCompletedSample.contents
            let totalItems = knownTotalItems.contents
            let remainingItems = if totalItems > processedItems {
              totalItems - processedItems
            } else {
              0
            }

            let etaByRecentItemRate = if emaSecondsPerItem.contents > 0.0 && remainingItems > 0 {
              Some(emaSecondsPerItem.contents *. Belt.Int.toFloat(remainingItems))
            } else {
              None
            }
            let etaByGlobalItemAverage = if processedItems >= 1 && remainingItems > 0 {
              let avgSecPerItem = elapsedSec /. Belt.Int.toFloat(processedItems)
              Some(avgSecPerItem *. Belt.Int.toFloat(remainingItems))
            } else {
              None
            }

            let etaByProgressSlope = if emaProgressPerSecond.contents > 0.0 {
              Some((100.0 -. pct) /. emaProgressPerSecond.contents)
            } else {
              None
            }

            let blendedEta = switch (etaByProgressSlope, etaByRecentItemRate) {
            | (Some(slope), Some(rate)) => Some(0.7 *. slope +. 0.3 *. rate)
            | (Some(slope), None) => Some(slope)
            | (None, Some(rate)) => Some(rate)
            | _ => etaByGlobalItemAverage
            }->Option.map(raw => {
              let utilizationFactor = switch parsedMetrics {
              | Some(m) =>
                m.inFlightUtilization
                ->Option.map(
                  u =>
                    0.92 +. 0.08 *. EtaSupport.clampFloat(~value=u, ~minValue=0.0, ~maxValue=1.0),
                )
                ->Option.getOr(1.0)
              | None => 1.0
              }
              raw *. utilizationFactor
            })

            switch blendedEta {
            | Some(candidate) if etaReady.contents =>
              let smoothed = if stableEtaSeconds.contents <= 0.0 {
                candidate
              } else {
                let raw = 0.65 *. stableEtaSeconds.contents +. 0.35 *. candidate
                let maxRise = stableEtaSeconds.contents +. 30.0
                let maxDrop = stableEtaSeconds.contents -. 40.0
                EtaSupport.clampFloat(
                  ~value=raw,
                  ~minValue=Math.max(1.0, maxDrop),
                  ~maxValue=maxRise,
                )
              }
              stableEtaSeconds := smoothed
            | _ => ()
            }
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
