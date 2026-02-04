open EventBus
open ReBindings

let useThrottledAction = (
  ~action: (~signal: BrowserBindings.AbortController.signal) => Promise.t<'a>,
  ~debounceMs: int,
  ~rateLimit: (int, int),
) => {
  let (maxCalls, windowMs) = rateLimit

  let rateLimiter = React.useMemo2(() => {
    RateLimiter.make(~maxCalls, ~windowMs)
  }, (maxCalls, windowMs))

  let (isPending, setPending) = React.useState(() => false)
  let (isThrottled, setThrottled) = React.useState(() => false)

  let abortControllerRef = React.useRef(None)
  let actionRef = React.useRef(action)
  React.useEffect1(() => {
    actionRef.current = action
    None
  }, [action])

  let cancel = React.useCallback0(() => {
    switch abortControllerRef.current {
    | Some(ctrl) => BrowserBindings.AbortController.abort(ctrl)
    | None => ()
    }
    setPending(_ => false)
    abortControllerRef.current = None
  })

  let debounced = React.useMemo2(() => {
    Debounce.make(~fn=() => {
      if RateLimiter.canCall(rateLimiter) {
        RateLimiter.recordCall(rateLimiter)

        if !RateLimiter.canCall(rateLimiter) {
          setThrottled(_ => true)
          let _ = Window.setTimeout(() => setThrottled(_ => false), windowMs)
        }

        let ctrl = BrowserBindings.AbortController.newAbortController()
        abortControllerRef.current = Some(ctrl)
        let signal = BrowserBindings.AbortController.signal(ctrl)

        setPending(_ => true)
        actionRef.current(~signal)
        ->Promise.then(res => {
          setPending(_ => false)
          abortControllerRef.current = None
          Promise.resolve(Some(res))
        })
        ->Promise.catch(_ => {
          setPending(_ => false)
          abortControllerRef.current = None
          Promise.resolve(None)
        })
      } else {
        setThrottled(_ => true)
        let _ = Window.setTimeout(() => setThrottled(_ => false), windowMs)

        EventBus.dispatch(ShowNotification("Rate limit exceeded. Please wait.", #Warning, None))
        Promise.resolve(None)
      }
    }, ~wait=debounceMs, ~leading=true, ~trailing=false)
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

  (execute, cancel, isPending, isThrottled)
}
