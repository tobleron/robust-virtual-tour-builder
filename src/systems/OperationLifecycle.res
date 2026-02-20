/* src/systems/OperationLifecycle.res */

// Bindings
@val external setTimeout: (unit => unit, int) => int = "setTimeout"

module Types = {
  type operationId = string

  type operationType =
    | Navigation
    | Simulation
    | Upload
    | Export
    | ThumbnailGeneration
    | SceneLoad
    | ProjectLoad
    | ProjectSave
    | Unknown(string)

  type scope =
    | Blocking
    | Ambient

  type status =
    | Idle
    | Active({progress: float, message: option<string>})
    | Paused
    | Completed({result: option<string>})
    | Failed({error: string})
    | Cancelled

  type task = {
    id: operationId,
    type_: operationType,
    scope: scope,
    phase: string,
    cancellable: bool,
    correlationId: option<string>,
    status: status,
    startedAt: float,
    updatedAt: float,
    meta: option<JSON.t>,
    visibleAfterMs: int,
  }
}

include Types

// --- STATE ---

let operations = ref(Belt.Map.String.empty)
let listeners: ref<array<array<task> => unit>> = ref([])
let cancelCallbacks = ref(Belt.Map.String.empty)

// --- INTERNAL HELPERS ---

let notifyListeners = () => {
  let ops = operations.contents->Belt.Map.String.valuesToArray
  listeners.contents->Belt.Array.forEach(cb => cb(ops))
}

let updateLoggerContext = () => {
  // Determine the most relevant operation for logging context
  // Priority: Blocking > Ambient (latest started)
  let activeOps =
    operations.contents
    ->Belt.Map.String.valuesToArray
    ->Belt.Array.keep(t => {
      switch t.status {
      | Active(_) | Paused => true
      | _ => false
      }
    })

  let contextOp =
    activeOps
    ->Belt.Array.keep(t => t.scope == Blocking)
    ->Belt.SortArray.stableSortBy((a, b) => compare(b.startedAt, a.startedAt))
    ->Belt.Array.get(0)
    ->Option.orElse(
      activeOps
      ->Belt.Array.keep(t => t.scope == Ambient)
      ->Belt.SortArray.stableSortBy((a, b) => compare(b.startedAt, a.startedAt))
      ->Belt.Array.get(0),
    )

  switch contextOp {
  | Some(op) => Logger.setOperationId(Some(op.id))
  | None => Logger.setOperationId(None)
  }
}

// --- PUBLIC API ---

let reset = () => {
  operations := Belt.Map.String.empty
  listeners := []
  cancelCallbacks := Belt.Map.String.empty
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
    let isActive = switch task.status {
    | Active(_) | Paused => true
    | _ => false
    }

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

  let defaultThreshold = switch type_ {
  // Calibrated for long-task UI visibility: avoid flashing for short operations.
  | Navigation => 1200
  | Upload => 700
  | ThumbnailGeneration => 1500
  | ProjectLoad
  | ProjectSave
  | Export => 500
  | SceneLoad => 800
  | Simulation => 1200
  | Unknown(_) => 800
  }

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
  updateLoggerContext()
  notifyListeners()

  Logger.info(
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
      updateLoggerContext()
      notifyListeners()
      cancelCallbacks := cancelCallbacks.contents->Belt.Map.String.remove(id)

      Logger.info(
        ~module_="OperationLifecycle",
        ~message="OPERATION_COMPLETED",
        ~data=Some({"id": id}),
        (),
      )

      // Auto-cleanup after 5 seconds
      let _ = setTimeout(() => {
        operations := operations.contents->Belt.Map.String.remove(id)
        updateLoggerContext()
        notifyListeners()
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
        operations := operations.contents->Belt.Map.String.remove(id)
        updateLoggerContext()
        notifyListeners()
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
          Logger.info(
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

        Logger.info(
          ~module_="OperationLifecycle",
          ~message="OPERATION_CANCELLED",
          ~data=Some({"id": id}),
          (),
        )

        // Auto-cleanup
        let _ = setTimeout(() => {
          operations := operations.contents->Belt.Map.String.remove(id)
          updateLoggerContext()
          notifyListeners()
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
      let isActive = switch task.status {
      | Active(_) | Paused => true
      | _ => false
      }

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
