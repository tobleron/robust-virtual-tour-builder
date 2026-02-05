open OperationJournal

type handler = journalEntry => Promise.t<bool>

let handlers: Dict.t<handler> = Dict.make()

let registerHandler = (operation: string, handler: handler) => {
  Dict.set(handlers, operation, handler)
}

let retry = (entry: journalEntry) => {
  switch Dict.get(handlers, entry.operation) {
  | Some(handler) =>
    EventBus.dispatch(ShowNotification("Recovering " ++ entry.operation ++ "...", #Info, None))
    handler(entry)
    ->Promise.then(success => {
      if success {
        EventBus.dispatch(
          ShowNotification(entry.operation ++ " recovered successfully", #Success, None),
        )
        // Mark the old interrupted operation as completed since it has been handled (re-tried)
        OperationJournal.completeOperation(entry.id)->Promise.then(() => Promise.resolve())
      } else {
        EventBus.dispatch(ShowNotification("Failed to recover " ++ entry.operation, #Error, None))
        Promise.resolve()
      }
    })
    ->Promise.catch(e => {
      let (msg, _) = Logger.getErrorDetails(e)
      EventBus.dispatch(ShowNotification("Recovery Error: " ++ msg, #Error, None))
      Promise.resolve()
    })
  | None =>
    Logger.warn(
      ~module_="RecoveryManager",
      ~message="No handler registered",
      ~data={"operation": entry.operation},
      (),
    )
    EventBus.dispatch(ShowNotification("No handler for " ++ entry.operation, #Error, None))
    Promise.resolve()
  }
}
