type state =
  | Closed
  | Open
  | HalfOpen

type config = {
  failureThreshold: int,
  successThreshold: int,
  timeout: int,
  onStateTransition: option<(state, state) => unit>,
  onCircuitOpen: option<unit => unit>,
}

type t

let make: (~config: config=?) => t
let canExecute: t => bool
let recordSuccess: t => unit
let recordFailure: t => unit
let getState: t => state
let stateToString: state => string
