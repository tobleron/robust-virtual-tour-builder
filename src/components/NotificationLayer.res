/* src/components/NotificationLayer.res */
open EventBus

@react.component
let make = React.memo(() => {
  let (_procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "",
      "phase": "",
      "error": false,
      "onCancel": () => (),
    }
  )
  let hideTimerRef = React.useRef(Nullable.null)

  // Subscribe to processing updates
  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(
      event => {
        switch event {
        | UpdateProcessing(payload) =>
          // Clear any existing hide timer
          switch Nullable.toOption(hideTimerRef.current) {
          | Some(timerId) =>
            clearTimeout(timerId)
            hideTimerRef.current = Nullable.null
          | None => ()
          }

          setProcState(_ => payload)

          // If progress is complete, start auto-hide timer
          if payload["progress"] >= 100.0 && payload["active"] {
            let timerId = setTimeout(
              () => {
                setProcState(
                  prev => {
                    let next = Object.assign(Object.make(), prev)
                    next["active"] = false
                    next
                  },
                )
                hideTimerRef.current = Nullable.null
              },
              3000,
            ) // 3 seconds delay for floating UI
            hideTimerRef.current = Nullable.fromOption(Some(timerId))
          }
        | _ => ()
        }
      },
    )

    Some(
      () => {
        unsubscribe()
      },
    )
  })

  <Shadcn.Sonner
    position="top-right"
    visibleToasts=Constants.toastVisibleToasts
    duration=Constants.toastDisplayDuration
    expand=true
  />
})
