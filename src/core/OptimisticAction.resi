/* src/core/OptimisticAction.resi */

type optimisticResult<'a> =
  | Committed('a)
  | RolledBack(string)

let execute: (
  ~action: Actions.action,
  ~apiCall: Types.state => Promise.t<result<'a, string>>,
  ~getState: unit => Types.state=?,
  ~getDispatch: unit => Actions.action => unit=?,
  ~onRollback: Types.state => unit=?,
) => Promise.t<optimisticResult<'a>>
