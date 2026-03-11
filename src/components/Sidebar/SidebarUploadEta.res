type tracker = {
  progressToastId: string,
  startedAtMs: float,
  knownTotalItems: ref<int>,
  lastPctSample: ref<float>,
  lastSampleAtMs: ref<float>,
  emaProgressPerSecond: ref<float>,
  lastCompletedSample: ref<int>,
  lastCompletedAtMs: ref<float>,
  emaSecondsPerItem: ref<float>,
  completionSampleCount: ref<int>,
  stableEtaSeconds: ref<float>,
  etaReady: ref<bool>,
  wasCancelled: ref<bool>,
  lastEtaToastAtMs: ref<float>,
  lastEtaToastValue: ref<int>,
  countdownTimerId: ref<option<int>>,
}

let makeTracker = (~progressToastId, ~initialItems: int): tracker => {
  let startedAtMs = Date.now()
  {
    progressToastId,
    startedAtMs,
    knownTotalItems: ref(initialItems),
    lastPctSample: ref(0.0),
    lastSampleAtMs: ref(startedAtMs),
    emaProgressPerSecond: ref(0.0),
    lastCompletedSample: ref(0),
    lastCompletedAtMs: ref(startedAtMs),
    emaSecondsPerItem: ref(0.0),
    completionSampleCount: ref(0),
    stableEtaSeconds: ref(0.0),
    etaReady: ref(false),
    wasCancelled: ref(false),
    lastEtaToastAtMs: ref(0.0),
    lastEtaToastValue: ref(0),
    countdownTimerId: ref(None),
  }
}

let stopCountdown = tracker => {
  tracker.countdownTimerId.contents->Option.forEach(id => ReBindings.Window.clearInterval(id))
  tracker.countdownTimerId := None
}

let startCountdown = tracker => {
  stopCountdown(tracker)
  tracker.countdownTimerId := Some(ReBindings.Window.setInterval(() => {
        if (
          tracker.stableEtaSeconds.contents > 1.0 &&
          tracker.etaReady.contents &&
          !tracker.wasCancelled.contents
        ) {
          tracker.stableEtaSeconds := tracker.stableEtaSeconds.contents -. 1.0
          let seconds = Belt.Float.toInt(tracker.stableEtaSeconds.contents)
          let now = Date.now()
          if (
            now -. tracker.lastEtaToastAtMs.contents >= 900.0 &&
              seconds != tracker.lastEtaToastValue.contents
          ) {
            tracker.lastEtaToastAtMs := now
            tracker.lastEtaToastValue := seconds
            EtaSupport.updateEtaToast(
              ~id=tracker.progressToastId,
              ~contextOperation="eta_upload",
              ~prefix="Uploading",
              ~etaSeconds=seconds,
              (),
            )
          }
        }
      }, 1000))
}

let cleanup = tracker => {
  stopCountdown(tracker)
  EtaSupport.dismissEtaToast(tracker.progressToastId)
}

let markCancelledIfNeeded = (~tracker, ~phase: string, ~msg: string) => {
  if phase == "Cancelled" || String.startsWith(msg, "Cancelled") {
    tracker.wasCancelled := true
    cleanup(tracker)
  }
}

let currentEtaLabel = (~tracker, ~processorEta: option<string>, ~isProc: bool, ~pct: float) =>
  if tracker.etaReady.contents {
    Some("ETA " ++ EtaSupport.formatEta(Belt.Float.toInt(tracker.stableEtaSeconds.contents)))
  } else if isProc && pct > 0.0 && pct < 100.0 {
    Some("Calculating...")
  } else {
    processorEta
  }

let ingestProcessingSample = (~tracker, ~pct: float, ~msg: string) => {
  let now = Date.now()
  let parsedMetrics = SidebarUploadMetrics.parseProcessingMetrics(msg)

  parsedMetrics->Option.forEach(m => {
    tracker.knownTotalItems := m.total
    if m.completed > tracker.lastCompletedSample.contents {
      let deltaItems = m.completed - tracker.lastCompletedSample.contents
      let deltaSeconds = (now -. tracker.lastCompletedAtMs.contents) /. 1000.0
      if deltaItems > 0 && deltaSeconds > 0.4 {
        let instSecondsPerItem = deltaSeconds /. Belt.Int.toFloat(deltaItems)
        if tracker.emaSecondsPerItem.contents <= 0.0 {
          tracker.emaSecondsPerItem := instSecondsPerItem
        } else {
          tracker.emaSecondsPerItem :=
            0.60 *. tracker.emaSecondsPerItem.contents +. 0.40 *. instSecondsPerItem
        }
        tracker.completionSampleCount := tracker.completionSampleCount.contents + 1
      }
      tracker.lastCompletedSample := m.completed
      tracker.lastCompletedAtMs := now
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
        0.7 *. tracker.emaProgressPerSecond.contents +. 0.3 *. instRate
    }
    tracker.lastPctSample := pct
    tracker.lastSampleAtMs := now
  }

  let elapsedSec = (now -. tracker.startedAtMs) /. 1000.0
  if (
    !tracker.etaReady.contents &&
    tracker.completionSampleCount.contents >= 2 &&
    elapsedSec >= 15.0 &&
    pct >= 10.0 &&
    tracker.emaProgressPerSecond.contents > 0.0
  ) {
    tracker.etaReady := true
    let seconds = Belt.Float.toInt(tracker.stableEtaSeconds.contents)
    if seconds > 0 {
      EtaSupport.updateEtaToast(
        ~id=tracker.progressToastId,
        ~contextOperation="eta_upload",
        ~prefix="Uploading",
        ~etaSeconds=seconds,
        (),
      )
    }
  }

  let processedItems = tracker.lastCompletedSample.contents
  let totalItems = tracker.knownTotalItems.contents
  let remainingItems = if totalItems > processedItems {
    totalItems - processedItems
  } else {
    0
  }

  let etaByRecentItemRate = if tracker.emaSecondsPerItem.contents > 0.0 && remainingItems > 0 {
    Some(tracker.emaSecondsPerItem.contents *. Belt.Int.toFloat(remainingItems))
  } else {
    None
  }
  let etaByGlobalItemAverage = if processedItems >= 1 && remainingItems > 0 {
    let avgSecPerItem = elapsedSec /. Belt.Int.toFloat(processedItems)
    Some(avgSecPerItem *. Belt.Int.toFloat(remainingItems))
  } else {
    None
  }
  let etaByProgressSlope = if tracker.emaProgressPerSecond.contents > 0.0 {
    Some((100.0 -. pct) /. tracker.emaProgressPerSecond.contents)
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
      ->Option.map(u =>
        0.92 +. 0.08 *. EtaSupport.clampFloat(~value=u, ~minValue=0.0, ~maxValue=1.0)
      )
      ->Option.getOr(1.0)
    | None => 1.0
    }
    raw *. utilizationFactor
  })

  switch blendedEta {
  | Some(candidate) if tracker.etaReady.contents =>
    let smoothed = if tracker.stableEtaSeconds.contents <= 0.0 {
      candidate
    } else {
      let raw = 0.65 *. tracker.stableEtaSeconds.contents +. 0.35 *. candidate
      let maxRise = tracker.stableEtaSeconds.contents +. 30.0
      let maxDrop = tracker.stableEtaSeconds.contents -. 40.0
      EtaSupport.clampFloat(~value=raw, ~minValue=Math.max(1.0, maxDrop), ~maxValue=maxRise)
    }
    tracker.stableEtaSeconds := smoothed
  | _ => ()
  }
}
