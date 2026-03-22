/* @efficiency-role: infra-adapter */

type state =
  | Closed
  | Open
  | HalfOpen

type internalState =
  | ClosedState({failureCount: int})
  | OpenState({startTime: float})
  | HalfOpenState({successCount: int, failureCount: int, probing: bool})

type config = {
  failureThreshold: int,
  successThreshold: int,
  timeout: int,
  onStateTransition: option<(state, state) => unit>,
  onCircuitOpen: option<unit => unit>,
}

type t = {
  // JUSTIFIED: imperative singleton
  mutable internalState: internalState,
  config: config,
}

let make = (
  ~config={
    failureThreshold: 5,
    successThreshold: 2,
    timeout: 30000,
    onStateTransition: None,
    onCircuitOpen: None,
  },
) => {
  {
    internalState: ClosedState({failureCount: 0}),
    config,
  }
}

let internalStateToPublicState = s =>
  switch s {
  | ClosedState(_) => Closed
  | OpenState(_) => Open
  | HalfOpenState(_) => HalfOpen
  }

let getState = t => {
  internalStateToPublicState(t.internalState)
}

let stateToString = state =>
  switch state {
  | Closed => "Closed"
  | Open => "Open"
  | HalfOpen => "HalfOpen"
  }

let canExecute = t => {
  switch t.internalState {
  | ClosedState(_) => true
  | OpenState({startTime}) =>
    if Date.now() -. startTime >= Int.toFloat(t.config.timeout) {
      let previous = getState(t)
      t.internalState = HalfOpenState({successCount: 0, failureCount: 0, probing: true})
      t.config.onStateTransition->Option.forEach(cb => cb(previous, HalfOpen))
      true
    } else {
      false
    }
  | HalfOpenState({probing, successCount, failureCount}) =>
    if probing {
      false
    } else {
      t.internalState = HalfOpenState({successCount, failureCount, probing: true})
      true
    }
  }
}

let recordSuccess = t => {
  switch t.internalState {
  | HalfOpenState({successCount, failureCount}) =>
    let newSuccessCount = successCount + 1
    if newSuccessCount >= t.config.successThreshold {
      let previous = getState(t)
      t.internalState = ClosedState({failureCount: 0})
      t.config.onStateTransition->Option.forEach(cb => cb(previous, Closed))
    } else {
      t.internalState = HalfOpenState({
        successCount: newSuccessCount,
        failureCount,
        probing: false,
      })
    }
  | ClosedState(_) => t.internalState = ClosedState({failureCount: 0})
  | OpenState(_) => () // Should not happen usually, but ignore
  }
}

let recordFailure = t => {
  let now = Date.now()
  switch t.internalState {
  | HalfOpenState({failureCount}) =>
    let newFailureCount = failureCount + 1
    if newFailureCount >= 2 {
      let previous = getState(t)
      t.internalState = OpenState({startTime: now})
      t.config.onStateTransition->Option.forEach(cb => cb(previous, Open))
      t.config.onCircuitOpen->Option.forEach(cb => cb())
    } else {
      t.internalState = HalfOpenState({
        successCount: 0,
        failureCount: newFailureCount,
        probing: false,
      })
    }
  | ClosedState({failureCount}) =>
    let newFailureCount = failureCount + 1
    if newFailureCount >= t.config.failureThreshold {
      let previous = getState(t)
      t.internalState = OpenState({startTime: now})
      t.config.onStateTransition->Option.forEach(cb => cb(previous, Open))
      t.config.onCircuitOpen->Option.forEach(cb => cb())
    } else {
      t.internalState = ClosedState({failureCount: newFailureCount})
    }
  | OpenState(_) =>
    // Reset timer on subsequent failures
    t.internalState = OpenState({startTime: now})
  }
}
