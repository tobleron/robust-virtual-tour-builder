/* src/utils/RequestQueue.res */

let maxConcurrent = 6
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

    let _ = Array.push(queue, run)
    process()
  })
}

let scheduleWithRetry = (
  ~task: unit => Promise.t<result<'a, string>>,
  ~retryConfig: option<Retry.config>=?,
  ~onRetry: option<(int, string, int) => unit>=?,
) => {
  schedule(() => {
    let controller = ReBindings.AbortController.make()

    Retry.execute(
      ~fn=(~signal as _) => task(),
      ~signal=ReBindings.AbortController.signal(controller),
      ~config=?retryConfig,
      ~onRetry?,
    )
  })
}
