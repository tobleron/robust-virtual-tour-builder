// src/components/NotificationCenter.res
// React component that subscribes to NotificationManager and renders notifications
// Phase 1: Debug widget showing active notification count
// Phase 2 (future): Full toast/modal rendering with animations

open NotificationTypes

@react.component
let make = React.memo(() => {
  // Track queue state in component
  let (state, setState) = React.useState(_ => {
    NotificationManager.getState()
  })

  // Subscribe to manager on mount, unsubscribe on unmount
  React.useEffect0(() => {
    let unsubscribe = NotificationManager.subscribe(
      newState => {
        setState(_ => newState)
      },
    )

    // Cleanup: unsubscribe on unmount
    Some(unsubscribe)
  })

  // Active notification count
  let activeCount = Belt.Array.length(state.active)

  // Phase 1: Debug widget showing active count
  <div className="fixed inset-0 pointer-events-none z-40">
    <div
      className="fixed bottom-4 right-4 pointer-events-auto bg-blue-500 text-white px-4 py-2 rounded text-sm font-medium"
    >
      {React.string("Active: " ++ Int.toString(activeCount))}
    </div>
  </div>
})
