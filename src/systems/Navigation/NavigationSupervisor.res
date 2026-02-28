/* src/systems/Navigation/NavigationSupervisor.res
 *
 * Centralized Navigation Supervisor
 * Uses intent-based auto-cancel model.
 * Uses AbortController/AbortSignal for structured concurrency.
 */

type taskId = string

type status =
  | Idle
  | Loading(taskId, string) // (taskId, sceneId)
  | Swapping(taskId, string) // (taskId, sceneId)
  | Stabilizing(taskId, string) // (taskId, sceneId)
  | Panning(taskId, string) // (taskId, sceneId)

type runToken = {
  id: taskId,
  epoch: int,
  signal: BrowserBindings.AbortSignal.t,
}

type task = {
  token: runToken,
  targetSceneId: string,
  abort: unit => unit,
  startedAt: float,
  opId: option<OperationLifecycle.operationId>,
}

// Module-level refs
let taskCounter = ref(0)
let currentTask: ref<option<task>> = ref(None)
let status: ref<status> = ref(Idle)
let listeners: ref<array<status => unit>> = ref([])
let runId = ref(0)

// Initialize module
let () = {
  Logger.initialized(~module_="NavigationSupervisor")
}

let notifyListeners = () => {
  listeners.contents->Belt.Array.forEach(cb => {
    try {
      cb(status.contents)
    } catch {
    | exn =>
      let (msg, _) = Logger.getErrorDetails(exn)
      Logger.error(
        ~module_="NavigationSupervisor",
        ~message="LISTENER_ERROR",
        ~data=Some({"error": msg}),
        (),
      )
    }
  })
}

let addStatusListener = (cb: status => unit): (unit => unit) => {
  listeners := Belt.Array.concat(listeners.contents, [cb])
  // Return unsubscribe function
  () => {
    listeners := listeners.contents->Belt.Array.keep(x => x !== cb)
  }
}

let isIdle = (): bool => {
  status.contents == Idle
}

let isBusy = (): bool => {
  !isIdle()
}

let getStatus = (): status => {
  status.contents
}

let getCurrentTask = (): option<task> => {
  currentTask.contents
}

let getRunId = (): int => {
  runId.contents
}

let isCurrentToken = (token: runToken): bool => {
  switch currentTask.contents {
  | Some(task) => task.token.id == token.id && task.token.epoch == token.epoch
  | None => false
  }
}

let isCurrentTaskId = (taskId: taskId): bool => {
  switch currentTask.contents {
  | Some(task) => task.token.id == taskId
  | None => false
  }
}

let reset = () => {
  switch currentTask.contents {
  | Some(task) =>
    task.abort()
    task.opId->Option.forEach(id => OperationLifecycle.cancel(id))
  | None => ()
  }
  currentTask := None
  status := Idle
  taskCounter := 0
  runId := 0
  notifyListeners()
  Logger.info(~module_="NavigationSupervisor", ~message="SUPERVISOR_RESET", ())
}

// Internal dispatch helper
let dispatchRef: ref<option<Actions.action => unit>> = ref(None)

let configure = (d: Actions.action => unit) => {
  dispatchRef := Some(d)
}

let dispatchInternal = (action: Actions.action) => {
  switch dispatchRef.contents {
  | Some(d) => d(action)
  | None => AppStateBridge.dispatch(action)
  }
}

let resetInFlightJourneyState = (~reason: string, ~targetSceneId: string) => {
  let currentState = AppStateBridge.getState()
  switch currentState.navigationState.navigation {
  | Idle => ()
  | _ =>
    dispatchInternal(Actions.SetNavigationStatus(Idle))
    dispatchInternal(Actions.SetIncomingLink(None))
    Logger.info(
      ~module_="NavigationSupervisor",
      ~message="IN_FLIGHT_JOURNEY_RESET",
      ~data=Some({"reason": reason, "targetSceneId": targetSceneId}),
      (),
    )
  }
}

let statusToString = (s: status): string => {
  switch s {
  | Idle => "Idle"
  | Loading(taskId, sceneId) => `Loading(${taskId}, ${sceneId})`
  | Swapping(taskId, sceneId) => `Swapping(${taskId}, ${sceneId})`
  | Stabilizing(taskId, sceneId) => `Stabilizing(${taskId}, ${sceneId})`
  | Panning(taskId, sceneId) => `Panning(${taskId}, ${sceneId})`
  }
}

