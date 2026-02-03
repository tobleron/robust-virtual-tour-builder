type state =
  | Closed
  | Open
  | HalfOpen

type config = {
  failureThreshold: int,
  successThreshold: int,
  timeout: int,
}

type t = {
  mutable state: state,
  mutable failureCount: int,
  mutable successCount: int,
  mutable lastFailureTime: option<float>,
  mutable probing: bool,
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
    state: Closed,
    failureCount: 0,
    successCount: 0,
    lastFailureTime: None,
    probing: false,
    config,
  }
}

let getState = t => t.state

let stateToString = state =>
  switch state {
  | Closed => "Closed"
  | Open => "Open"
  | HalfOpen => "HalfOpen"
  }

let canExecute = t => {
  switch t.state {
  | Closed => true
  | Open =>
    switch t.lastFailureTime {
    | Some(time) =>
      if Date.now() -. time >= Int.toFloat(t.config.timeout) {
        t.state = HalfOpen
        t.probing = true
        true
      } else {
        false
      }
    | None => true // Should not happen in Open, but safe fallback
    }
  | HalfOpen =>
    if t.probing {
      false
    } else {
      t.probing = true
      true
    }
  }
}

let recordSuccess = t => {
  switch t.state {
  | HalfOpen =>
    t.probing = false
    t.successCount = t.successCount + 1
    if t.successCount >= t.config.successThreshold {
      t.state = Closed
      t.failureCount = 0
      t.successCount = 0
      t.lastFailureTime = None
    }
  | Closed => t.failureCount = 0
  | Open => () // Should not happen usually, but ignore
  }
}

let recordFailure = t => {
  switch t.state {
  | HalfOpen =>
    t.state = Open
    t.lastFailureTime = Some(Date.now())
    t.successCount = 0
    t.probing = false
  | Closed =>
    t.failureCount = t.failureCount + 1
    if t.failureCount >= t.config.failureThreshold {
      t.state = Open
      t.lastFailureTime = Some(Date.now())
    }
  | Open =>
    // Reset timer on subsequent failures
    t.lastFailureTime = Some(Date.now())
  }
}
