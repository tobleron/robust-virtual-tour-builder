// src/components/NotificationCenter.res
// Custom ReScript notification system scoped strictly to the viewer
// Standardized padding: top-6 (24px), right-6 (24px)
// Standardized sizes: width 300px, height 48px

// open NotificationTypes (Removed to avoid shadowing Error global)

module Toast = {
  let getContextClass = (context: NotificationTypes.context): string => {
    switch context {
    | NotificationTypes.Operation(op) if String.startsWith(op, "eta_") => " eta"
    | _ => ""
    }
  }

  @react.component
  let make = (~notification: NotificationTypes.notification, ~isFadingOut: bool) => {
    let icon = switch notification.importance {
    | NotificationTypes.Success => <LucideIcons.CircleCheck size=20 strokeWidth=2.5 />
    | NotificationTypes.Error | NotificationTypes.Critical =>
      <LucideIcons.CircleAlert size=20 strokeWidth=2.5 />
    | NotificationTypes.Warning => <LucideIcons.TriangleAlert size=20 strokeWidth=2.5 />
    | NotificationTypes.Info | NotificationTypes.Transient =>
      <LucideIcons.Info size=20 strokeWidth=2.5 />
    }

    let importanceKey = NotificationTypes.importanceToString(notification.importance)
    let contextClass = getContextClass(notification.context)
    let isAssertive = switch notification.importance {
    | NotificationTypes.Error
    | NotificationTypes.Critical
    | NotificationTypes.Warning => true
    | NotificationTypes.Success
    | NotificationTypes.Info
    | NotificationTypes.Transient => false
    }

    <div
      className={"viewer-toast " ++
      importanceKey ++
      if isFadingOut {
        " dismissing"
      } else {
        ""
      } ++
      contextClass}
      role={if isAssertive {
        "alert"
      } else {
        "status"
      }}
      ariaLive={if isAssertive {
        #assertive
      } else {
        #polite
      }}
      ariaAtomic=true
    >
      <div className="viewer-toast-icon"> icon </div>

      <div className="viewer-toast-copy">
        <div className="viewer-toast-content"> {React.string(notification.message)} </div>
        {switch notification.details {
        | Some(details) => <div className="viewer-toast-details"> {React.string(details)} </div>
        | None => React.null
        }}
      </div>

      /* Optional Action Button */
      {switch notification.action {
      | Some(action) =>
        <Shadcn.Button
          variant="secondary"
          className="h-7 px-3 text-[10px] ml-auto bg-white/10 hover:bg-white/20 border-none text-white whitespace-nowrap"
          onClick={_ => action.onClick()}
        >
          {React.string(
            action.label ++
            switch action.shortcut {
            | Some(s) => " (" ++ String.toUpperCase(s) ++ ")"
            | None => ""
            },
          )}
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

  /* Keep a live region mounted even when no toast is currently visible. */
  <div id="viewer-notifications-container" ariaLive=#polite ariaAtomic=true>
    {state.active
    ->Belt.Array.map(notif => {
      <Toast key=notif.id notification=notif isFadingOut={isFadingOut(notif.id)} />
    })
    ->React.array}
  </div>
})
