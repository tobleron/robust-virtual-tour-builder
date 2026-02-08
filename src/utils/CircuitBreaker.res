/* @efficiency-role: infra-adapter */

type state =
  | Closed
  | Open
  | HalfOpen

type internalState =
  | ClosedState({failureCount: int})
  | OpenState({startTime: float})
  | HalfOpenState({successCount: int, probing: bool})

type config = {
  failureThreshold: int,
  successThreshold: int,
  timeout: int,
}

type t = {
  mutable internalState: internalState,
  config: config,
}

let make = (
  ~config={
    failureThreshold: 5,
    successThreshold: 2,
    timeout: 30000,
  },
) => {
  {
    internalState: ClosedState({failureCount: 0}),
    config: config,
  }
}

let getState = t => {
  switch t.internalState {
  | ClosedState(_) => Closed
  | OpenState(_) => Open
  | HalfOpenState(_) => HalfOpen
  }
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
      t.internalState = HalfOpenState({successCount: 0, probing: true})
      true
    } else {
      false
    }
  | HalfOpenState({probing, successCount}) =>
    if probing {
      false
    } else {
      t.internalState = HalfOpenState({successCount: successCount, probing: true})
      true
    }
  }
}

let recordSuccess = t => {
  switch t.internalState {
  | HalfOpenState({successCount}) =>
    let newSuccessCount = successCount + 1
    if newSuccessCount >= t.config.successThreshold {
      t.internalState = ClosedState({failureCount: 0})
    } else {
      t.internalState = HalfOpenState({successCount: newSuccessCount, probing: false})
    }
  | ClosedState(_) => t.internalState = ClosedState({failureCount: 0})
  | OpenState(_) => () // Should not happen usually, but ignore
  }
}

let recordFailure = t => {
  let now = Date.now()
  switch t.internalState {
  | HalfOpenState(_) =>
    t.internalState = OpenState({startTime: now})
  | ClosedState({failureCount}) =>
    let newFailureCount = failureCount + 1
    if newFailureCount >= t.config.failureThreshold {
      t.internalState = OpenState({startTime: now})
    } else {
      t.internalState = ClosedState({failureCount: newFailureCount})
    }
  | OpenState(_) =>
    // Reset timer on subsequent failures
    t.internalState = OpenState({startTime: now})
  }
}
