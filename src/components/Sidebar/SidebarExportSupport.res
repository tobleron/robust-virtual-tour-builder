type tracker = {
  progressToastId: string,
  startedAtMs: float,
  knownTotalScenes: ref<int>,
  knownTotalUploadMb: ref<float>,
  lastEtaToastAtMs: ref<float>,
  lastPctSample: ref<float>,
  lastSampleAtMs: ref<float>,
  emaProgressPerSecond: ref<float>,
  lastPackagedSceneSample: ref<int>,
  lastPackagedSceneAtMs: ref<float>,
  emaSecondsPerScene: ref<float>,
  packagingSampleCount: ref<int>,
  lastUploadedMbSample: ref<float>,
  lastUploadedMbAtMs: ref<float>,
  emaSecondsPerMb: ref<float>,
  uploadSampleCount: ref<int>,
  stableEtaSeconds: ref<float>,
  etaReady: ref<bool>,
}

let makeTracker = (~progressToastId, ~exportSceneCount: int): tracker => {
  let startedAtMs = Date.now()
  {
    progressToastId,
    startedAtMs,
    knownTotalScenes: ref(exportSceneCount),
    knownTotalUploadMb: ref(0.0),
    lastEtaToastAtMs: ref(0.0),
    lastPctSample: ref(0.0),
    lastSampleAtMs: ref(startedAtMs),
    emaProgressPerSecond: ref(0.0),
    lastPackagedSceneSample: ref(0),
    lastPackagedSceneAtMs: ref(startedAtMs),
    emaSecondsPerScene: ref(0.0),
    packagingSampleCount: ref(0),
    lastUploadedMbSample: ref(0.0),
    lastUploadedMbAtMs: ref(startedAtMs),
    emaSecondsPerMb: ref(0.0),
    uploadSampleCount: ref(0),
    stableEtaSeconds: ref(0.0),
    etaReady: ref(false),
  }
}

