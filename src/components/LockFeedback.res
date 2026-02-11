/* src/components/LockFeedback.res */

@react.component
let make = () => {
  let (status, setStatus) = React.useState(_ => NavigationSupervisor.Idle)
  let (showWarning, setShowWarning) = React.useState(_ => false)
  let (showLongWarning, setShowLongWarning) = React.useState(_ => false)

  React.useEffect0(() => {
    let cleanup = NavigationSupervisor.addStatusListener(newStatus => {
      setStatus(_ => newStatus)
    })
    Some(cleanup)
  })

  React.useEffect1(() => {
    switch status {
    | Idle =>
      setShowWarning(_ => false)
      setShowLongWarning(_ => false)
      None
    | _ =>
      let t1 = setTimeout(() => setShowWarning(_ => true), 3000)
      let t2 = setTimeout(() => setShowLongWarning(_ => true), 8000)

      Some(
        () => {
          clearTimeout(t1)
          clearTimeout(t2)
        },
      )
    }
  }, [status])

  if !showWarning {
    React.null
  } else {
    let (message, color) = if showLongWarning {
      ("Scene transition delayed. Please wait...", "bg-red-500/90 text-white")
    } else {
      ("Processing scene transition...", "bg-blue-500/90 text-white")
    }

    <div
      className={`absolute top-4 right-4 z-[9999] px-4 py-2 rounded-lg shadow-lg font-medium text-sm pointer-events-none transition-all duration-300 ${color}`}
    >
      {React.string(message)}
    </div>
  }
}
