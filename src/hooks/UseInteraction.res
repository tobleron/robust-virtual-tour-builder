/* @efficiency-role: state-hook */
open InteractionPolicies

let useInteraction = (~id: string, ~policy: policy, ~action: unit => Promise.t<'a>) => {
  let (isPending, setPending) = React.useState(() => false)
  let (wasThrottled, setThrottled) = React.useState(() => false)
  let isMounted = React.useRef(true)

  React.useEffect0(() => {
    isMounted.current = true
    Some(
      () => {
        isMounted.current = false
      },
    )
  })

  let execute = React.useCallback1(() => {
    let wrappedAction = () => {
      if isMounted.current {
        setPending(_ => true)
      }
      action()->Promise.finally(() => {
        if isMounted.current {
          setPending(_ => false)
        }
      })
    }

    switch InteractionGuard.attempt(id, policy, wrappedAction) {
    | Ok(p) =>
      if isMounted.current {
        setThrottled(_ => false)
      }
      p->Promise.then(val => Promise.resolve(Some(val)))
    | Error(msg) =>
      if isMounted.current {
        setThrottled(_ => true)
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: SystemEvent("interaction"),
          message: switch msg {
          | "Rate limited" => "Rate limit exceeded."
          | "Locked" => "Action already in progress."
          | _ => "Navigation busy."
          },
          details: None,
          action: None,
          duration: 2000,
          dismissible: true,
          createdAt: Date.now(),
        })
        let _ = ReBindings.Window.setTimeout(() => {
          if isMounted.current {
            setThrottled(_ => false)
          }
        }, 1000)
      }
      Promise.resolve(None)
    }
  }, [action])

  (execute, isPending, wasThrottled)
}
