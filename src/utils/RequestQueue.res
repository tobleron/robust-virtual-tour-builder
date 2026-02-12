/* src/utils/RequestQueue.res */

let maxConcurrent = 6
let maxQueued = 256
let activeCount = ref(0)
let queue: array<unit => Promise.t<unit>> = []

let rec process = () => {
  if activeCount.contents < maxConcurrent && Array.length(queue) > 0 {
    switch Array.shift(queue) {
    | Some(run) =>
      activeCount := activeCount.contents + 1
      try {
        run()
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

let schedule = (task: unit => Promise.t<'a>): Promise.t<'a> => {
  Promise.make((resolve, reject) => {
    if Array.length(queue) >= maxQueued {
      reject("RequestQueueOverflow")
    } else {
      let run = () => {
        try {
          task()
          ->Promise.then(result => {
            resolve(result)
            Promise.resolve()
          })
          ->Promise.catch(err => {
            reject(String.make(err))
            Promise.resolve()
          })
        } catch {
        | e => {
            reject(String.make(e))
            Promise.resolve()
          }
        }
      }

      let _ = Array.push(queue, run)
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
