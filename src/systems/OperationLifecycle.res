/* src/systems/OperationLifecycle.res */

// Bindings
@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external setInterval: (unit => unit, int) => int = "setInterval"
@val external clearInterval: int => unit = "clearInterval"

include OperationLifecycleTypes

// --- STATE ---

let operations = ref(Belt.Map.String.empty)
let listeners: ref<array<array<task> => unit>> = ref([])
let cancelCallbacks = ref(Belt.Map.String.empty)
let completedTotal = ref(0)
let leakedTotal = ref(0)
let sweepIntervalId: ref<option<int>> = ref(None)

let ttlSweepMs = 30000
let timeoutTtlExceeded = "OPERATION_TIMEOUT_TTL_EXCEEDED"

let ttlMsForType = (type_: operationType): int =>
  switch type_ {
  | Upload => 600000
  | Export => 300000
  | ProjectLoad => 120000
  | ProjectSave => 60000
  | Navigation => 30000
  | SceneLoad => 30000
  | _ => 120000
  }

// --- INTERNAL HELPERS ---

let notifyListeners = () => {
  let ops = operations.contents->Belt.Map.String.valuesToArray
  listeners.contents->Belt.Array.forEach(cb => cb(ops))
}

let updateLoggerContext = () => {
  let contextOp =
    operations.contents->Belt.Map.String.valuesToArray->OperationLifecycleContext.selectContextOperation

  switch contextOp {
  | Some(op) => Logger.setOperationId(Some(op.id))
  | None => Logger.setOperationId(None)
  }
}

let activeCount = (): int =>
  operations.contents->Belt.Map.String.valuesToArray->Belt.Array.keep(task =>
    OperationLifecycleContext.isActiveStatus(task.status)
  )->Belt.Array.length

let cleanupTerminalOperation = (id: operationId): unit => {
  operations := operations.contents->Belt.Map.String.remove(id)
  cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(id)
  updateLoggerContext()
  notifyListeners()
}

let sweepExpiredOperations = (): unit => {
  let now = Date.now()
  operations.contents
  ->Belt.Map.String.valuesToArray
  ->Belt.Array.forEach(task => {
    if OperationLifecycleContext.isActiveStatus(task.status) {
      let ttl = ttlMsForType(task.type_)
      let elapsed = now -. task.startedAt
      if elapsed > Int.toFloat(ttl) {
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
            "elapsedMs": elapsed,
            "phase": task.phase,
          }),
          (),
        )
        let _ = setTimeout(() => cleanupTerminalOperation(task.id), 10000)
      }
    }
  })
}

let ensureSweepInterval = (): unit => {
  switch sweepIntervalId.contents {
  | Some(_) => ()
  | None =>
    let intervalId = setInterval(() => sweepExpiredOperations(), ttlSweepMs)
    sweepIntervalId := Some(intervalId)
  }
}

// --- PUBLIC API ---

let reset = () => {
  operations := Belt.Map.String.empty
  listeners := []
  cancelCallbacks := Belt.Map.String.empty
  completedTotal := 0
  leakedTotal := 0
  switch sweepIntervalId.contents {
  | Some(id) =>
    clearInterval(id)
    sweepIntervalId := None
  | None => ()
  }
  ensureSweepInterval()
  updateLoggerContext()
}

let subscribe = (cb: array<task> => unit): (unit => unit) => {
  listeners := Belt.Array.concat(listeners.contents, [cb])
  // Initial callback
  cb(operations.contents->Belt.Map.String.valuesToArray)

  () => {
    listeners := listeners.contents->Belt.Array.keep(x => x !== cb)
  }
}

let registerCancel = (id: operationId, cb: unit => unit): unit => {
  cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.set(id, cb)
}

let getOperation = (id: operationId): option<task> => {
  operations.contents->Belt.Map.String.get(id)
}

let getOperations = (): array<task> => {
  operations.contents->Belt.Map.String.valuesToArray
}

let isActive = (id: operationId): bool => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    switch task.status {
    | Active(_) | Paused => true
    | _ => false
    }
  | None => false
  }
}

let isBusy = (~type_: option<operationType>=?, ~scope: option<scope>=?, ()): bool => {
  operations.contents->Belt.Map.String.some((_, task) => {
    let isActive = OperationLifecycleContext.isActiveStatus(task.status)

    let typeMatch = switch type_ {
    | Some(t) => task.type_ == t
    | None => true
    }

    let scopeMatch = switch scope {
    | Some(s) => task.scope == s
    | None => true
    }

    isActive && typeMatch && scopeMatch
  })
}

let start = (
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

  let activeNow = activeCount()
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
  id: operationId,
  progress: float,
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

let complete = (id: operationId, ~result: option<string>=?, ()): unit => {
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

      // Auto-cleanup after 5 seconds
      let _ = setTimeout(() => {
        cleanupTerminalOperation(id)
      }, 5000)
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

let fail = (id: operationId, error: string): unit => {
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

      // Auto-cleanup after 10 seconds for errors
      let _ = setTimeout(() => {
        cleanupTerminalOperation(id)
      }, 10000)
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

let cancel = (id: operationId): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    switch task.status {
    | Active(_)
    | Paused =>
      if task.cancellable {
        // Invoke callback first
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

        // Auto-cleanup
        let _ = setTimeout(() => {
          cleanupTerminalOperation(id)
        }, 5000)
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

let getStats = (): lifecycleStats => {
  {
    active: activeCount(),
    completedTotal: completedTotal.contents,
    leakedTotal: leakedTotal.contents,
  }
}

// --- REACT HOOKS ---

let useOperations = () => {
  let (ops, setOps) = React.useState(_ => getOperations())

  React.useEffect0(() => {
    let unsubscribe = subscribe(newOps => {
      setOps(_ => newOps)
    })
    Some(unsubscribe)
  })

  ops
}

let useIsBusy = (~type_: option<operationType>=?, ~scope: option<scope>=?) => {
  let ops = useOperations()

  React.useMemo3(() => {
    ops->Belt.Array.some(task => {
      let isActive = OperationLifecycleContext.isActiveStatus(task.status)

      let typeMatch = switch type_ {
      | Some(t) => task.type_ == t
      | None => true
      }

      let scopeMatch = switch scope {
      | Some(s) => task.scope == s
      | None => true
      }

      isActive && typeMatch && scopeMatch
    })
  }, (ops, type_, scope))
}
