// src/components/NotificationCenter.res
// Custom ReScript notification system scoped strictly to the viewer
// Standardized padding: top-6 (24px), right-6 (24px)
// Standardized sizes: width 300px, height 48px

// open NotificationTypes (Removed to avoid shadowing Error global)

module Toast = {
  @react.component
  let make = (~notification: NotificationTypes.notification, ~isFadingOut: bool) => {
    let (isDismissing, setIsDismissing) = React.useState(_ => false)

    let handleDismiss = _ => {
      setIsDismissing(_ => true)
      // Small delay for animation before logic removal
      let _ = ReBindings.Window.setTimeout(() => {
        NotificationManager.dismiss(notification.id)
      }, 300)
    }

    let icon = switch notification.importance {
    | NotificationTypes.Success => <LucideIcons.CircleCheck size=20 strokeWidth=2.5 />
    | NotificationTypes.Error | NotificationTypes.Critical =>
      <LucideIcons.CircleAlert size=20 strokeWidth=2.5 />
    | NotificationTypes.Warning => <LucideIcons.TriangleAlert size=20 strokeWidth=2.5 />
    | NotificationTypes.Info | NotificationTypes.Transient =>
      <LucideIcons.Info size=20 strokeWidth=2.5 />
    }

    let importanceKey = NotificationTypes.importanceToString(notification.importance)

    <div
      className={"viewer-toast " ++
      importanceKey ++ if isFadingOut || isDismissing {
        " dismissing"
      } else {
        ""
      }}
    >
      /* Close Button - Orange Bubble Badge */
      {if notification.dismissible {
        <button
          className="viewer-toast-close" onClick=handleDismiss ariaLabel="Dismiss notification"
        >
          <LucideIcons.X size=10 strokeWidth=3.0 />
        </button>
      } else {
        React.null
      }}

      <div className="viewer-toast-icon"> icon </div>

      <div className="viewer-toast-content"> {React.string(notification.message)} </div>

      /* Optional Action Button */
      {switch notification.action {
      | Some(action) =>
        <Shadcn.Button
          variant="secondary"
          className="h-7 px-3 text-[10px] ml-auto bg-white/10 hover:bg-white/20 border-none text-white"
          onClick={_ => action.onClick()}
        >
          {React.string(action.label)}
        </Shadcn.Button>
      | None => React.null
      }}
    </div>
  }
}

@react.component
let make = React.memo(() => {
  let (state, setState) = React.useState(_ => {
    NotificationManager.getState()
  })

  // Subscribe to manager
  React.useEffect0(() => {
    let unsubscribe = NotificationManager.subscribe(
      newState => {
        setState(_ => newState)
      },
    )
    Some(() => unsubscribe())
  })

  let isFadingOut = id => Belt.Array.some(state.fadingOut, fadingId => fadingId === id)

  if Array.length(state.active) == 0 {
    React.null
  } else {
    /* Scoped to the viewer container */
    <div id="viewer-notifications-container">
      {state.active
      ->Belt.Array.map(notif => {
        <Toast key=notif.id notification=notif isFadingOut={isFadingOut(notif.id)} />
      })
      ->React.array}
    </div>
  }
})
