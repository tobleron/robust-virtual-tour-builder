/* src/utils/AsyncQueueWeightedRuntime.res */
// @efficiency-role: service-orchestrator

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

          let finish = (resultOpt: option<'result>, status: string) => {
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
            finish(Some(makeSuccess(res)), "__DONE__")
            Promise.resolve()
          })
          ->Promise.catch(err => {
            let (msg, _) = LoggerCommon.getErrorDetails(err)
            logUnhandledError("WEIGHTED_WORKER_UNHANDLED_ERROR", i, msg)
            finish(Some(makeFailure(i, msg)), "__Error__")
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
