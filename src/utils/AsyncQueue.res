/* src/utils/AsyncQueue.res */
// @efficiency-role: service-orchestrator

open Logger

type queueResult<'result> =
  | Success('result)
  | Failed(int, string)

type adaptiveConfig = {
  initialConcurrency: int,
  minConcurrency: int,
  maxConcurrency: int,
  successWindow: int,
  latencyThresholdMs: float,
  errorWindow: int,
  errorRateThreshold: float,
}

type adaptiveStats = {
  p50LatencyMs: float,
  p95LatencyMs: float,
  avgLatencyMs: float,
  errorRate: float,
  finalConcurrency: int,
}

type adaptiveExecuteResult<'result> = {
  results: array<queueResult<'result>>,
  stats: adaptiveStats,
}

let defaultAdaptiveConfig: adaptiveConfig = {
  initialConcurrency: 2,
  minConcurrency: 1,
  maxConcurrency: 6,
  successWindow: 3,
  latencyThresholdMs: 2000.0,
  errorWindow: 10,
  errorRateThreshold: 0.2,
}

let getHeapUsageRatio = (): option<float> => AsyncQueueStats.getHeapUsageRatio()

let toSortedCopy = (values: array<float>): array<float> => {
  let copied = Belt.Array.map(values, x => x)
  Array.sort(copied, (a, b) =>
    if a < b {
      -1.0
    } else if a > b {
      1.0
    } else {
      0.0
    }
  )
  copied
}

let percentile = (values: array<float>, p: float): float => {
  let len = Array.length(values)
  if len == 0 {
    0.0
  } else {
    let sorted = toSortedCopy(values)
    let idx = Belt.Int.fromFloat(Math.floor(Float.fromInt(len - 1) *. p))
    Belt.Array.get(sorted, idx)->Option.getOr(0.0)
  }
}

let average = (values: array<float>): float => {
  let len = Array.length(values)
  if len == 0 {
    0.0
  } else {
    values->Belt.Array.reduce(0.0, (acc, x) => acc +. x) /. Float.fromInt(len)
  }
}

let computeStatus = (activeStatuses, startedCount, total) =>
  AsyncQueueStats.computeStatus(activeStatuses, startedCount, total)

let logBackpressure = (queueDepth: int, concurrency: int) => {
  Logger.warn(
    ~module_="AsyncQueue",
    ~message="BACKPRESSURE_SIGNAL",
    ~data=Logger.castToJson({"queueDepth": queueDepth, "concurrency": concurrency}),
    (),
  )
}

let logUnhandledError = (message: string, index: int, errorMessage: string) => {
  error(
    ~module_="AsyncQueue",
    ~message,
    ~data=castToJson({"index": index, "error": errorMessage}),
    (),
  )
}

let executeAdaptive = (
  items: array<'item>,
  ~config: option<adaptiveConfig>=?,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
): Promise.t<adaptiveExecuteResult<'result>> => {
  let cfg = config->Option.getOr(defaultAdaptiveConfig)
  AsyncQueueRuntime.executeAdaptive(
    items,
    ~initialConcurrency=cfg.initialConcurrency,
    ~minConcurrency=cfg.minConcurrency,
    ~maxConcurrency=cfg.maxConcurrency,
    ~successWindow=cfg.successWindow,
    ~latencyThresholdMs=cfg.latencyThresholdMs,
    ~errorWindow=cfg.errorWindow,
    ~errorRateThreshold=cfg.errorRateThreshold,
    ~getHeapUsageRatio,
    ~average,
    ~percentile,
    ~computeStatus,
    ~logBackpressure,
    ~logUnhandledError,
    ~makeSuccess=res => Success(res),
    ~makeFailure=(index, message) => Failed(index, message),
    worker,
    onProgress,
  )->Promise.then(result => {
    let stats: adaptiveStats = {
      p50LatencyMs: result.stats.p50LatencyMs,
      p95LatencyMs: result.stats.p95LatencyMs,
      avgLatencyMs: result.stats.avgLatencyMs,
      errorRate: result.stats.errorRate,
      finalConcurrency: result.stats.finalConcurrency,
    }
    Promise.resolve({results: result.results, stats})
  })
}

let execute = (
  items: array<'item>,
  maxConcurrency: int,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
) => {
  AsyncQueueRuntime.execute(
    items,
    ~maxConcurrency,
    ~computeStatus,
    ~logUnhandledError,
    ~makeSuccess=res => Success(res),
    ~makeFailure=(index, message) => Failed(index, message),
    worker,
    onProgress,
  )
}

let executeWeighted = (
  items: array<'item>,
  ~maxConcurrency: int,
  ~weightOf: 'item => float,
  ~maxInFlightWeight: float,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
) => {
  AsyncQueueRuntime.executeWeighted(
    items,
    ~maxConcurrency,
    ~weightOf,
    ~maxInFlightWeight,
    ~computeStatus,
    ~logUnhandledError,
    ~makeSuccess=res => Success(res),
    ~makeFailure=(index, message) => Failed(index, message),
    worker,
    onProgress,
  )
}
