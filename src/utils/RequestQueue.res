/* src/utils/RequestQueue.res */

let maxConcurrent = 6
let maxQueued = 256
let activeCount = ref(0)

type queuedItem = {
  task: unit => Promise.t<unit>,
  reject: exn => unit,
}

let queue: array<queuedItem> = []

let paused = ref(false)

let length = (): int => Array.length(queue)

let rec process = () => {
  if paused.contents {
    ()
  } else if activeCount.contents < maxConcurrent && Array.length(queue) > 0 {
    switch Array.shift(queue) {
    | Some(item) =>
      activeCount := activeCount.contents + 1
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
    ~data=Some(Logger.castToJson({"queued": Array.length(queue)})),
    (),
  )
}

let resume = () => {
  paused := false
  Logger.debug(
    ~module_="RequestQueue",
    ~message="RESUMED",
    ~data=Some(Logger.castToJson({"queued": Array.length(queue)})),
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
      ()
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

let drain = (): int => {
  let count = Array.length(queue)
  let removed = Array.slice(queue, ~start=0, ~end=count)
  let _ = Array.splice(queue, ~start=0, ~remove=count, ~insert=[])

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

let schedule = (task: unit => Promise.t<'a>): Promise.t<'a> => {
  Promise.make((resolve, reject) => {
    if Array.length(queue) >= maxQueued {
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

      let _ = Array.push(queue, {task: run, reject})
      process()
    }
  })
}

let scheduleWithRetry = (
  ~task: unit => Promise.t<result<'a, string>>,
  ~retryConfig: option<Retry.config>=?,
  ~signal: option<ReBindings.AbortSignal.t>=?,
  ~onRetry: option<(int, string, int) => unit>=?,
) => {
  schedule(() => {
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
