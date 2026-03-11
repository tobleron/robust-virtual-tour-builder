/* src/utils/AsyncQueueAdaptiveRuntime.res */
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
  let total = Array.length(items)
  let results = Belt.Array.make(total, None)
  let currentIndex = ref(0)
  let completedCount = ref(0)
  let activeCount = ref(0)
  let currentConcurrency = ref(initialConcurrency)
  let successSinceAdjustment = ref(0)
  let activeStatuses = Dict.make()
  let latencies = []
  let recentErrors = []

  let adjustConcurrencyOnBackpressure = (~queueDepth: int) => {
    if queueDepth > currentConcurrency.contents * 2 {
      logBackpressure(queueDepth, currentConcurrency.contents)
    }
  }

  let recordError = (isError: bool) => {
    let _ = Array.push(
      recentErrors,
      if isError {
        1.0
      } else {
        0.0
      },
    )
    if Array.length(recentErrors) > errorWindow {
      ignore(Array.shift(recentErrors))
    }
  }

  let updateAimd = (~isError: bool, ~latencyMs: float) => {
    let _ = Array.push(latencies, latencyMs)
    recordError(isError)

    let currentErrorRate = average(recentErrors)
    let p95 = percentile(latencies, 0.95)
    let heapPressure = getHeapUsageRatio()->Option.getOr(0.0)

    if (
      isError ||
      p95 > latencyThresholdMs ||
      heapPressure > 0.8 ||
      currentErrorRate > errorRateThreshold
    ) {
      let halved = Math.Int.max(minConcurrency, currentConcurrency.contents / 2)
      let forced = if currentErrorRate > errorRateThreshold {
        minConcurrency
      } else {
        halved
      }
      currentConcurrency := forced
      successSinceAdjustment := 0
    } else {
      successSinceAdjustment := successSinceAdjustment.contents + 1
      if successSinceAdjustment.contents >= successWindow {
        currentConcurrency := Math.Int.min(maxConcurrency, currentConcurrency.contents + 1)
        successSinceAdjustment := 0
      }
    }
  }

  let report = () => {
    let msg = computeStatus(activeStatuses, currentIndex.contents, total)
    let pct = if total > 0 {
      Float.fromInt(completedCount.contents) /. Float.fromInt(total)
    } else {
      1.0
    }
    onProgress(pct, msg)
    adjustConcurrencyOnBackpressure(
      ~queueDepth=total - completedCount.contents - activeCount.contents,
    )
  }

  let (resolve, _) = (ref(ignore), ref(ignore))
  let promise = Promise.make((res, _rej) => {
    resolve := res
  })
  let pumpRef: ref<unit => unit> = ref(() => ())

  let rec tryLaunch = (): bool => {
    if currentIndex.contents >= total || activeCount.contents >= currentConcurrency.contents {
      false
    } else {
      switch Belt.Array.get(items, currentIndex.contents) {
      | None =>
        currentIndex := currentIndex.contents + 1
        tryLaunch()
      | Some(item) =>
        let i = currentIndex.contents
        currentIndex := i + 1
        activeCount := activeCount.contents + 1
        Dict.set(activeStatuses, Belt.Int.toString(i), "Pending")
        report()

        let startedAt = Date.now()
        worker(i, item, status => {
          Dict.set(activeStatuses, Belt.Int.toString(i), status)
          report()
        })
        ->Promise.then(res => {
          let _ = Belt.Array.set(results, i, Some(makeSuccess(res)))
          completedCount := completedCount.contents + 1
          activeCount := activeCount.contents - 1
          Dict.set(activeStatuses, Belt.Int.toString(i), "__DONE__")
          let latency = Date.now() -. startedAt
          updateAimd(~isError=false, ~latencyMs=latency)
          report()
          pumpRef.contents()
          Promise.resolve()
        })
        ->Promise.catch(err => {
          let (msg, _) = LoggerCommon.getErrorDetails(err)
          logUnhandledError("ADAPTIVE_WORKER_UNHANDLED_ERROR", i, msg)
          let _ = Belt.Array.set(results, i, Some(makeFailure(i, msg)))
          completedCount := completedCount.contents + 1
          activeCount := activeCount.contents - 1
          Dict.set(activeStatuses, Belt.Int.toString(i), "__Error__")
          let latency = Date.now() -. startedAt
          updateAimd(~isError=true, ~latencyMs=latency)
          report()
          pumpRef.contents()
          Promise.resolve()
        })
        ->ignore

        true
      }
    }
  }

  let pump = () => {
    if completedCount.contents == total {
      let stats: adaptiveStatsSnapshot = {
        p50LatencyMs: percentile(latencies, 0.5),
        p95LatencyMs: percentile(latencies, 0.95),
        avgLatencyMs: average(latencies),
        errorRate: average(recentErrors),
        finalConcurrency: currentConcurrency.contents,
      }
      resolve.contents({results: Belt.Array.keepMap(results, x => x), stats})
    } else {
      let rec launchLoop = (launchedAny: bool): bool => {
        if tryLaunch() {
          launchLoop(true)
        } else {
          launchedAny
        }
      }
      ignore(launchLoop(false))
    }
  }
  pumpRef := pump

  if total == 0 {
    let stats: adaptiveStatsSnapshot = {
      p50LatencyMs: 0.0,
      p95LatencyMs: 0.0,
      avgLatencyMs: 0.0,
      errorRate: 0.0,
      finalConcurrency: initialConcurrency,
    }
    resolve.contents({results: [], stats})
  } else {
    pumpRef.contents()
  }
  promise
}
