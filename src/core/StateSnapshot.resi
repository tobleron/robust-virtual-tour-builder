/* src/core/StateSnapshot.resi */

type snapshot = {
  id: string,
  timestamp: float,
  state: Types.state,
  action: Actions.action,
}

let snapshotEncoder: snapshot => JSON.t
let capture: (Types.state, Actions.action) => string
let rollback: string => option<Types.state>
let commit: string => unit
let getLatest: unit => option<snapshot>
let clear: unit => unit
