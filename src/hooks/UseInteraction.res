open InteractionPolicies

let useInteraction = (
  ~id: string,
  ~policy: policy,
  ~action: unit => Promise.t<'a>,
) => {
  let (isPending, setPending) = React.useState(() => false)
  let (wasThrottled, setThrottled) = React.useState(() => false)
  let isMounted = React.useRef(true)

  React.useEffect0(() => {
    isMounted.current = true
    Some(() => {
      isMounted.current = false
    })
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
      p
    | Error(_) =>
      if isMounted.current {
        setThrottled(_ => true)
        let _ = ReBindings.Window.setTimeout(() => {
          if isMounted.current {
            setThrottled(_ => false)
          }
        }, 1000)
      }
      // Return a dummy promise that resolves to null/undefined
      // We use Obj.magic because we can't construct a Promise.t<'a> from nothing
      Promise.resolve(Obj.magic(null))
    }
  }, [action])

  (execute, isPending, wasThrottled)
}
