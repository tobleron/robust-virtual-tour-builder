open OperationJournal

type handler = journalEntry => Promise.t<bool>

let handlers: Dict.t<handler> = Dict.make()

let registerHandler = (operation: string, handler: handler) => {
  Dict.set(handlers, operation, handler)
}

let hasHandler = (operation: string) => Dict.get(handlers, operation)->Option.isSome

let canRetry = (entry: journalEntry) => {
  let retryableStatus = switch entry.status {
  | Pending | InProgress | Interrupted => true
  | Completed | Failed(_) | Cancelled => false
  }
  entry.retryable && retryableStatus && hasHandler(entry.operation)
}

let retry = (entry: journalEntry) => {
  if !canRetry(entry) {
    Logger.warn(
      ~module_="RecoveryManager",
      ~message="Skipped non-retryable recovery entry",
      ~data={"id": entry.id, "operation": entry.operation, "retryable": entry.retryable},
      (),
    )
    let failureReason = if !entry.retryable {
      "Operation is not retryable"
    } else if !hasHandler(entry.operation) {
      "No recovery handler registered"
    } else {
      "Operation is already in terminal state"
    }
    OperationJournal.failOperation(entry.id, failureReason)
  } else {
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
      OperationJournal.updateStatus(entry.id, InProgress)
      ->Promise.then(() => handler(entry))
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
          // Mark operation completed exactly once after successful handler execution.
          OperationJournal.completeOperation(entry.id)->Promise.then(() => Promise.resolve())
        } else {
          NotificationManager.dispatch({
            id: "",
            importance: Error,
            context: SystemEvent("recovery"),
            message: NotificationTypes.truncateForToast("Failed to recover " ++ entry.operation),
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Error),
            dismissible: true,
            createdAt: Date.now(),
          })
          OperationJournal.failOperation(entry.id, "Recovery handler returned unsuccessful")
        }
      })
      ->Promise.catch(e => {
        let (msg, _) = Logger.getErrorDetails(e)
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: SystemEvent("recovery"),
          message: NotificationTypes.truncateForToast("Recovery Error: " ++ msg),
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        OperationJournal.failOperation(entry.id, "Recovery error: " ++ msg)
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
      OperationJournal.failOperation(entry.id, "No recovery handler for " ++ entry.operation)
    }
  }
}
