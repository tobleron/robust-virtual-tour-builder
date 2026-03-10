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

let ttlMsForType = (type_: operationType): int => OperationLifecycleRuntime.ttlMsForType(type_)

// --- INTERNAL HELPERS ---

let notifyListeners = () => {
  OperationLifecycleRuntime.notifyListeners(~operations, ~listeners)
}

let updateLoggerContext = () => {
  OperationLifecycleRuntime.updateLoggerContext(~operations)
}

let activeCount = (): int => OperationLifecycleRuntime.activeCount(~operations)

let cleanupTerminalOperation = (id: operationId): unit => {
  OperationLifecycleRuntime.cleanupTerminalOperation(
    ~operations,
    ~cancelCallbacks,
    ~updateLoggerContext,
    ~notifyListeners,
    id,
  )
}

let sweepExpiredOperations = (): unit => {
  OperationLifecycleRuntime.sweepExpiredOperations(
    ~operations,
    ~cancelCallbacks,
    ~leakedTotal,
    ~updateLoggerContext,
    ~notifyListeners,
    ~cleanupTerminalOperation,
  )
}

let ensureSweepInterval = (): unit => {
  OperationLifecycleRuntime.ensureSweepInterval(~sweepIntervalId, ~sweepExpiredOperations)
}

// --- PUBLIC API ---

let reset = () => {
  operations := Belt.Map.String.empty
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
  // Preserve active subscribers across project resets (LoadProject/Reset in AppContext)
  // so sidebar progress + ESC cancel bindings remain connected after imports.
  notifyListeners()
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
  OperationLifecycleRuntime.isBusy(~operations, ~type_, ~scope, ())
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
  OperationLifecycleRuntime.start(
    ~operations,
    ~ensureSweepInterval,
    ~updateLoggerContext,
    ~notifyListeners,
    ~type_,
    ~scope,
    ~phase,
    ~cancellable,
    ~correlationId?,
    ~meta?,
    ~visibleAfterMs?,
    (),
  )
}

let progress = (
  id: operationId,
  progress: float,
  ~message: option<string>=?,
  ~phase: option<string>=?,
  (),
): unit => {
  OperationLifecycleRuntime.progress(
    ~operations,
    ~notifyListeners,
    id,
    progress,
    ~message?,
    ~phase?,
    (),
  )
}

let complete = (id: operationId, ~result: option<string>=?, ()): unit => {
  OperationLifecycleRuntime.complete(
    ~operations,
    ~cancelCallbacks,
    ~completedTotal,
    ~updateLoggerContext,
    ~notifyListeners,
    ~cleanupTerminalOperation,
    id,
    ~result?,
    (),
  )
}

let fail = (id: operationId, error: string): unit => {
  OperationLifecycleRuntime.fail(
    ~operations,
    ~cancelCallbacks,
    ~updateLoggerContext,
    ~notifyListeners,
    ~cleanupTerminalOperation,
    id,
    error,
  )
}

let cancel = (id: operationId): unit => {
  OperationLifecycleRuntime.cancel(
    ~operations,
    ~cancelCallbacks,
    ~updateLoggerContext,
    ~notifyListeners,
    ~cleanupTerminalOperation,
    id,
  )
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
    OperationLifecycleRuntime.arrayIsBusy(~ops, ~type_, ~scope)
  }, (ops, type_, scope))
}
