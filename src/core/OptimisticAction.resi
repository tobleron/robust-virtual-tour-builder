/* src/core/OptimisticAction.resi */

type optimisticResult<'a> =
  | Committed('a)
  | RolledBack(string)

let execute: (
  ~action: Actions.action,
  ~apiCall: unit => Promise.t<result<'a, string>>,
  ~onRollback: Types.state => unit=?,
) => Promise.t<optimisticResult<'a>>
