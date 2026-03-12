/* src/components/ui/OfflineBanner.res */

open ReBindings

let connectivityToastId = "connectivity-status-toast"
let connectivityRecoveredToastId = "connectivity-status-recovered"

let secondsUntilRetry = (snapshot: NetworkStatus.statusSnapshot, now: float): option<int> =>
  snapshot.nextRetryAtMs->Option.map(nextRetryAtMs => {
    let remainingMs = nextRetryAtMs -. now
    if remainingMs <= 0.0 {
      0
    } else {
      Math.ceil(remainingMs /. 1000.0)->Float.toInt
    }
  })

let toastMessageForSnapshot = (snapshot: NetworkStatus.statusSnapshot): string =>
  switch snapshot.phase {
  | NetworkStatus.HealthyPhase => "Connected."
  | NetworkStatus.BrowserOfflinePhase => "Connection lost. Local editing remains available."
  | NetworkStatus.RecoveringPhase => "Connection lost. Retrying automatically."
  | NetworkStatus.RateLimitedPhase => "Server busy. Pausing backend requests."
  }

let reasonDetails = (reason: NetworkStatus.statusReason): string =>
  switch reason {
  | NetworkStatus.Healthy => "Connected."
  | NetworkStatus.BrowserOffline => "Browser reports no network connection."
  | NetworkStatus.ProbeNetworkFailure => "Cannot reach the backend health endpoint."
  | NetworkStatus.BackendRateLimited(Some(seconds)) =>
    "Server asked us to back off for " ++ Belt.Int.toString(seconds) ++ "s."
  | NetworkStatus.BackendRateLimited(None) => "Server asked us to back off."
  | NetworkStatus.BackendUnavailable(status, statusText) =>
    "Backend responded with " ++ Belt.Int.toString(status) ++ " " ++ statusText ++ "."
  | NetworkStatus.TransportFailure(message) => "Transport failure: " ++ message
  }

let toastDetailsForSnapshot = (
  snapshot: NetworkStatus.statusSnapshot,
  ~now: float,
): string => {
  let retryText = switch secondsUntilRetry(snapshot, now) {
  | Some(seconds) =>
    if seconds <= 0 {
      "Retrying now."
    } else {
      "Retrying in " ++ Belt.Int.toString(seconds) ++ "s."
    }
  | None => "Retrying when the backend is reachable."
  }

  let reasonText = switch snapshot.reason {
  | NetworkStatus.BackendRateLimited(Some(seconds)) =>
    "Server asked us to back off for " ++ Belt.Int.toString(seconds) ++ "s."
  | _ => reasonDetails(snapshot.reason)
  }

  let attemptText =
    if snapshot.attempt > 0 && snapshot.phase !== NetworkStatus.RateLimitedPhase {
      " Attempt " ++ Belt.Int.toString(snapshot.attempt) ++ "."
    } else {
      ""
    }

  reasonText ++ " " ++ retryText ++ attemptText
}

let toastImportanceForSnapshot = (snapshot: NetworkStatus.statusSnapshot): NotificationTypes.importance =>
  switch snapshot.phase {
  | NetworkStatus.RateLimitedPhase => NotificationTypes.Info
  | NetworkStatus.BrowserOfflinePhase
  | NetworkStatus.RecoveringPhase => NotificationTypes.Warning
  | NetworkStatus.HealthyPhase => NotificationTypes.Success
  }

let shouldShowOverlay = (snapshot: NetworkStatus.statusSnapshot): bool =>
  switch snapshot.phase {
  | NetworkStatus.BrowserOfflinePhase
  | NetworkStatus.RecoveringPhase => true
  | NetworkStatus.HealthyPhase
  | NetworkStatus.RateLimitedPhase => false
  }

@react.component
let make = () => {
  let (snapshot, setSnapshot) = React.useState(_ => NetworkStatus.getSnapshot())
  let (now, setNow) = React.useState(_ => Date.now())
  let previousPhaseRef = React.useRef(snapshot.phase)

  React.useEffect0(() => {
    let unsubscribe = NetworkStatus.subscribeSnapshot(nextSnapshot => {
      setSnapshot(_ => nextSnapshot)
    })

    Some(() => unsubscribe())
  })

  React.useEffect1(() => {
    if snapshot.phase === NetworkStatus.HealthyPhase {
      None
    } else {
      let timer = ReBindings.Window.setInterval(() => {
        setNow(_ => Date.now())
      }, 1000)
      Some(() => ReBindings.Window.clearInterval(timer))
    }
  }, [snapshot.phase])

  React.useEffect1(() => {
    let bodyClasses = Dom.classList(Dom.documentBody)
    if shouldShowOverlay(snapshot) {
      bodyClasses->Dom.ClassList.add("network-degraded")
    } else {
      bodyClasses->Dom.ClassList.remove("network-degraded")
    }

    Some(() => bodyClasses->Dom.ClassList.remove("network-degraded"))
  }, [snapshot.phase])

  React.useEffect2(() => {
    let previousPhase = previousPhaseRef.current
    let becameDegraded =
      previousPhase === NetworkStatus.HealthyPhase && snapshot.phase !== NetworkStatus.HealthyPhase

    if becameDegraded {
      PersistenceLayer.flushNow(
        ~state=AppStateBridge.getState(),
        ~reason="network-degraded-transition",
      )
    }

    if snapshot.phase === NetworkStatus.HealthyPhase {
      NotificationManager.dismiss(connectivityToastId)
      if previousPhase !== NetworkStatus.HealthyPhase {
        NotificationManager.dispatch({
          id: connectivityRecoveredToastId,
          importance: NotificationTypes.Success,
          context: NotificationTypes.SystemEvent("connectivity"),
          message: "Connection restored.",
          details: Some("Backend access recovered. You can resume server-backed actions."),
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(NotificationTypes.Success),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
    } else {
      NotificationManager.dismiss(connectivityRecoveredToastId)
      NotificationManager.dispatch({
        id: connectivityToastId,
        importance: toastImportanceForSnapshot(snapshot),
        context: NotificationTypes.SystemEvent("connectivity"),
        message: toastMessageForSnapshot(snapshot),
        details: Some(toastDetailsForSnapshot(snapshot, ~now)),
        action: Some({
          label: "Retry now",
          onClick: () => {
            let _ = NetworkStatus.probeNow()
          },
          shortcut: None,
        }),
        duration: 0,
        dismissible: true,
        createdAt: Date.now(),
      })
    }

    previousPhaseRef.current = snapshot.phase
    None
  }, (snapshot, now))

  if shouldShowOverlay(snapshot) {
    <div className="network-degraded-overlay" ariaHidden=true />
  } else {
    React.null
  }
}
