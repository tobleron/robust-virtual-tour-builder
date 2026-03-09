@get external aborted: ReBindings.AbortSignal.t => bool = "aborted"

let waitForDelay = (signal: ReBindings.AbortSignal.t, delay: int): Promise.t<bool> => {
  Promise.make((resolve, _reject) => {
    if aborted(signal) {
      resolve(false)
    } else {
      let timeoutId = ref(None)
      let done = ref(false)

      let rec onAbort = () => {
        if !done.contents {
          done := true
          switch timeoutId.contents {
          | Some(id) => ReBindings.Window.clearTimeout(id)
          | None => ()
          }
          signal->ReBindings.AbortSignal.removeEventListener("abort", onAbort)
          resolve(false)
        }
      }

      signal->ReBindings.AbortSignal.addEventListener("abort", onAbort)
      let tid = ReBindings.Window.setTimeout(() => {
        if !done.contents {
          done := true
          signal->ReBindings.AbortSignal.removeEventListener("abort", onAbort)
          resolve(true)
        }
      }, delay)

      timeoutId := Some(tid)
    }
  })
}
