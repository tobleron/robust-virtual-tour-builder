/* src/core/OptimisticAction.res */

type optimisticResult<'a> =
  | Committed('a)
  | RolledBack(string)

let execute = (
  ~action: Actions.action,
  ~apiCall: unit => Promise.t<result<'a, string>>,
  ~getState: unit => Types.state=AppContext.getBridgeState,
  ~getDispatch: unit => Actions.action => unit=AppContext.getBridgeDispatch,
  ~onRollback: Types.state => unit=AppContext.restoreState,
): Promise.t<optimisticResult<'a>> => {
  // 1. Capture state
  let currentState = getState()
  let snapshotId = StateSnapshot.capture(currentState, action)

  // 2. Optimistic dispatch
  let dispatch = getDispatch()
  dispatch(action)

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
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: SystemEvent("optimistic_action"),
          message: "Action failed. Changes have been reverted.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })

        Promise.resolve(RolledBack(msg))
      | None =>
        Logger.error(
          ~module_="OptimisticAction",
          ~message="ROLLBACK_FAILED_NO_SNAPSHOT",
          ~data=Some(Logger.castToJson({"id": snapshotId})),
          (),
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
      NotificationManager.dispatch({
        id: "",
        importance: Warning,
        context: SystemEvent("optimistic_action"),
        message: "Action failed. Changes have been reverted.",
        details: Some("Error: " ++ msg),
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Warning),
        dismissible: true,
        createdAt: Date.now(),
      })
      Promise.resolve(RolledBack(msg))
    | None => Promise.resolve(RolledBack(msg ++ " (Rollback failed)"))
    }
  })
}
