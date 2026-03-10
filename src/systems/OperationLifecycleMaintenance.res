@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external setInterval: (unit => unit, int) => int = "setInterval"

include OperationLifecycleTypes

let ttlSweepMs = 30000
let timeoutTtlExceeded = "OPERATION_TIMEOUT_TTL_EXCEEDED"

let ttlMsForType = (type_: operationType): int =>
  switch type_ {
  | Upload => 7200000
  | Export => 3600000
  | ProjectLoad => 300000
  | ProjectSave => 120000
  | Navigation => 60000
  | SceneLoad => 60000
  | _ => 300000
  }

let notifyListeners = (~operations, ~listeners): unit => {
  let ops = operations.contents->Belt.Map.String.valuesToArray
  listeners.contents->Belt.Array.forEach(cb => cb(ops))
}

let updateLoggerContext = (~operations): unit => {
  let contextOp =
    operations.contents
    ->Belt.Map.String.valuesToArray
    ->OperationLifecycleContext.selectContextOperation

  switch contextOp {
  | Some(op) => Logger.setOperationId(Some(op.id))
  | None => Logger.setOperationId(None)
  }
}

let activeCount = (~operations): int =>
  operations.contents
  ->Belt.Map.String.valuesToArray
  ->Belt.Array.keep(task => OperationLifecycleContext.isActiveStatus(task.status))
  ->Belt.Array.length

let cleanupTerminalOperation = (
  ~operations,
  ~cancelCallbacks,
  ~updateLoggerContext,
  ~notifyListeners,
  id: operationId,
): unit => {
  operations := operations.contents->Belt.Map.String.remove(id)
  cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(id)
  updateLoggerContext()
  notifyListeners()
}

let sweepExpiredOperations = (
  ~operations,
  ~cancelCallbacks,
  ~leakedTotal,
  ~updateLoggerContext,
  ~notifyListeners,
  ~cleanupTerminalOperation,
): unit => {
  let now = Date.now()

  operations.contents
  ->Belt.Map.String.valuesToArray
  ->Belt.Array.forEach(task => {
    if OperationLifecycleContext.isActiveStatus(task.status) {
      let ttl = ttlMsForType(task.type_)
      let elapsedSinceUpdate = now -. task.updatedAt

      if elapsedSinceUpdate > Int.toFloat(ttl) {
        leakedTotal := leakedTotal.contents + 1
        let updatedTask = {
          ...task,
          status: Failed({error: timeoutTtlExceeded}),
          updatedAt: now,
        }

        operations := operations.contents->Belt.Map.String.set(task.id, updatedTask)
        cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(task.id)
        updateLoggerContext()
        notifyListeners()

        Logger.error(
          ~module_="OperationLifecycle",
          ~message="OPERATION_TTL_EXPIRED",
          ~data=Some({
            "id": task.id,
            "type": task.type_,
            "ttlMs": ttl,
            "elapsedMs": elapsedSinceUpdate,
            "phase": task.phase,
          }),
          (),
        )

        let _ = setTimeout(() => cleanupTerminalOperation(task.id), 10000)
      }
    }
  })
}

let ensureSweepInterval = (~sweepIntervalId, ~sweepExpiredOperations): unit => {
  switch sweepIntervalId.contents {
  | Some(_) => ()
  | None =>
    let intervalId = setInterval(() => sweepExpiredOperations(), ttlSweepMs)
    sweepIntervalId := Some(intervalId)
  }
}
