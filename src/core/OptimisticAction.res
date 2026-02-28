/* src/core/OptimisticAction.res */

type optimisticResult<'a> =
  | Committed('a)
  | RolledBack(string)

let execute = (
  ~action: Actions.action,
  ~apiCall: Types.state => Promise.t<result<'a, string>>,
  ~getState: unit => Types.state=AppContext.getBridgeState,
  ~getDispatch: unit => Actions.action => unit=AppContext.getBridgeDispatch,
  ~onRollback: Types.state => unit=AppContext.restoreState,
): Promise.t<optimisticResult<'a>> => {
  // 1. Capture state
  let currentState = getState()
  let snapshotId = StateSnapshot.capture(currentState, action)
  
  // 2. Compute next state for the API call (avoiding bridge lag)
  let nextState = Reducer.reducer(currentState, action)
  
  Logger.debug(
    ~module_="OptimisticAction",
    ~message="CAPTURING_SNAPSHOT",
    ~data=Some(Logger.castToJson({
      "id": snapshotId,
      "action": Actions.actionToString(action),
      "activeIndex": currentState.activeIndex,
    })),
    (),
  )

  // 3. Optimistic dispatch (to update UI)
  let dispatch = getDispatch()
  dispatch(action)

  // 4. API Call with the computed next state
  apiCall(nextState)
  ->Promise.then(result => {
    switch result {
    | Ok(data) =>
      // 5. Success -> Commit
      Logger.debug(
        ~module_="OptimisticAction",
        ~message="COMMIT_SUCCESS",
        ~data=Some(Logger.castToJson({"id": snapshotId})),
        (),
      )
      StateSnapshot.commit(snapshotId)
      Promise.resolve(Committed(data))

    | Error(msg) =>
      // 6. Failure -> Rollback
      Logger.warn(
        ~module_="OptimisticAction",
        ~message="ROLLBACK_TRIGGERED",
        ~data=Some(Logger.castToJson({
          "id": snapshotId,
          "error": msg,
          "action": Actions.actionToString(action),
        })),
        (),
      )
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
