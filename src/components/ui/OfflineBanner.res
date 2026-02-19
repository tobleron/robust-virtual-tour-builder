/* src/components/ui/OfflineBanner.res */

@react.component
let make = () => {
  let (isOnline, setIsOnline) = React.useState(_ => NetworkStatus.isOnline())
  let (rateLimitUntil, setRateLimitUntil) = React.useState(_ => 0.0)
  let (now, setNow) = React.useState(_ => Date.now())

  React.useEffect0(() => {
    let unsubscribe = NetworkStatus.subscribe(status => {
      setIsOnline(_ => status)
    })

    let unsubscribeRateLimit = EventBus.subscribe(event => {
      switch event {
      | RateLimitBackoff(seconds) => setRateLimitUntil(_ => Date.now() +. Float.fromInt(seconds) *. 1000.0)
      | _ => ()
      }
    })

    let timer = ReBindings.Window.setInterval(() => {
        setNow(_ => Date.now())
    }, 1000)

    Some(() => {
      unsubscribe()
      unsubscribeRateLimit()
      ReBindings.Window.clearInterval(timer)
    })
  })

  let secondsLeft = if rateLimitUntil > now {
    Math.ceil((rateLimitUntil -. now) /. 1000.0)->Float.toInt
  } else {
    0
  }
  let isRateLimited = secondsLeft > 0

  if !isOnline {
    <div
      className="absolute top-0 left-0 w-full bg-amber-600/95 text-white text-center py-2 px-4 text-sm font-medium backdrop-blur-sm z-[100] shadow-md transition-all duration-300 ease-in-out border-b border-amber-700/20"
      role="alert"
    >
      <div className="flex items-center justify-center gap-4">
        <div className="flex items-center gap-2">
          <LucideIcons.WifiOff size=16 />
          {React.string("You appear to be offline. Some features may be unavailable.")}
        </div>
        <button
          onClick={_ => {
            let _ = NetworkStatus.probe()
          }}
          className="bg-white/20 hover:bg-white/30 px-3 py-1 rounded text-xs transition-colors border border-white/30"
        >
          {React.string("Retry Connection")}
        </button>
      </div>
    </div>
  } else if isRateLimited {
    <div
      className="absolute top-0 left-0 w-full bg-amber-600/95 text-white text-center py-2 px-4 text-sm font-medium backdrop-blur-sm z-[100] shadow-md transition-all duration-300 ease-in-out border-b border-amber-700/20"
      role="alert"
    >
      <div className="flex items-center justify-center gap-4">
        <div className="flex items-center gap-2">
          <LucideIcons.Hourglass size=16 />
          {React.string("High traffic volume. Pausing background requests for " ++ Belt.Int.toString(secondsLeft) ++ "s...")}
        </div>
      </div>
    </div>
  } else {
    React.null
  }
}
