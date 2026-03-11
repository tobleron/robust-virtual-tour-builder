include OperationLifecycleTypes

let ttlSweepMs = 30000
let timeoutTtlExceeded = "OPERATION_TIMEOUT_TTL_EXCEEDED"

let ttlMsForType = (type_: operationType): int => OperationLifecycleMaintenance.ttlMsForType(type_)

let notifyListeners = (~operations, ~listeners): unit => {
  OperationLifecycleMaintenance.notifyListeners(~operations, ~listeners)
}

let updateLoggerContext = (~operations): unit => {
  OperationLifecycleMaintenance.updateLoggerContext(~operations)
}

let activeCount = (~operations): int => OperationLifecycleMaintenance.activeCount(~operations)

let cleanupTerminalOperation = (
  ~operations,
  ~cancelCallbacks,
  ~updateLoggerContext,
  ~notifyListeners,
  id: operationId,
): unit => {
  OperationLifecycleMaintenance.cleanupTerminalOperation(
    ~operations,
    ~cancelCallbacks,
    ~updateLoggerContext,
    ~notifyListeners,
    id,
  )
}

let sweepExpiredOperations = (
  ~operations,
  ~cancelCallbacks,
  ~leakedTotal,
  ~updateLoggerContext,
  ~notifyListeners,
  ~cleanupTerminalOperation,
): unit => {
  OperationLifecycleMaintenance.sweepExpiredOperations(
    ~operations,
    ~cancelCallbacks,
    ~leakedTotal,
    ~updateLoggerContext,
    ~notifyListeners,
    ~cleanupTerminalOperation,
  )
}

let ensureSweepInterval = (~sweepIntervalId, ~sweepExpiredOperations): unit => {
  OperationLifecycleMaintenance.ensureSweepInterval(~sweepIntervalId, ~sweepExpiredOperations)
}

let isBusy = (~operations, ~type_, ~scope, ()): bool => {
  OperationLifecycleBusy.isBusy(~operations, ~type_, ~scope, ())
}

let start = (
  ~operations,
  ~ensureSweepInterval,
  ~updateLoggerContext,
  ~notifyListeners,
  ~type_: operationType,
  ~scope: scope=Ambient,
  ~phase: string="Running",
  ~cancellable: bool=true,
  ~correlationId: option<string>=?,
  ~meta: option<JSON.t>=?,
  ~visibleAfterMs: option<int>=?,
  (),
): operationId => {
  let id = `op_${Date.now()->Float.toString}_${Math.random()->Float.toString}`
  let defaultThreshold = OperationLifecycleContext.defaultVisibleAfterMs(type_)
  let threshold = visibleAfterMs->Option.getOr(defaultThreshold)

  let task = {
    id,
    type_,
    scope,
    phase,
    cancellable,
    correlationId,
    status: Active({progress: 0.0, message: None}),
    startedAt: Date.now(),
    updatedAt: Date.now(),
    meta,
    visibleAfterMs: threshold,
  }

  operations := operations.contents->Belt.Map.String.set(id, task)
  ensureSweepInterval()
  updateLoggerContext()
  notifyListeners()

  let activeNow = activeCount(~operations)
  if activeNow >= 10 {
    Logger.warn(
      ~module_="OperationLifecycle",
      ~message="OPERATION_WATERMARK_HIGH_ACTIVE",
      ~data=Some({"activeCount": activeNow}),
      (),
    )
  }

  Logger.debug(
    ~module_="OperationLifecycle",
    ~message="OPERATION_STARTED",
    ~data=Some({
      "id": id,
      "type": type_,
      "scope": scope,
      "phase": phase,
      "cancellable": cancellable,
      "visibleAfterMs": threshold,
    }),
    (),
  )

  id
}

let progress = (
  ~operations,
  ~notifyListeners,
  id,
  progress,
  ~message: option<string>=?,
  ~phase: option<string>=?,
  (),
): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    switch task.status {
    | Active(_)
    | Paused =>
      let updatedTask = {
        ...task,
        status: Active({progress, message}),
        phase: phase->Option.getOr(task.phase),
        updatedAt: Date.now(),
      }
      operations := operations.contents->Belt.Map.String.set(id, updatedTask)
      notifyListeners()
    | Idle
    | Completed(_)
    | Failed(_)
    | Cancelled =>
      Logger.debug(
        ~module_="OperationLifecycle",
        ~message="PROGRESS_IGNORED_TERMINAL_OR_IDLE",
        ~data=Some({"id": id}),
        (),
      )
    }
  | None => ()
  }
}

