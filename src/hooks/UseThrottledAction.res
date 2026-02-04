open EventBus
open ReBindings

let useThrottledAction = (
  ~action: unit => Promise.t<'a>,
  ~debounceMs: int,
  ~rateLimit: (int, int),
) => {
  let (maxCalls, windowMs) = rateLimit

  let rateLimiter = React.useMemo2(() => {
    RateLimiter.make(~maxCalls, ~windowMs)
  }, (maxCalls, windowMs))

  let (isPending, setPending) = React.useState(() => false)
  let (isThrottled, setThrottled) = React.useState(() => false)

  let actionRef = React.useRef(action)
  React.useEffect1(() => {
    actionRef.current = action
    None
  }, [action])

  let debounced = React.useMemo2(() => {
    Debounce.make(
      ~fn=() => {
        if RateLimiter.canCall(rateLimiter) {
             RateLimiter.recordCall(rateLimiter)

             if !RateLimiter.canCall(rateLimiter) {
                 setThrottled(_ => true)
                 let _ = Window.setTimeout(() => setThrottled(_ => false), windowMs)
             }

             setPending(_ => true)
             actionRef.current()
             ->Promise.then(res => {
               setPending(_ => false)
               Promise.resolve(Some(res))
             })
             ->Promise.catch(_ => {
               setPending(_ => false)
               Promise.resolve(None)
             })
         } else {
             setThrottled(_ => true)
             let _ = Window.setTimeout(() => setThrottled(_ => false), windowMs)

             EventBus.dispatch(ShowNotification(
               "Rate limit exceeded. Please wait.",
               #Warning,
               None
             ))
             Promise.resolve(None)
         }
      },
      ~wait=debounceMs,
      ~leading=true,
      ~trailing=false
    )
  }, (debounceMs, rateLimiter))

  React.useEffect1(() => {
    Some(() => debounced.cancel())
  }, [debounced])

  let execute = () => {
    if isPending {
      Promise.resolve(None)
    } else {
      debounced.call()
    }
  }

  (execute, isPending, isThrottled)
}
