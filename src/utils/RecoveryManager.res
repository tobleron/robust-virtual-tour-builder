open OperationJournal

type handler = journalEntry => Promise.t<bool>

let handlers: Dict.t<handler> = Dict.make()

let registerHandler = (operation: string, handler: handler) => {
  Dict.set(handlers, operation, handler)
}

let retry = (entry: journalEntry) => {
  switch Dict.get(handlers, entry.operation) {
  | Some(handler) =>
    NotificationManager.dispatch({
      id: "",
      importance: Info,
      context: SystemEvent("recovery"),
      message: "Recovering " ++ entry.operation ++ "...",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Info),
      dismissible: true,
      createdAt: Date.now(),
    })
    handler(entry)
    ->Promise.then(success => {
      if success {
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: SystemEvent("recovery"),
          message: entry.operation ++ " recovered successfully",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
        // Mark the old interrupted operation as completed since it has been handled (re-tried)
        OperationJournal.completeOperation(entry.id)->Promise.then(() => Promise.resolve())
      } else {
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: SystemEvent("recovery"),
          message: "Failed to recover " ++ entry.operation,
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        Promise.resolve()
      }
    })
    ->Promise.catch(e => {
      let (msg, _) = Logger.getErrorDetails(e)
      NotificationManager.dispatch({
        id: "",
        importance: Error,
        context: SystemEvent("recovery"),
        message: "Recovery Error: " ++ msg,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
      Promise.resolve()
    })
  | None =>
    Logger.warn(
      ~module_="RecoveryManager",
      ~message="No handler registered",
      ~data={"operation": entry.operation},
      (),
    )
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: SystemEvent("recovery"),
      message: "No handler for " ++ entry.operation,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    Promise.resolve()
  }
}
