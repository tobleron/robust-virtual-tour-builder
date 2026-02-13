/* src/components/LockFeedback.res */

open NotificationTypes

@react.component
let make = () => {
  let transitionToastId = "scene-transition-toast"
  let (status, setStatus) = React.useState(_ => NavigationSupervisor.Idle)

  let dispatchProcessingToast = () =>
    NotificationManager.dispatch({
      id: transitionToastId,
      importance: NotificationTypes.Info,
      context: NotificationTypes.SystemEvent("scene_transition"),
      message: "Processing scene transition...",
      details: None,
      action: None,
      duration: 0,
      dismissible: false,
      createdAt: Date.now(),
    })

  let dispatchDelayedToast = () =>
    NotificationManager.dispatch({
      id: transitionToastId,
      importance: NotificationTypes.Warning,
      context: NotificationTypes.SystemEvent("scene_transition"),
      message: "Scene transition delayed. Please wait...",
      details: None,
      action: None,
      duration: 0,
      dismissible: false,
      createdAt: Date.now(),
    })

  React.useEffect0(() => {
    let cleanup = NavigationSupervisor.addStatusListener(newStatus => {
      setStatus(_ => newStatus)
    })
    Some(cleanup)
  })

  React.useEffect1(() => {
    NotificationManager.dismiss(transitionToastId)

    switch status {
    | Idle
    | Panning(_, _) =>
      None
    | _ =>
      let shortId = ReBindings.Window.setTimeout(dispatchProcessingToast, 3000)
      let longId = ReBindings.Window.setTimeout(dispatchDelayedToast, 8000)

      Some(
        () => {
          ReBindings.Window.clearTimeout(shortId)
          ReBindings.Window.clearTimeout(longId)
        },
      )
    }
  }, [status])

  React.null
}
