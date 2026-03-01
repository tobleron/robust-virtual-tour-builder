open SidebarBase

module UploadLogic = SidebarUploadLogic

let handleExport = async (
  ~progressToastId,
  scenes: array<Types.scene>,
  ~tourName: string,
  ~projectData: option<JSON.t>=?,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  dispatch(DispatchAppFsmEvent(StartExport))
  let startedAtMs = Date.now()
  let exportSceneCount = scenes->Belt.Array.keep(s => s.floor->String.trim != "")->Belt.Array.length
  let knownTotalScenes = ref(exportSceneCount)
  let knownTotalUploadMb = ref(0.0)
  let lastEtaToastAtMs = ref(0.0)
  let lastPctSample = ref(0.0)
  let lastSampleAtMs = ref(startedAtMs)
  let emaProgressPerSecond = ref(0.0)
  let lastPackagedSceneSample = ref(0)
  let lastPackagedSceneAtMs = ref(startedAtMs)
  let emaSecondsPerScene = ref(0.0)
  let packagingSampleCount = ref(0)
  let lastUploadedMbSample = ref(0.0)
  let lastUploadedMbAtMs = ref(startedAtMs)
  let emaSecondsPerMb = ref(0.0)
  let uploadSampleCount = ref(0)
  let stableEtaSeconds = ref(0.0)
  let etaReady = ref(false)

  let opId = OperationLifecycle.start(
    ~type_=Export,
    ~scope=Blocking,
    ~phase="Preparing",
    ~meta=Logger.castToJson({
      "tourName": tourName,
    }),
    (),
  )
  OperationLifecycle.registerCancel(opId, onCancel)

  updateProgress(~dispatch, ~onCancel, 0.0, "Starting export...", true, "Export")
  EtaSupport.dispatchCalculatingEtaToast(
    ~id=progressToastId,
    ~contextOperation="eta_export",
    ~prefix="Exporting",
    ~details=Some("Preparing export package"),
    (),
  )

  let handleExportProgress = (pct: float, _total: float, msg: string) => {
    updateProgress(~dispatch, ~onCancel, pct, msg, true, "Export")

    if pct > 0.0 && pct < 100.0 {
      let now = Date.now()
      let metrics = UploadLogic.parseExportMetrics(msg)

      metrics.packagedScene->Option.forEach(((completed, total)) => {
        knownTotalScenes := total
        if completed > lastPackagedSceneSample.contents {
          let deltaScenes = completed - lastPackagedSceneSample.contents
          let deltaSeconds = (now -. lastPackagedSceneAtMs.contents) /. 1000.0
          if deltaScenes > 0 && deltaSeconds > 0.4 {
            let instSecondsPerScene = deltaSeconds /. Belt.Int.toFloat(deltaScenes)
            if emaSecondsPerScene.contents <= 0.0 {
              emaSecondsPerScene := instSecondsPerScene
            } else {
              emaSecondsPerScene :=
                0.72 *. emaSecondsPerScene.contents +. 0.28 *. instSecondsPerScene
            }
            packagingSampleCount := packagingSampleCount.contents + 1
          }
          lastPackagedSceneSample := completed
          lastPackagedSceneAtMs := now
        }
      })

      metrics.uploadedMb->Option.forEach(((uploadedMb, totalMb)) => {
        knownTotalUploadMb := totalMb
        if uploadedMb > lastUploadedMbSample.contents {
          let deltaMb = uploadedMb -. lastUploadedMbSample.contents
          let deltaSeconds = (now -. lastUploadedMbAtMs.contents) /. 1000.0
          if deltaMb > 0.1 && deltaSeconds > 0.4 {
            let instSecondsPerMb = deltaSeconds /. deltaMb
            if emaSecondsPerMb.contents <= 0.0 {
              emaSecondsPerMb := instSecondsPerMb
            } else {
              emaSecondsPerMb := 0.7 *. emaSecondsPerMb.contents +. 0.3 *. instSecondsPerMb
            }
            uploadSampleCount := uploadSampleCount.contents + 1
          }
          lastUploadedMbSample := uploadedMb
          lastUploadedMbAtMs := now
        }
      })

      let deltaPct = pct -. lastPctSample.contents
      let deltaSec = (now -. lastSampleAtMs.contents) /. 1000.0
      if deltaPct > 0.0 && deltaSec > 0.4 {
        let instRate = deltaPct /. deltaSec
        if emaProgressPerSecond.contents <= 0.0 {
          emaProgressPerSecond := instRate
        } else {
          emaProgressPerSecond := 0.82 *. emaProgressPerSecond.contents +. 0.18 *. instRate
        }
        lastPctSample := pct
        lastSampleAtMs := now
      }

      let elapsedSec = (now -. startedAtMs) /. 1000.0
      if (
        !etaReady.contents &&
        elapsedSec >= 10.0 &&
        (packagingSampleCount.contents >= 2 ||
        uploadSampleCount.contents >= 2 ||
        (pct >= 20.0 && emaProgressPerSecond.contents > 0.0))
      ) {
        etaReady := true
      }

      let shouldUpdateToast = now -. lastEtaToastAtMs.contents >= 1500.0
      if shouldUpdateToast {
        let remainingScenes = if knownTotalScenes.contents > lastPackagedSceneSample.contents {
          knownTotalScenes.contents - lastPackagedSceneSample.contents
        } else {
          0
        }
        let remainingMb = if knownTotalUploadMb.contents > lastUploadedMbSample.contents {
          knownTotalUploadMb.contents -. lastUploadedMbSample.contents
        } else {
          0.0
        }

        let etaBySceneRate = if emaSecondsPerScene.contents > 0.0 && remainingScenes > 0 {
          Some(emaSecondsPerScene.contents *. Belt.Int.toFloat(remainingScenes))
        } else {
          None
        }
        let etaByUploadRate = if emaSecondsPerMb.contents > 0.0 && remainingMb > 0.1 {
          Some(emaSecondsPerMb.contents *. remainingMb)
        } else {
          None
        }
        let etaByProgressSlope = if emaProgressPerSecond.contents > 0.0 {
          Some((100.0 -. pct) /. emaProgressPerSecond.contents)
        } else {
          None
        }
        let etaByGlobalAverage = if pct >= 1.0 {
          Some(elapsedSec /. pct *. (100.0 -. pct))
        } else {
          None
        }

        let blendedEta = EtaSupport.combineEtaCandidates(
          ~a=etaBySceneRate,
          ~b=etaByUploadRate,
          ~c=etaByProgressSlope,
          ~d=?etaByGlobalAverage,
        )->Option.map(raw =>
          if String.startsWith(msg, "Building your tour") {
            raw *. 1.08
          } else {
            raw
          }
        )

        let etaSeconds = switch blendedEta {
        | Some(candidate) if etaReady.contents =>
          let smoothed = if stableEtaSeconds.contents <= 0.0 {
            candidate
          } else {
            let raw = 0.8 *. stableEtaSeconds.contents +. 0.2 *. candidate
            let maxRise = stableEtaSeconds.contents +. 25.0
            let maxDrop = stableEtaSeconds.contents -. 16.0
            EtaSupport.clampFloat(~value=raw, ~minValue=Math.max(1.0, maxDrop), ~maxValue=maxRise)
          }
          stableEtaSeconds := smoothed
          Belt.Float.toInt(smoothed)
        | _ => 0
        }

        lastEtaToastAtMs := now
        if etaReady.contents {
          EtaSupport.updateEtaToast(
            ~id=progressToastId,
            ~contextOperation="eta_export",
            ~prefix="Exporting",
            ~etaSeconds,
            ~details=Some("Export • " ++ msg),
            ~createdAt=now,
            (),
          )
        } else {
          EtaSupport.dispatchCalculatingEtaToast(
            ~id=progressToastId,
            ~contextOperation="eta_export",
            ~prefix="Exporting",
            ~details=Some("Export • " ++ msg),
            ~createdAt=now,
            (),
          )
        }
      }
    }
  }

  try {
    let exportResult = await FeatureLoaders.exportTourLazy(
      scenes,
      tourName,
      AppContext.getBridgeState().logo,
      projectData,
      signal,
      Some(handleExportProgress),
      opId,
    )
    switch exportResult {
    | Ok() => {
        EtaSupport.dismissEtaToast(progressToastId)
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("sidebar_export"),
          message: "Export complete",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 100.0, "Done", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error("CANCELLED") => {
        EtaSupport.dismissEtaToast(progressToastId)
        Logger.info(~module_="SidebarLogicHandler", ~message="EXPORT_CANCELLED_HANDLED", ())
        NotificationManager.dispatch({
          id: "",
          importance: Info,
          context: Operation("sidebar_export"),
          message: "Export cancelled",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Info),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 0.0, "Cancelled", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error(msg) => {
        EtaSupport.dismissEtaToast(progressToastId)
        Logger.error(
          ~module_="SidebarLogicHandler",
          ~message="EXPORT_FAILED",
          ~data=Some({"error": msg}),
          (),
        )
        dispatch(DispatchAppFsmEvent(ExportComplete))
        let finalMsg = if String.startsWith(msg, "Export blocked") {
          msg
        } else {
          "Export failed: " ++ msg
        }
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_export"),
          message: NotificationTypes.truncateForToast(finalMsg),
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
      }
    }
  } catch {
  | JsExn(exn) =>
    EtaSupport.dismissEtaToast(progressToastId)
    let msg = exn->JsExn.message->Option.getOr("Unexpected Error")
    Logger.error(
      ~module_="SidebarLogicHandler",
      ~message="EXPORT_FAILED_UNCAUGHT",
      ~data=Some({"error": msg}),
      (),
    )
    dispatch(DispatchAppFsmEvent(ExportComplete))
    let finalMsg = if String.startsWith(msg, "Export blocked") {
      msg
    } else {
      "Export failed: " ++ msg
    }
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("sidebar_export"),
      message: NotificationTypes.truncateForToast(finalMsg),
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
  | _ =>
    EtaSupport.dismissEtaToast(progressToastId)
    dispatch(DispatchAppFsmEvent(ExportComplete))
    updateProgress(~dispatch, 0.0, "Error: Unexpected Error", false, "")
  }
}
