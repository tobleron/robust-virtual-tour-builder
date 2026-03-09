// @efficiency-role: service-orchestrator

type etaState = {
  teaserStartedAtMs: float,
  lastEtaToastAtMs: ref<float>,
  lastPctSample: ref<float>,
  lastSampleAtMs: ref<float>,
  emaProgressPerSecond: ref<float>,
  knownTotalFrames: ref<int>,
  lastRenderedFrameSample: ref<int>,
  lastFrameSampleAtMs: ref<float>,
  emaSecondsPerFrame: ref<float>,
  frameSampleCount: ref<int>,
  stableEtaSeconds: ref<float>,
  etaReady: ref<bool>,
}

let handleProgress = (
  ~teaserEtaToastId: string,
  ~phaseName: string,
  ~msg: string,
  ~pct: float,
  ~parsed: TeaserLogicHelpers.teaserProgressMetrics,
  ~etaState: etaState,
) => {
  if pct > 0.0 && pct < 100.0 {
    let now = Date.now()

    switch (parsed.renderedFrame, parsed.totalFrames) {
    | (Some(done), Some(total)) =>
      etaState.knownTotalFrames := total
      if done > etaState.lastRenderedFrameSample.contents {
        let deltaFrames = done - etaState.lastRenderedFrameSample.contents
        let deltaSeconds = (now -. etaState.lastFrameSampleAtMs.contents) /. 1000.0
        if deltaFrames > 0 && deltaSeconds > 0.2 {
          let instSecondsPerFrame = deltaSeconds /. Belt.Int.toFloat(deltaFrames)
          if etaState.emaSecondsPerFrame.contents <= 0.0 {
            etaState.emaSecondsPerFrame := instSecondsPerFrame
          } else {
            etaState.emaSecondsPerFrame :=
              0.74 *. etaState.emaSecondsPerFrame.contents +. 0.26 *. instSecondsPerFrame
          }
          etaState.frameSampleCount := etaState.frameSampleCount.contents + 1
        }
        etaState.lastRenderedFrameSample := done
        etaState.lastFrameSampleAtMs := now
      }
    | _ => ()
    }

    let deltaPct = pct -. etaState.lastPctSample.contents
    let deltaSec = (now -. etaState.lastSampleAtMs.contents) /. 1000.0
    if deltaPct > 0.0 && deltaSec > 0.3 {
      let instRate = deltaPct /. deltaSec
      if etaState.emaProgressPerSecond.contents <= 0.0 {
        etaState.emaProgressPerSecond := instRate
      } else {
        etaState.emaProgressPerSecond :=
          0.8 *. etaState.emaProgressPerSecond.contents +. 0.2 *. instRate
      }
      etaState.lastPctSample := pct
      etaState.lastSampleAtMs := now
    }

    let elapsedSec = (now -. etaState.teaserStartedAtMs) /. 1000.0
    if (
      !etaState.etaReady.contents &&
      elapsedSec >= 8.0 &&
      (etaState.frameSampleCount.contents >= 3 ||
        (pct >= 15.0 && etaState.emaProgressPerSecond.contents > 0.0))
    ) {
      etaState.etaReady := true
    }

    let shouldUpdateToast = now -. etaState.lastEtaToastAtMs.contents >= 1200.0
    if shouldUpdateToast {
      let remainingFrames = if etaState.knownTotalFrames.contents > etaState.lastRenderedFrameSample.contents {
        etaState.knownTotalFrames.contents - etaState.lastRenderedFrameSample.contents
      } else {
        0
      }
      let etaByFrameRate = if etaState.emaSecondsPerFrame.contents > 0.0 && remainingFrames > 0 {
        Some(etaState.emaSecondsPerFrame.contents *. Belt.Int.toFloat(remainingFrames))
      } else {
        None
      }
      let etaByProgressSlope = if etaState.emaProgressPerSecond.contents > 0.0 {
        Some((100.0 -. pct) /. etaState.emaProgressPerSecond.contents)
      } else {
        None
      }
      let etaByGlobalAverage = if pct >= 1.0 {
        Some(elapsedSec /. pct *. (100.0 -. pct))
      } else {
        None
      }

      let etaFromRenderer = parsed.etaSecondsFromMessage->Option.map(Belt.Int.toFloat)
      let blendedEta =
        EtaSupport.combineEtaCandidates(~a=etaByFrameRate, ~b=etaByProgressSlope, ~c=etaByGlobalAverage, ~d=?etaFromRenderer)
        ->Option.map(raw =>
          if phaseName == "Encoding WebM" { raw *. 1.06 } else { raw }
        )

      let etaSeconds = switch blendedEta {
      | Some(candidate) if etaState.etaReady.contents =>
        let smoothed = if etaState.stableEtaSeconds.contents <= 0.0 {
          candidate
        } else {
          let raw = 0.78 *. etaState.stableEtaSeconds.contents +. 0.22 *. candidate
          let maxRise = etaState.stableEtaSeconds.contents +. 20.0
          let maxDrop = etaState.stableEtaSeconds.contents -. 12.0
          EtaSupport.clampFloat(~value=raw, ~minValue=Math.max(1.0, maxDrop), ~maxValue=maxRise)
        }
        etaState.stableEtaSeconds := smoothed
        Belt.Float.toInt(smoothed)
      | _ => 0
      }

      etaState.lastEtaToastAtMs := now
      if etaState.etaReady.contents {
        EtaSupport.updateEtaToast(
          ~id=teaserEtaToastId,
          ~contextOperation="eta_teaser",
          ~prefix="Generating teaser",
          ~etaSeconds,
          ~details=Some(phaseName ++ " • " ++ msg),
          ~createdAt=now,
          (),
        )
      } else {
        EtaSupport.dispatchCalculatingEtaToast(
          ~id=teaserEtaToastId,
          ~contextOperation="eta_teaser",
          ~prefix="Generating teaser",
          ~details=Some(phaseName ++ " • " ++ msg),
          ~createdAt=now,
          (),
        )
      }
    }
  }
}

let handleFailure = (
  ~teaserEtaToastId: string,
  ~dispatch: Actions.action => unit,
  ~opId: string,
  ~signal,
  exn,
) => {
  EtaSupport.dismissEtaToast(teaserEtaToastId)
  dispatch(Actions.SetIsTeasing(false))
  ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
  TeaserRecorder.Recorder.stopRecording()

  let (msg, _) = Logger.getErrorDetails(exn)
  if String.includes(msg, "AbortError") || TeaserLogicHelpers.signalIsAborted(signal) {
    if OperationLifecycle.isActive(opId) {
      OperationLifecycle.cancel(opId)
    }
    NotificationManager.dispatch({
      id: "",
      importance: Info,
      context: Operation("teaser"),
      message: "Teaser generation cancelled",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Info),
      dismissible: true,
      createdAt: Date.now(),
    })
  } else {
    Logger.error(
      ~module_="TeaserLogic",
      ~message="TEASER_FAILED",
      ~data=Some(Logger.castToJson({"error": msg})),
      (),
    )
    if OperationLifecycle.isActive(opId) {
      OperationLifecycle.fail(opId, "Teaser generation failed: " ++ msg)
    }
  }
}
