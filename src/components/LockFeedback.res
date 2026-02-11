/* src/components/LockFeedback.res */

@react.component
let make = () => {
  let (phase, setPhase) = React.useState(_ => TransitionLock.Idle)
  let (showWarning, setShowWarning) = React.useState(_ => false)
  let (showLongWarning, setShowLongWarning) = React.useState(_ => false)
  let (remainingSeconds, setRemainingSeconds) = React.useState(_ => 15)
  let (showRecovery, setShowRecovery) = React.useState(_ => false)

  React.useEffect0(() => {
    let cleanup = TransitionLock.addChangeListener(newPhase => {
      setPhase(_ => newPhase)
    })
    Some(cleanup)
  })

  React.useEffect0(() => {
    let cleanup = TransitionLock.addRecoveryListener(() => {
      setShowRecovery(_ => true)
      let timeoutId = setTimeout(() => setShowRecovery(_ => false), 3000)
      ignore(Some(() => clearTimeout(timeoutId)))
    })
    Some(cleanup)
  })

  React.useEffect1(() => {
    switch phase {
    | Idle =>
      setShowWarning(_ => false)
      setShowLongWarning(_ => false)
      None
    | _ =>
      let t1 = setTimeout(() => setShowWarning(_ => true), 3000)
      let t2 = setTimeout(() => setShowLongWarning(_ => true), 8000)
      let countdownIntervalId = setInterval(() => {
        let remaining = TransitionLock.getRemainingMs() / 1000
        setRemainingSeconds(_ => remaining)
      }, 500)

      Some(
        () => {
          clearTimeout(t1)
          clearTimeout(t2)
          clearInterval(countdownIntervalId)
        },
      )
    }
  }, [phase])

  if showRecovery {
    <div
      className="absolute top-4 right-4 z-[9999] px-4 py-2 rounded-lg shadow-lg font-medium text-sm pointer-events-none transition-all duration-300 bg-green-500/90 text-white"
    >
      {React.string("Scene transition recovered")}
    </div>
  } else if !showWarning {
    React.null
  } else {
    let (message, color) = if showLongWarning {
      let countdownMsg =
        "Transition delayed (" ++
        Int.toString(remainingSeconds) ++ "s remaining). System will auto-recover..."
      (countdownMsg, "bg-red-500/90 text-white")
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
