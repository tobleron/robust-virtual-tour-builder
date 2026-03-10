/* src/utils/RequestQueue.res */

let maxConcurrent = 6
let maxQueued = 256
let criticalBurstSlots = 2
let activeCount = ref(0)

type priority =
  | Critical
  | Normal
  | Background

type queuedItem = {
  task: unit => Promise.t<unit>,
  reject: exn => unit,
  priority: priority,
  enqueuedAtMs: float,
}

let criticalQueue: array<queuedItem> = []
let normalQueue: array<queuedItem> = []
let backgroundQueue: array<queuedItem> = []

let paused = ref(false)
let nowMs: ref<unit => float> = ref(() => Date.now())
let scopeBackoffUntilMs = Dict.make()

let length = (): int =>
  Array.length(criticalQueue) + Array.length(normalQueue) + Array.length(backgroundQueue)

let logQueueDepths = (~reason: string) => {
  Logger.debug(
    ~module_="RequestQueue",
    ~message="QUEUE_DEPTHS",
    ~data=Some(
      Logger.castToJson({
        "reason": reason,
        "critical": Array.length(criticalQueue),
        "normal": Array.length(normalQueue),
        "background": Array.length(backgroundQueue),
        "active": activeCount.contents,
      }),
    ),
    (),
  )
}

let pushByPriority = (item: queuedItem) => {
  switch item.priority {
  | Critical => ignore(Array.push(criticalQueue, item))
  | Normal => ignore(Array.push(normalQueue, item))
  | Background => ignore(Array.push(backgroundQueue, item))
  }
}

let promoteStarved = () => {
  let now = nowMs.contents()
  let promoteQueue = (~queue, ~thresholdMs: float, ~priority) => {
    let (keep, promote) = queue->Belt.Array.partition(item => now -. item.enqueuedAtMs < thresholdMs)
    let _ = Array.splice(queue, ~start=0, ~remove=Array.length(queue), ~insert=keep)
    promote->Belt.Array.forEach(item => {
      pushByPriority({...item, priority})
    })
    Array.length(promote)
  }

  let backgroundPromotions = promoteQueue(~queue=backgroundQueue, ~thresholdMs=30000.0, ~priority=Normal)
  let normalPromotions = promoteQueue(~queue=normalQueue, ~thresholdMs=60000.0, ~priority=Critical)

  if backgroundPromotions > 0 || normalPromotions > 0 {
    logQueueDepths(~reason="starvation-promotion")
  }
}

let shiftNext = (): option<queuedItem> => {
  promoteStarved()
  [criticalQueue, normalQueue, backgroundQueue]
  ->Belt.Array.getBy(queue => Array.length(queue) > 0)
  ->Option.flatMap(Array.shift)
}

let currentConcurrencyLimit = () => {
  if Array.length(criticalQueue) > 0 {
    maxConcurrent + criticalBurstSlots
  } else {
    maxConcurrent
  }
}

let rec process = () => {
  if paused.contents {
    ()
  } else if activeCount.contents < currentConcurrencyLimit() && length() > 0 {
    switch shiftNext() {
    | Some(item) =>
      activeCount := activeCount.contents + 1
      logQueueDepths(~reason="dequeue")
      try {
        item.task()
        ->Promise.then(_ => {
          activeCount := activeCount.contents - 1
          process()
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          activeCount := activeCount.contents - 1
          process()
          Promise.resolve()
        })
        ->ignore
      } catch {
      | _ =>
        activeCount := activeCount.contents - 1
        process()
      }

      /* Try to start another one in parallel if slots remain */
      process()
    | None => ()
    }
  }
}

let pause = () => {
  paused := true
  Logger.debug(
    ~module_="RequestQueue",
    ~message="PAUSED",
    ~data=Some(Logger.castToJson({"queued": length()})),
    (),
  )
}

let resume = () => {
  paused := false
  Logger.debug(
    ~module_="RequestQueue",
    ~message="RESUMED",
    ~data=Some(Logger.castToJson({"queued": length()})),
    (),
  )
  process()
}