let requestNavigation = (targetSceneId: string, ~previewOnly=false): unit => {
  // If any journey state is still active, reset it so stale completions cannot win over the latest intent.
  resetInFlightJourneyState(~reason="request_navigation", ~targetSceneId)

  // Cancel previous task if it exists
  switch currentTask.contents {
  | Some(task) =>
    task.abort()
    // Cancel operation in Lifecycle
    task.opId->Option.forEach(id => OperationLifecycle.cancel(id))

    Logger.info(
      ~module_="NavigationSupervisor",
      ~message="PREVIOUS_TASK_CANCELLED",
      ~data=Some({
        "previousTaskId": task.token.id,
        "previousSceneId": task.targetSceneId,
        "newSceneId": targetSceneId,
      }),
      (),
    )
  | None => ()
  }

  // Create new task with AbortController
  let controller = BrowserBindings.AbortController.make()
  let abortSignal = BrowserBindings.AbortController.signal(controller)
  taskCounter := taskCounter.contents + 1
  runId := runId.contents + 1
  let taskId = `task_${Date.now()->Float.toString}_${taskCounter.contents->Belt.Int.toString}`
  let token = {
    id: taskId,
    epoch: runId.contents,
    signal: abortSignal,
  }

  // Start Global Operation
  let opId = OperationLifecycle.start(
    ~type_=Navigation,
    ~scope=Blocking,
    ~phase="Loading",
    ~meta=Logger.castToJson({"targetSceneId": targetSceneId}),
    (),
  )

  let task = {
    token,
    targetSceneId,
    abort: () => {
      BrowserBindings.AbortController.abort(controller)
    },
    startedAt: Date.now(),
    opId: Some(opId),
  }

  currentTask := Some(task)
  status := if previewOnly {
      Panning(taskId, targetSceneId)
    } else {
      Loading(taskId, targetSceneId)
    }
  notifyListeners()

  Logger.info(
    ~module_="NavigationSupervisor",
    ~message="NAVIGATION_REQUESTED",
    ~data=Some({
      "taskId": taskId,
      "targetSceneId": targetSceneId,
      "previewOnly": previewOnly,
    }),
    (),
  )

  // Dispatch FSM event to update UI state (LockFeedback, ViewerHUD, etc.)
  dispatchInternal(
    Actions.DispatchNavigationFsmEvent(UserClickedScene({targetSceneId, previewOnly})),
  )
}

let transitionTo = (taskId: taskId, newStatus: status): unit => {
  // Only process if taskId matches current task (stale-task guard)
  if isCurrentTaskId(taskId) {
    if status.contents == newStatus {
      ()
    } else {
      let prevStatus = status.contents
      status := newStatus
      notifyListeners()

      // Update OperationLifecycle Phase
      switch newStatus {
      | Swapping(_, _) =>
        currentTask.contents->Option.forEach(t =>
          t.opId->Option.forEach(id => OperationLifecycle.progress(id, 50.0, ~phase="Swapping", ()))
        )
      | Stabilizing(_, _) =>
        currentTask.contents->Option.forEach(t =>
          t.opId->Option.forEach(id =>
            OperationLifecycle.progress(id, 80.0, ~phase="Stabilizing", ())
          )
        )
      | _ => ()
      }

      Logger.info(
        ~module_="NavigationSupervisor",
        ~message="STATUS_TRANSITION",
        ~data=Some({
          "taskId": taskId,
          "from": statusToString(prevStatus),
          "to": statusToString(newStatus),
        }),
        (),
      )
    }
  } else {
    Logger.debug(
      ~module_="NavigationSupervisor",
      ~message="STALE_TASK_IGNORED",
      ~data=Some({
        "staleTaskId": taskId,
        "currentTaskId": switch currentTask.contents {
        | Some(t) => t.token.id
        | None => "none"
        },
      }),
      (),
    )
  }
}

let complete = (taskId: taskId): unit => {
  // Only process if taskId matches current task
  if isCurrentTaskId(taskId) {
    // Complete operation
    currentTask.contents->Option.forEach(t =>
      t.opId->Option.forEach(id => OperationLifecycle.complete(id, ~result="Completed", ()))
    )

    currentTask := None
    status := Idle
    notifyListeners()

    Logger.info(
      ~module_="NavigationSupervisor",
      ~message="TASK_COMPLETED",
      ~data=Some({
        "taskId": taskId,
      }),
      (),
    )
  } else {
    Logger.debug(
      ~module_="NavigationSupervisor",
      ~message="STALE_TASK_COMPLETION_IGNORED",
      ~data=Some({
        "taskId": taskId,
      }),
      (),
    )
  }
}

let abort = (taskId: taskId): unit => {
  // Only process if taskId matches current task
  if isCurrentTaskId(taskId) {
    let abortedTargetSceneId = switch currentTask.contents {
    | Some(task) => task.targetSceneId
    | None => ""
    }

    // Cancel operation
    currentTask.contents->Option.forEach(t =>
      t.opId->Option.forEach(id => OperationLifecycle.cancel(id))
    )

    currentTask := None
    status := Idle
    notifyListeners()

    Logger.info(
      ~module_="NavigationSupervisor",
      ~message="TASK_ABORTED",
      ~data=Some({
        "taskId": taskId,
      }),
      (),
    )

    resetInFlightJourneyState(~reason="task_abort", ~targetSceneId=abortedTargetSceneId)

    // Dispatch FSM abort event to update UI state
    dispatchInternal(Actions.DispatchNavigationFsmEvent(Aborted))
  } else {
    Logger.debug(
      ~module_="NavigationSupervisor",
      ~message="STALE_TASK_ABORT_IGNORED",
      ~data=Some({
        "taskId": taskId,
      }),
      (),
    )
  }
}