let complete = (
  ~operations,
  ~cancelCallbacks,
  ~completedTotal,
  ~updateLoggerContext,
  ~notifyListeners,
  ~cleanupTerminalOperation,
  id: operationId,
  ~result: option<string>=?,
  (),
): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    switch task.status {
    | Active(_)
    | Paused =>
      let updatedTask = {
        ...task,
        status: Completed({result: result}),
        updatedAt: Date.now(),
      }
      operations := operations.contents->Belt.Map.String.set(id, updatedTask)
      completedTotal := completedTotal.contents + 1
      updateLoggerContext()
      notifyListeners()
      cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(id)

      Logger.debug(
        ~module_="OperationLifecycle",
        ~message="OPERATION_COMPLETED",
        ~data=Some({"id": id}),
        (),
      )

      let _ = setTimeout(() => cleanupTerminalOperation(id), 5000)
    | Idle
    | Completed(_)
    | Failed(_)
    | Cancelled =>
      Logger.debug(
        ~module_="OperationLifecycle",
        ~message="COMPLETE_IGNORED_TERMINAL_OR_IDLE",
        ~data=Some({"id": id}),
        (),
      )
    }
  | None => ()
  }
}

let fail = (
  ~operations,
  ~cancelCallbacks,
  ~updateLoggerContext,
  ~notifyListeners,
  ~cleanupTerminalOperation,
  id: operationId,
  error: string,
): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    switch task.status {
    | Active(_)
    | Paused =>
      let updatedTask = {
        ...task,
        status: Failed({error: error}),
        updatedAt: Date.now(),
      }
      operations := operations.contents->Belt.Map.String.set(id, updatedTask)
      updateLoggerContext()
      notifyListeners()
      cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(id)

      Logger.error(
        ~module_="OperationLifecycle",
        ~message="OPERATION_FAILED",
        ~data=Some({"id": id, "error": error}),
        (),
      )

      let _ = setTimeout(() => cleanupTerminalOperation(id), 10000)
    | Idle
    | Completed(_)
    | Failed(_)
    | Cancelled =>
      Logger.debug(
        ~module_="OperationLifecycle",
        ~message="FAIL_IGNORED_TERMINAL_OR_IDLE",
        ~data=Some({"id": id}),
        (),
      )
    }
  | None => ()
  }
}

let cancel = (
  ~operations,
  ~cancelCallbacks,
  ~updateLoggerContext,
  ~notifyListeners,
  ~cleanupTerminalOperation,
  id: operationId,
): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    switch task.status {
    | Active(_)
    | Paused =>
      if task.cancellable {
        switch cancelCallbacks.contents->Belt.Map.String.get(id) {
        | Some(cb) =>
          Logger.debug(
            ~module_="OperationLifecycle",
            ~message="INVOKING_CANCEL_CALLBACK",
            ~data=Some({"id": id}),
            (),
          )
          cb()
        | None => ()
        }

        let updatedTask = {
          ...task,
          status: Cancelled,
          updatedAt: Date.now(),
        }
        operations := operations.contents->Belt.Map.String.set(id, updatedTask)
        updateLoggerContext()
        notifyListeners()
        cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(id)

        Logger.debug(
          ~module_="OperationLifecycle",
          ~message="OPERATION_CANCELLED",
          ~data=Some({"id": id}),
          (),
        )

        let _ = setTimeout(() => cleanupTerminalOperation(id), 5000)
      } else {
        Logger.warn(
          ~module_="OperationLifecycle",
          ~message="OPERATION_CANCEL_ATTEMPT_IGNORED",
          ~data=Some({"id": id, "reason": "Not Cancellable"}),
          (),
        )
      }
    | Idle
    | Completed(_)
    | Failed(_)
    | Cancelled =>
      Logger.debug(
        ~module_="OperationLifecycle",
        ~message="CANCEL_IGNORED_TERMINAL_OR_IDLE",
        ~data=Some({"id": id}),
        (),
      )
    }
  | None => ()
  }
}

let arrayIsBusy = (~ops, ~type_, ~scope): bool =>
  OperationLifecycleBusy.arrayIsBusy(~ops, ~type_, ~scope)
