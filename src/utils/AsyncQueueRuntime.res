/* src/utils/AsyncQueueRuntime.res */
// @efficiency-role: service-orchestrator

type adaptiveStatsSnapshot = {
  p50LatencyMs: float,
  p95LatencyMs: float,
  avgLatencyMs: float,
  errorRate: float,
  finalConcurrency: int,
}

type adaptiveRuntimeResult<'result> = {
  results: array<'result>,
  stats: adaptiveStatsSnapshot,
}

let executeAdaptive = (
  items: array<'item>,
  ~initialConcurrency: int,
  ~minConcurrency: int,
  ~maxConcurrency: int,
  ~successWindow: int,
  ~latencyThresholdMs: float,
  ~errorWindow: int,
  ~errorRateThreshold: float,
  ~getHeapUsageRatio: unit => option<float>,
  ~average: array<float> => float,
  ~percentile: (array<float>, float) => float,
  ~computeStatus: (Dict.t<string>, int, int) => string,
  ~logBackpressure: (int, int) => unit,
  ~logUnhandledError: (string, int, string) => unit,
  ~makeSuccess: 'value => 'result,
  ~makeFailure: (int, string) => 'result,
  worker: (int, 'item, string => unit) => Promise.t<'value>,
  onProgress: (float, string) => unit,
): Promise.t<adaptiveRuntimeResult<'result>> => {
  AsyncQueueAdaptiveRuntime.executeAdaptive(
    items,
    ~initialConcurrency,
    ~minConcurrency,
    ~maxConcurrency,
    ~successWindow,
    ~latencyThresholdMs,
    ~errorWindow,
    ~errorRateThreshold,
    ~getHeapUsageRatio,
    ~average,
    ~percentile,
    ~computeStatus,
    ~logBackpressure,
    ~logUnhandledError,
    ~makeSuccess,
    ~makeFailure,
    worker,
    onProgress,
  )->Promise.then(result => {
    let stats: adaptiveStatsSnapshot = {
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
  ~maxConcurrency: int,
  ~computeStatus: (Dict.t<string>, int, int) => string,
  ~logUnhandledError: (string, int, string) => unit,
  ~makeSuccess: 'value => 'result,
  ~makeFailure: (int, string) => 'result,
  worker: (int, 'item, string => unit) => Promise.t<'value>,
  onProgress: (float, string) => unit,
): Promise.t<array<'result>> => {
  let total = Array.length(items)
  let results = Belt.Array.make(total, None)
  let currentIndex = ref(0)
  let completedCount = ref(0)
  let activeStatuses = Dict.make()

  let report = () => {
    let msg = computeStatus(activeStatuses, currentIndex.contents, total)
    let pct = if total > 0 {
      Float.fromInt(completedCount.contents) /. Float.fromInt(total)
    } else {
      1.0
    }
    onProgress(pct, msg)
  }

  let (resolve, _) = (ref(ignore), ref(ignore))
  let promise = Promise.make((res, _rej) => {
    resolve := res
  })

  let rec next = () => {
    if currentIndex.contents >= total {
      if completedCount.contents == total {
        resolve.contents(Belt.Array.keepMap(results, x => x))
      }
    } else {
      let i = currentIndex.contents
      currentIndex := i + 1
      switch Belt.Array.get(items, i) {
      | Some(item) =>
        Dict.set(activeStatuses, Belt.Int.toString(i), "Pending")
        report()

        let _ =
          worker(i, item, status => {
            Dict.set(activeStatuses, Belt.Int.toString(i), status)
            report()
          })
          ->Promise.then(res => {
            let _ = Belt.Array.set(results, i, Some(makeSuccess(res)))
            completedCount := completedCount.contents + 1
            Dict.set(activeStatuses, Belt.Int.toString(i), "__DONE__")
            report()
            next()
            Promise.resolve()
          })
          ->Promise.catch(err => {
            let (msg, _) = LoggerCommon.getErrorDetails(err)
            logUnhandledError("WORKER_UNHANDLED_ERROR", i, msg)
            let _ = Belt.Array.set(results, i, Some(makeFailure(i, msg)))
            completedCount := completedCount.contents + 1
            Dict.set(activeStatuses, Belt.Int.toString(i), "__Error__")
            report()
            next()
            Promise.resolve()
          })
      | None => ()
      }
    }
  }

  let initialWorkers = Math.Int.min(maxConcurrency, total)
  if total == 0 {
    resolve.contents([])
  } else {
    for _ in 1 to initialWorkers {
      next()
    }
  }
  promise
}

let executeWeighted = (
  items: array<'item>,
  ~maxConcurrency: int,
  ~weightOf: 'item => float,
  ~maxInFlightWeight: float,
  ~computeStatus: (Dict.t<string>, int, int) => string,
  ~logUnhandledError: (string, int, string) => unit,
  ~makeSuccess: 'value => 'result,
  ~makeFailure: (int, string) => 'result,
  worker: (int, 'item, string => unit) => Promise.t<'value>,
  onProgress: (float, string) => unit,
): Promise.t<array<'result>> => {
  AsyncQueueWeightedRuntime.executeWeighted(
    items,
    ~maxConcurrency,
    ~weightOf,
    ~maxInFlightWeight,
    ~computeStatus,
    ~logUnhandledError,
    ~makeSuccess,
    ~makeFailure,
    worker,
    onProgress,
  )
}