let updateProgressEta = (~tracker, ~pct: float, ~msg: string) => {
  if !(pct > 0.0 && pct < 100.0) {
    ()
  } else {
    let now = Date.now()
    let metrics = SidebarUploadLogic.parseExportMetrics(msg)

    metrics.packagedScene->Option.forEach(((completed, total)) => {
      tracker.knownTotalScenes := total
      if completed > tracker.lastPackagedSceneSample.contents {
        let deltaScenes = completed - tracker.lastPackagedSceneSample.contents
        let deltaSeconds = (now -. tracker.lastPackagedSceneAtMs.contents) /. 1000.0
        if deltaScenes > 0 && deltaSeconds > 0.4 {
          let instSecondsPerScene = deltaSeconds /. Belt.Int.toFloat(deltaScenes)
          if tracker.emaSecondsPerScene.contents <= 0.0 {
            tracker.emaSecondsPerScene := instSecondsPerScene
          } else {
            tracker.emaSecondsPerScene :=
              0.72 *. tracker.emaSecondsPerScene.contents +. 0.28 *. instSecondsPerScene
          }
          tracker.packagingSampleCount := tracker.packagingSampleCount.contents + 1
        }
        tracker.lastPackagedSceneSample := completed
        tracker.lastPackagedSceneAtMs := now
      }
    })

    metrics.uploadedMb->Option.forEach(((uploadedMb, totalMb)) => {
      tracker.knownTotalUploadMb := totalMb
      if uploadedMb > tracker.lastUploadedMbSample.contents {
        let deltaMb = uploadedMb -. tracker.lastUploadedMbSample.contents
        let deltaSeconds = (now -. tracker.lastUploadedMbAtMs.contents) /. 1000.0
        if deltaMb > 0.1 && deltaSeconds > 0.4 {
          let instSecondsPerMb = deltaSeconds /. deltaMb
          if tracker.emaSecondsPerMb.contents <= 0.0 {
            tracker.emaSecondsPerMb := instSecondsPerMb
          } else {
            tracker.emaSecondsPerMb :=
              0.7 *. tracker.emaSecondsPerMb.contents +. 0.3 *. instSecondsPerMb
          }
          tracker.uploadSampleCount := tracker.uploadSampleCount.contents + 1
        }
        tracker.lastUploadedMbSample := uploadedMb
        tracker.lastUploadedMbAtMs := now
      }
    })

    let deltaPct = pct -. tracker.lastPctSample.contents
    let deltaSec = (now -. tracker.lastSampleAtMs.contents) /. 1000.0
    if deltaPct > 0.0 && deltaSec > 0.4 {
      let instRate = deltaPct /. deltaSec
      if tracker.emaProgressPerSecond.contents <= 0.0 {
        tracker.emaProgressPerSecond := instRate
      } else {
        tracker.emaProgressPerSecond :=
          0.82 *. tracker.emaProgressPerSecond.contents +. 0.18 *. instRate
      }
      tracker.lastPctSample := pct
      tracker.lastSampleAtMs := now
    }

    let elapsedSec = (now -. tracker.startedAtMs) /. 1000.0
    if (
      !tracker.etaReady.contents &&
      elapsedSec >= 10.0 &&
      (tracker.packagingSampleCount.contents >= 2 ||
      tracker.uploadSampleCount.contents >= 2 ||
      (pct >= 20.0 && tracker.emaProgressPerSecond.contents > 0.0))
    ) {
      tracker.etaReady := true
    }

    if now -. tracker.lastEtaToastAtMs.contents >= 1500.0 {
      let remainingScenes = if (
        tracker.knownTotalScenes.contents > tracker.lastPackagedSceneSample.contents
      ) {
        tracker.knownTotalScenes.contents - tracker.lastPackagedSceneSample.contents
      } else {
        0
      }
      let remainingMb = if (
        tracker.knownTotalUploadMb.contents > tracker.lastUploadedMbSample.contents
      ) {
        tracker.knownTotalUploadMb.contents -. tracker.lastUploadedMbSample.contents
      } else {
        0.0
      }
      let etaBySceneRate = if tracker.emaSecondsPerScene.contents > 0.0 && remainingScenes > 0 {
        Some(tracker.emaSecondsPerScene.contents *. Belt.Int.toFloat(remainingScenes))
      } else {
        None
      }
      let etaByUploadRate = if tracker.emaSecondsPerMb.contents > 0.0 && remainingMb > 0.1 {
        Some(tracker.emaSecondsPerMb.contents *. remainingMb)
      } else {
        None
      }
      let etaByProgressSlope = if tracker.emaProgressPerSecond.contents > 0.0 {
        Some((100.0 -. pct) /. tracker.emaProgressPerSecond.contents)
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
      | Some(candidate) if tracker.etaReady.contents =>
        let smoothed = if tracker.stableEtaSeconds.contents <= 0.0 {
          candidate
        } else {
          let raw = 0.8 *. tracker.stableEtaSeconds.contents +. 0.2 *. candidate
          let maxRise = tracker.stableEtaSeconds.contents +. 25.0
          let maxDrop = tracker.stableEtaSeconds.contents -. 16.0
          EtaSupport.clampFloat(~value=raw, ~minValue=Math.max(1.0, maxDrop), ~maxValue=maxRise)
        }
        tracker.stableEtaSeconds := smoothed
        Belt.Float.toInt(smoothed)
      | _ => 0
      }

      tracker.lastEtaToastAtMs := now
      if tracker.etaReady.contents {
        EtaSupport.updateEtaToast(
          ~id=tracker.progressToastId,
          ~contextOperation="eta_export",
          ~prefix="Exporting",
          ~etaSeconds,
          ~details=Some("Export • " ++ msg),
          ~createdAt=now,
          (),
        )
      } else {
        EtaSupport.dispatchCalculatingEtaToast(
          ~id=tracker.progressToastId,
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

let sanitizePublishProjectData = (~projectData: option<JSON.t>, ~includeMarketing: bool) =>
  switch projectData {
  | Some(projectJson) if !includeMarketing =>
    switch JsonCombinators.Json.decode(projectJson, JsonParsers.Domain.project) {
    | Ok(project) =>
      Some(
        JsonParsers.Encoders.project({
          ...project,
          marketingComment: "",
          marketingPhone1: "",
          marketingPhone2: "",
          marketingForRent: false,
          marketingForSale: false,
        }),
      )
    | Error(_) => projectData
    }
  | _ => projectData
  }
