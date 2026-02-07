// src/components/NotificationCenter.res
// React component that subscribes to NotificationManager and renders notifications as Sonner toasts

@react.component
let make = React.memo(() => {
  // Track queue state in component
  let (state, setState) = React.useState(_ => {
    NotificationManager.getState()
  })

  // Track which notifications have been rendered as toasts to avoid duplicates
  let renderedIdsRef = React.useRef(Set.make())

  // Subscribe to manager on mount, unsubscribe on unmount
  React.useEffect0(() => {
    Logger.info(~module_="NotificationCenter", ~message="MOUNTED_AND_SUBSCRIBING", ())
    let unsubscribe = NotificationManager.subscribe(
      newState => {
        setState(_ => newState)
      },
    )

    // Cleanup: unsubscribe on unmount
    Some(
      () => {
        Logger.info(~module_="NotificationCenter", ~message="UNMOUNTING", ())
        unsubscribe()
      },
    )
  })

  // Render active notifications as Sonner toasts
  React.useEffect1(() => {
    state.active->Belt.Array.forEach(
      notification => {
        let renderedIds = renderedIdsRef.current

        if !Set.has(renderedIds, notification.id) {
          // Mark as rendered to avoid duplicate toasts
          Set.add(renderedIds, notification.id)->ignore

          let message = notification.message

          let options: Shadcn.Sonner.toastOptions = {
            duration: notification.duration,
            description: notification.details,
          }

          // Dispatch appropriate toast based on importance
          switch notification.importance {
          | NotificationTypes.Success => Shadcn.Sonner.success(message, options)
          | NotificationTypes.Error => Shadcn.Sonner.error(message, options)
          | NotificationTypes.Warning => Shadcn.Sonner.warning(message, options)
          | NotificationTypes.Info => Shadcn.Sonner.info(message, options)
          | NotificationTypes.Critical => Shadcn.Sonner.error(message, options)
          | NotificationTypes.Transient => Shadcn.Sonner.toast(message, options)
          }

          Logger.info(
            ~module_="NotificationCenter",
            ~message="RENDERED_TOAST",
            ~data=Some({
              "id": notification.id,
              "importance": switch notification.importance {
              | NotificationTypes.Info => "info"
              | NotificationTypes.Success => "success"
              | NotificationTypes.Warning => "warning"
              | NotificationTypes.Error => "error"
              | NotificationTypes.Critical => "critical"
              | NotificationTypes.Transient => "transient"
              },
              "message": message,
            }),
            (),
          )
        }
      },
    )
    None
  }, [state.active])

  React.null
})
