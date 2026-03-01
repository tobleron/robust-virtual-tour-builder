/* src/utils/AsyncQueue.res */
// @efficiency-role: utility

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

let getHeapUsageRatio = (): option<float> =>
  %raw(`(function(){
    try {
      const p = typeof performance !== "undefined" ? performance : null;
      if (!p || !p.memory || !p.memory.jsHeapSizeLimit || p.memory.jsHeapSizeLimit <= 0) {
        return undefined;
      }
      return p.memory.usedJSHeapSize / p.memory.jsHeapSizeLimit;
    } catch (_) {
      return undefined;
    }
  })()`)

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

let computeStatus = (activeStatuses, startedCount, total) => {
  let counts = Dict.make()
  let activeCount = ref(0)
  Dict.toArray(activeStatuses)->Belt.Array.forEach(((_k, status)) => {
    if status != "__DONE__" && status != "__Error__" {
      activeCount := activeCount.contents + 1
      let current = Dict.get(counts, status)->Option.getOr(0)
      Dict.set(counts, status, current + 1)
    }
  })

  let baseMsg = "Processing " ++ Belt.Int.toString(startedCount) ++ "/" ++ Belt.Int.toString(total)
  if activeCount.contents > 0 {
    baseMsg ++ " | Active: " ++ Belt.Int.toString(activeCount.contents)
  } else {
    baseMsg
  }
}

