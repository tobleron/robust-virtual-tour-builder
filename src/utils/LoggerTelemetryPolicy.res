/* src/utils/LoggerTelemetryPolicy.res */

open LoggerCommon

let queueFillRatio = (~telemetryQueue: array<logEntry>): float => {
  let maxSize = Constants.Telemetry.queueMaxSize
  if maxSize <= 0 {
    0.0
  } else {
    Belt.Int.toFloat(Array.length(telemetryQueue)) /. Belt.Int.toFloat(maxSize)
  }
}

let shouldSendLowPriority = (~telemetryQueue: array<logEntry>): bool => {
  let fill = queueFillRatio(~telemetryQueue)
  if fill >= Constants.Telemetry.lowPriorityDropThreshold {
    false
  } else if fill >= Constants.Telemetry.lowPrioritySamplingThreshold {
    Math.random() < Constants.Telemetry.lowPrioritySamplingRate
  } else {
    true
  }
}

let shouldQueueForPriority = (~telemetryQueue: array<logEntry>, p: priority) =>
  switch p {
  | Low => shouldSendLowPriority(~telemetryQueue)
  | _ => true
  }

let runIdle = (_task: unit => unit) =>
  %raw(`(function(task){
    if (typeof window !== "undefined" && typeof window.requestIdleCallback === "function") {
      window.requestIdleCallback(() => task(), {timeout: 1500});
    } else {
      setTimeout(task, 0);
    }
  })(_task)`)

let scheduleIdleFlush = (
  ~idleFlushPending: ref<bool>,
  ~runIdle: (unit => unit) => unit,
  ~flushTelemetry: unit => Promise.t<unit>,
) => {
  if !idleFlushPending.contents {
    idleFlushPending := true
    runIdle(() => {
      idleFlushPending := false
      let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
    })
  }
}

let shouldSampleByLevel = (
  ~adaptiveSamplingScale: ref<float>,
  ~sampleRateInfo: float,
  ~sampleRateDebugProd: float,
  level: level,
): bool => {
  let baseRate = switch level {
  | Warn => 1.0
  | Info | Perf => sampleRateInfo
  | Trace =>
    if Constants.Telemetry.diagnosticMode.contents {
      1.0
    } else {
      0.0
    }
  | Debug =>
    if Constants.isDebugBuild() || Constants.Telemetry.diagnosticMode.contents {
      1.0
    } else {
      sampleRateDebugProd
    }
  | _ => 1.0
  }

  if baseRate >= 1.0 {
    true
  } else if baseRate <= 0.0 {
    false
  } else {
    let effectiveRate = baseRate *. adaptiveSamplingScale.contents
    Math.random() < effectiveRate
  }
}
