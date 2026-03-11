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
  NavigationSupervisorRuntime.notifyListeners(status.contents, listeners)
}

let addStatusListener = (cb: status => unit): (unit => unit) => {
  NavigationSupervisorRuntime.addStatusListener(listeners, cb)
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
  NavigationSupervisorState.cancelTask(
    ~taskOpt=currentTask.contents,
    ~abortTask=task => task.abort(),
    ~cancelOp=task => task.opId->Option.forEach(id => OperationLifecycle.cancel(id)),
  )
  NavigationSupervisorState.resetSupervisorState(
    ~currentTaskRef=currentTask,
    ~statusRef=status,
    ~taskCounterRef=taskCounter,
    ~runIdRef=runId,
    ~idleStatus=Idle,
  )
  notifyListeners()
  Logger.info(~module_="NavigationSupervisor", ~message="SUPERVISOR_RESET", ())
}

let cancelExistingTask = (~targetSceneId: string) => {
  NavigationSupervisorLifecycle.cancelTaskWithLog(
    ~taskOpt=currentTask.contents,
    ~targetSceneId,
    ~abortTask=task => task.abort(),
    ~cancelOp=task => task.opId->Option.forEach(id => OperationLifecycle.cancel(id)),
    ~getTaskId=task => task.token.id,
    ~getTargetSceneId=task => task.targetSceneId,
  )
}

let makeTask = (targetSceneId: string): task => {
  let seed = NavigationSupervisorLifecycle.makeTaskSeed(
    ~targetSceneId,
    ~taskCounterRef=taskCounter,
    ~runIdRef=runId,
  )
  let token = {
    id: seed.taskId,
    epoch: seed.epoch,
    signal: seed.signal,
  }
  {
    token,
    targetSceneId,
    abort: () => BrowserBindings.AbortController.abort(seed.controller),
    startedAt: seed.startedAt,
    opId: Some(seed.opId),
  }
}

let setTaskActive = (~task, ~previewOnly: bool) => {
  currentTask := Some(task)
  status := if previewOnly {
      Panning(task.token.id, task.targetSceneId)
    } else {
      Loading(task.token.id, task.targetSceneId)
    }
  notifyListeners()
}

let updateLifecyclePhase = (newStatus: status) => {
  NavigationSupervisorLifecycle.updateLifecyclePhase(
    ~currentTaskOpt=currentTask.contents,
    ~newStatus,
    ~getOpId=task => task.opId,
    ~isSwapping=status =>
      switch status {
      | Swapping(_, _) => true
      | _ => false
      },
    ~isStabilizing=status =>
      switch status {
      | Stabilizing(_, _) => true
      | _ => false
      },
  )
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
  resetInFlightJourneyState(~reason="request_navigation", ~targetSceneId)
  cancelExistingTask(~targetSceneId)
  let task = makeTask(targetSceneId)
  setTaskActive(~task, ~previewOnly)

  Logger.debug(
    ~module_="NavigationSupervisor",
    ~message="NAVIGATION_REQUESTED",
    ~data=Some({
      "taskId": task.token.id,
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
    NavigationSupervisorState.advanceStatus(
      ~statusRef=status,
      ~newStatus,
      ~notify=notifyListeners,
      ~onProgress=updateLifecyclePhase,
    )->Option.forEach(prevStatus =>
      Logger.debug(
        ~module_="NavigationSupervisor",
        ~message="STATUS_TRANSITION",
        ~data=Some({
          "taskId": taskId,
          "from": statusToString(prevStatus),
          "to": statusToString(newStatus),
        }),
        (),
      )
    )
  } else {
    Logger.debug(
      ~module_="NavigationSupervisor",
      ~message="STALE_TASK_IGNORED",
      ~data=Some({
        "staleTaskId": taskId,
        "currentTaskId": NavigationSupervisorState.currentTaskIdString(
          ~currentTaskOpt=currentTask.contents,
          ~getId=t => t.token.id,
        ),
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

    Logger.debug(
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

    Logger.debug(
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
