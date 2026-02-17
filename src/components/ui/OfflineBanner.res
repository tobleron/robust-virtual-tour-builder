/* src/components/ui/OfflineBanner.res */

@react.component
let make = () => {
  let (isOnline, setIsOnline) = React.useState(_ => NetworkStatus.isOnline())

  React.useEffect0(() => {
    let unsubscribe = NetworkStatus.subscribe(status => {
      setIsOnline(_ => status)
    })
    Some(unsubscribe)
  })

  if isOnline {
    React.null
  } else {
    <div
      className="absolute top-0 left-0 w-full bg-amber-600/95 text-white text-center py-2 px-4 text-sm font-medium backdrop-blur-sm z-[100] shadow-md transition-all duration-300 ease-in-out border-b border-amber-700/20"
      role="alert"
    >
      <div className="flex items-center justify-center gap-2">
        <LucideIcons.WifiOff size=16 />
        {React.string("You appear to be offline. Some features may be unavailable.")}
      </div>
    </div>
  }
}
