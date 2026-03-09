/* src/utils/WorkerPoolRequests.res */

let createRequestId = (): string =>
  Math.random()->Float.toString ++ "_" ++ Date.now()->Float.toInt->Int.toString

let installAbortHandler = (
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onAbort: unit => unit,
): ref<option<unit => unit>> => {
  let removeOnAbort = ref(None)
  signal->Option.forEach(sig => {
    let onAbortEvent = () => onAbort()
    BrowserBindings.AbortSignal.addEventListener(sig, "abort", onAbortEvent)
    removeOnAbort :=
      Some(() => BrowserBindings.AbortSignal.removeEventListener(sig, "abort", onAbortEvent))
    if BrowserBindings.AbortSignal.aborted(sig) {
      onAbortEvent()
    }
  })
  removeOnAbort
}

let runRequest = (
  pool: WorkerPoolCore.state,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~waitersRef: ref<array<WorkerPoolCore.waiter<'a>>>,
  ~removeWaiter: (WorkerPoolCore.state, string) => option<WorkerPoolCore.waiter<'a>>,
  ~abortValue: 'a,
  ~send: (WorkerPoolCore.worker, string) => unit,
): Promise.t<'a> =>
  Promise.make((resolve, _reject) => {
    let id = createRequestId()
    let settled = ref(false)
    let finish = value => {
      if !settled.contents {
        settled := true
        resolve(value)
      }
    }
    let removeOnAbort = installAbortHandler(
      ~signal?,
      ~onAbort=(() => {
        let _ = removeWaiter(pool, id)
        finish(abortValue)
      }),
    )
    waitersRef := Belt.Array.concat(waitersRef.contents, [{id, resolve}])
    waitersRef :=
      waitersRef.contents->Belt.Array.map(waiter =>
        if waiter.id == id {
          {
            ...waiter,
            resolve: value => {
              removeOnAbort.contents->Option.forEach(cb => cb())
              finish(value)
            },
          }
        } else {
          waiter
        }
      )
    let worker = WorkerPoolCore.takeWorker(pool)
    send(worker, id)
  })