let executeAdaptive = (
  items: array<'item>,
  ~config: option<adaptiveConfig>=?,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
): Promise.t<adaptiveExecuteResult<'result>> => {
  let cfg = config->Option.getOr(defaultAdaptiveConfig)
  let total = Array.length(items)
  let results = Belt.Array.make(total, None)
  let currentIndex = ref(0)
  let completedCount = ref(0)
  let activeCount = ref(0)
  let currentConcurrency = ref(cfg.initialConcurrency)
  let successSinceAdjustment = ref(0)
  let activeStatuses = Dict.make()
  let latencies = []
  let recentErrors = []

  let adjustConcurrencyOnBackpressure = (~queueDepth: int) => {
    if queueDepth > currentConcurrency.contents * 2 {
      Logger.warn(
        ~module_="AsyncQueue",
        ~message="BACKPRESSURE_SIGNAL",
        ~data=Logger.castToJson({
          "queueDepth": queueDepth,
          "concurrency": currentConcurrency.contents,
        }),
        (),
      )
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
    if Array.length(recentErrors) > cfg.errorWindow {
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
      p95 > cfg.latencyThresholdMs ||
      heapPressure > 0.8 ||
      currentErrorRate > cfg.errorRateThreshold
    ) {
      let halved = Math.Int.max(cfg.minConcurrency, currentConcurrency.contents / 2)
      let forced = if currentErrorRate > cfg.errorRateThreshold {
        cfg.minConcurrency
      } else {
        halved
      }
      currentConcurrency := forced
      successSinceAdjustment := 0
    } else {
      successSinceAdjustment := successSinceAdjustment.contents + 1
      if successSinceAdjustment.contents >= cfg.successWindow {
        currentConcurrency := Math.Int.min(cfg.maxConcurrency, currentConcurrency.contents + 1)
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
          let _ = Belt.Array.set(results, i, Some(Success(res)))
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
          let (msg, _) = getErrorDetails(err)
          error(
            ~module_="AsyncQueue",
            ~message="ADAPTIVE_WORKER_UNHANDLED_ERROR",
            ~data=castToJson({"index": i, "error": msg}),
            (),
          )
          let _ = Belt.Array.set(results, i, Some(Failed(i, msg)))
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
      let stats: adaptiveStats = {
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
    let stats: adaptiveStats = {
      p50LatencyMs: 0.0,
      p95LatencyMs: 0.0,
      avgLatencyMs: 0.0,
      errorRate: 0.0,
      finalConcurrency: cfg.initialConcurrency,
    }
    resolve.contents({results: [], stats})
  } else {
    pumpRef.contents()
  }
  promise
}

let execute = (
  items: array<'item>,
  maxConcurrency: int,
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
) => {
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
    // No reject handling needed for now
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
            let _ = Belt.Array.set(results, i, Some(Success(res)))
            completedCount := completedCount.contents + 1
            Dict.set(activeStatuses, Belt.Int.toString(i), "__DONE__")
            report()
            next()
            Promise.resolve()
          })
          ->Promise.catch(err => {
            let (msg, _) = getErrorDetails(err)
            error(
              ~module_="AsyncQueue",
              ~message="WORKER_UNHANDLED_ERROR",
              ~data=castToJson({"index": i, "error": msg}),
              (),
            )
            let _ = Belt.Array.set(results, i, Some(Failed(i, msg)))
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
  worker: (int, 'item, string => unit) => Promise.t<'result>,
  onProgress: (float, string) => unit,
) => {
  let total = Array.length(items)
  let results = Belt.Array.make(total, None)
  let currentIndex = ref(0)
  let completedCount = ref(0)
  let activeCount = ref(0)
  let inFlightWeight = ref(0.0)
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
  let pumpRef: ref<unit => unit> = ref(() => ())

  let canStart = (weight: float): bool =>
    activeCount.contents < maxConcurrency && inFlightWeight.contents +. weight <= maxInFlightWeight

  let rec tryLaunch = (): bool => {
    if currentIndex.contents >= total || activeCount.contents >= maxConcurrency {
      false
    } else {
      switch Belt.Array.get(items, currentIndex.contents) {
      | None =>
        currentIndex := currentIndex.contents + 1
        tryLaunch()
      | Some(item) =>
        let rawWeight = weightOf(item)
        let weight = if rawWeight > 0.1 {
          rawWeight
        } else {
          0.1
        }
        if !(canStart(weight) || activeCount.contents == 0) {
          false
        } else {
          let i = currentIndex.contents
          currentIndex := i + 1
          activeCount := activeCount.contents + 1
          inFlightWeight := inFlightWeight.contents +. weight
          Dict.set(activeStatuses, Belt.Int.toString(i), "Pending")
          report()

          let finish = (resultOpt: option<queueResult<'result>>, status: string) => {
            resultOpt->Belt.Option.forEach(r => {
              let _ = Belt.Array.set(results, i, Some(r))
            })
            completedCount := completedCount.contents + 1
            activeCount := activeCount.contents - 1
            let nextWeight = inFlightWeight.contents -. weight
            inFlightWeight := if nextWeight > 0.0 {
                nextWeight
              } else {
                0.0
              }
            Dict.set(activeStatuses, Belt.Int.toString(i), status)
            report()
            pumpRef.contents()
          }

          worker(i, item, status => {
            Dict.set(activeStatuses, Belt.Int.toString(i), status)
            report()
          })
          ->Promise.then(res => {
            finish(Some(Success(res)), "__DONE__")
            Promise.resolve()
          })
          ->Promise.catch(err => {
            let (msg, _) = getErrorDetails(err)
            error(
              ~module_="AsyncQueue",
              ~message="WEIGHTED_WORKER_UNHANDLED_ERROR",
              ~data=castToJson({"index": i, "error": msg}),
              (),
            )
            finish(Some(Failed(i, msg)), "__Error__")
            Promise.resolve()
          })
          ->ignore

          true
        }
      }
    }
  }

  let pump = () => {
    if completedCount.contents == total {
      resolve.contents(Belt.Array.keepMap(results, x => x))
    } else {
      let rec launchLoop = (launchedAny: bool): bool => {
        if tryLaunch() {
          launchLoop(true)
        } else {
          launchedAny
        }
      }

      let launchedAny = launchLoop(false)
      if !launchedAny && activeCount.contents == 0 && currentIndex.contents >= total {
        resolve.contents(Belt.Array.keepMap(results, x => x))
      }
    }
  }
  pumpRef := pump

  if total == 0 {
    resolve.contents([])
  } else {
    pumpRef.contents()
  }
  promise
}
