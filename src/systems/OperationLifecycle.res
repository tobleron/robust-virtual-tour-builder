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
    | Unknown(string)

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
    status: status,
    startedAt: float,
    updatedAt: float,
    meta: option<JSON.t>,
  }
}

include Types

// --- STATE ---

let operations = ref(Belt.Map.String.empty)
let listeners: ref<array<array<task> => unit>> = ref([])

// --- INTERNAL HELPERS ---

let notifyListeners = () => {
  let ops = operations.contents->Belt.Map.String.valuesToArray
  listeners.contents->Belt.Array.forEach(cb => cb(ops))
}

// --- PUBLIC API ---

let reset = () => {
  operations := Belt.Map.String.empty
  listeners := []
}

let subscribe = (cb: array<task> => unit): (unit => unit) => {
  listeners := Belt.Array.concat(listeners.contents, [cb])
  // Initial callback
  cb(operations.contents->Belt.Map.String.valuesToArray)

  () => {
    listeners := listeners.contents->Belt.Array.keep(x => x !== cb)
  }
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

let isBusy = (~type_: option<operationType>=?, ()): bool => {
  operations.contents->Belt.Map.String.some((_, task) => {
    let isActive = switch task.status {
    | Active(_) | Paused => true
    | _ => false
    }

    switch type_ {
    | Some(t) => isActive && task.type_ == t
    | None => isActive
    }
  })
}

let start = (~type_: operationType, ~meta: option<JSON.t>=?, ()): operationId => {
  let id = `op_${Date.now()->Float.toString}_${Math.random()->Float.toString}`
  let task = {
    id,
    type_,
    status: Active({progress: 0.0, message: None}),
    startedAt: Date.now(),
    updatedAt: Date.now(),
    meta,
  }

  operations := operations.contents->Belt.Map.String.set(id, task)
  notifyListeners()

  Logger.info(
    ~module_="OperationLifecycle",
    ~message="OPERATION_STARTED",
    ~data=Some({"id": id, "type": type_}),
    (),
  )

  id
}

let progress = (id: operationId, progress: float, ~message: option<string>=?, ()): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    let updatedTask = {
      ...task,
      status: Active({progress, message}),
      updatedAt: Date.now(),
    }
    operations := operations.contents->Belt.Map.String.set(id, updatedTask)
    notifyListeners()
  | None => ()
  }
}

let complete = (id: operationId, ~result: option<string>=?, ()): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    let updatedTask = {
      ...task,
      status: Completed({result: result}),
      updatedAt: Date.now(),
    }
    operations := operations.contents->Belt.Map.String.set(id, updatedTask)
    notifyListeners()

    Logger.info(
      ~module_="OperationLifecycle",
      ~message="OPERATION_COMPLETED",
      ~data=Some({"id": id}),
      (),
    )

    // Auto-cleanup after 5 seconds
    let _ = setTimeout(() => {
      operations := operations.contents->Belt.Map.String.remove(id)
      notifyListeners()
    }, 5000)
  | None => ()
  }
}

let fail = (id: operationId, error: string): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    let updatedTask = {
      ...task,
      status: Failed({error: error}),
      updatedAt: Date.now(),
    }
    operations := operations.contents->Belt.Map.String.set(id, updatedTask)
    notifyListeners()

    Logger.error(
      ~module_="OperationLifecycle",
      ~message="OPERATION_FAILED",
      ~data=Some({"id": id, "error": error}),
      (),
    )

    // Auto-cleanup after 10 seconds for errors
    let _ = setTimeout(() => {
      operations := operations.contents->Belt.Map.String.remove(id)
      notifyListeners()
    }, 10000)
  | None => ()
  }
}

let cancel = (id: operationId): unit => {
  switch operations.contents->Belt.Map.String.get(id) {
  | Some(task) =>
    let updatedTask = {
      ...task,
      status: Cancelled,
      updatedAt: Date.now(),
    }
    operations := operations.contents->Belt.Map.String.set(id, updatedTask)
    notifyListeners()

    Logger.info(
      ~module_="OperationLifecycle",
      ~message="OPERATION_CANCELLED",
      ~data=Some({"id": id}),
      (),
    )

    // Auto-cleanup
    let _ = setTimeout(() => {
      operations := operations.contents->Belt.Map.String.remove(id)
      notifyListeners()
    }, 5000)
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

let useIsBusy = (~type_: option<operationType>=?) => {
  let ops = useOperations()

  React.useMemo2(() => {
    ops->Belt.Array.some(task => {
      let isActive = switch task.status {
      | Active(_) | Paused => true
      | _ => false
      }

      switch type_ {
      | Some(t) => isActive && task.type_ == t
      | None => isActive
      }
    })
  }, (ops, type_))
}
