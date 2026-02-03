/* src/core/OptimisticAction.res */

type optimisticResult<'a> =
  | Committed('a)
  | RolledBack(string)

let execute = (
  ~action: Actions.action,
  ~apiCall: unit => Promise.t<result<'a, string>>,
  ~onRollback: Types.state => unit=state => GlobalStateBridge.setState(state),
): Promise.t<optimisticResult<'a>> => {
  // 1. Capture state
  let currentState = GlobalStateBridge.getState()
  let snapshotId = StateSnapshot.capture(currentState, action)

  // 2. Optimistic dispatch
  GlobalStateBridge.dispatch(action)

  // 3. API Call
  apiCall()
  ->Promise.then(result => {
    switch result {
    | Ok(data) =>
      // 4. Success -> Commit
      StateSnapshot.commit(snapshotId)
      Promise.resolve(Committed(data))

    | Error(msg) =>
      // 5. Failure -> Rollback
      switch StateSnapshot.rollback(snapshotId) {
      | Some(restoredState) =>
        onRollback(restoredState)

        // Notify user
        EventBus.dispatch(ShowNotification(
          "Action failed. Changes have been reverted.",
          #Warning,
          Some(Logger.castToJson({"action": Actions.actionToString(action), "error": msg}))
        ))

        Promise.resolve(RolledBack(msg))
      | None =>
        Logger.error(
          ~module_="OptimisticAction",
          ~message="ROLLBACK_FAILED_NO_SNAPSHOT",
          ~data=Some(Logger.castToJson({"id": snapshotId})),
          ()
        )
        Promise.resolve(RolledBack(msg ++ " (Rollback failed)"))
      }
    }
  })
  ->Promise.catch(ex => {
    let (msg, _) = Logger.getErrorDetails(ex)

     switch StateSnapshot.rollback(snapshotId) {
      | Some(restoredState) =>
        onRollback(restoredState)
        EventBus.dispatch(ShowNotification(
          "Action failed. Changes have been reverted.",
          #Warning,
          Some(Logger.castToJson({"action": Actions.actionToString(action), "error": msg}))
        ))
        Promise.resolve(RolledBack(msg))
      | None =>
         Promise.resolve(RolledBack(msg ++ " (Rollback failed)"))
     }
  })
}