let handleRateLimit = (seconds: int) => {
  if !paused.contents {
    Logger.warn(
      ~module_="RequestQueue",
      ~message="RATE_LIMIT_PAUSE",
      ~data=Some(Logger.castToJson({"seconds": seconds})),
      (),
    )
    pause()
    let _ = ReBindings.Window.setTimeout(() => {
      // Only resume if network is online.
      if NetworkStatus.isOnline() {
        resume()
      }
    }, seconds * 1000)
  }
}

let handleRateLimitForScope = (~scope: string, ~seconds: int) => {
  let untilMs = nowMs.contents() +. Belt.Int.toFloat(seconds * 1000)
  Dict.set(scopeBackoffUntilMs, scope, untilMs)
  Logger.warn(
    ~module_="RequestQueue",
    ~message="RATE_LIMIT_SCOPE_BACKOFF",
    ~data=Some(Logger.castToJson({"scope": scope, "seconds": seconds})),
    (),
  )
}

let waitForScope = (~scope: string): Promise.t<unit> => {
  let untilMs = Dict.get(scopeBackoffUntilMs, scope)->Option.getOr(0.0)
  let remainingMs = untilMs -. nowMs.contents()
  if remainingMs <= 0.0 {
    Promise.resolve()
  } else {
    Promise.make((resolve, _reject) => {
      let delayMs = Belt.Float.toInt(remainingMs)
      let _ = ReBindings.Window.setTimeout(() => resolve(), delayMs)
    })
  }
}

let drain = (): int => {
  let count = length()
  let removed = Belt.Array.concatMany([
    Array.slice(criticalQueue, ~start=0, ~end=Array.length(criticalQueue)),
    Array.slice(normalQueue, ~start=0, ~end=Array.length(normalQueue)),
    Array.slice(backgroundQueue, ~start=0, ~end=Array.length(backgroundQueue)),
  ])
  let _ = Array.splice(criticalQueue, ~start=0, ~remove=Array.length(criticalQueue), ~insert=[])
  let _ = Array.splice(normalQueue, ~start=0, ~remove=Array.length(normalQueue), ~insert=[])
  let _ = Array.splice(backgroundQueue, ~start=0, ~remove=Array.length(backgroundQueue), ~insert=[])

  removed->Belt.Array.forEach(item => {
    item.reject(Failure("RequestQueueDrained"))
  })

  Logger.info(
    ~module_="RequestQueue",
    ~message="DRAINED",
    ~data=Some(Logger.castToJson({"drainedCount": count})),
    (),
  )
  count
}

let initializeNetworkListener = () => {
  let _unsubscribe = NetworkStatus.subscribe(online => {
    if online {
      resume()
    } else {
      pause()
    }
  })
}

let rec schedule = (task: unit => Promise.t<'a>): Promise.t<'a> => {
  scheduleWithPriority(~priority=Normal, task)
}

and scheduleWithPriority = (~priority: priority, task: unit => Promise.t<'a>): Promise.t<'a> => {
  Promise.make((resolve, reject) => {
    if length() >= maxQueued {
      reject(Failure("RequestQueueOverflow"))
    } else {
      let run = () => {
        try {
          task()
          ->Promise.then(result => {
            resolve(result)
            Promise.resolve()
          })
          ->Promise.catch(err => {
            reject(err)
            Promise.resolve()
          })
        } catch {
        | e => {
            reject(e)
            Promise.resolve()
          }
        }
      }

      pushByPriority({task: run, reject, priority, enqueuedAtMs: nowMs.contents()})
      logQueueDepths(~reason="enqueue")
      process()
    }
  })
}

let scheduleWithRetry = (
  ~task: unit => Promise.t<result<'a, string>>,
  ~priority: priority=Normal,
  ~retryConfig: option<Retry.config>=?,
  ~signal: option<ReBindings.AbortSignal.t>=?,
  ~onRetry: option<(int, string, int) => unit>=?,
) => {
  scheduleWithPriority(~priority, () => {
    let resolvedSignal = switch signal {
    | Some(s) => s
    | None =>
      let controller = ReBindings.AbortController.make()
      ReBindings.AbortController.signal(controller)
    }

    Retry.execute(
      ~fn=(~signal as _) => task(),
      ~signal=resolvedSignal,
      ~config=?retryConfig,
      ~onRetry?,
    )
  })
}
