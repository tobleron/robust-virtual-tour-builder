/* src/systems/Navigation/NavigationSupervisor.res
 *
 * Centralized Navigation Supervisor
 * Replaces distributed TransitionLock pattern with intent-based auto-cancel model.
 * Uses AbortController/AbortSignal for structured concurrency.
 */

type taskId = string

type status =
  | Idle
  | Loading(taskId, string) // (taskId, sceneId)
  | Swapping(taskId, string) // (taskId, sceneId)
  | Stabilizing(taskId, string) // (taskId, sceneId)

type task = {
  id: taskId,
  targetSceneId: string,
  signal: BrowserBindings.AbortSignal.t, // AbortSignal for cancellation
  abort: unit => unit, // Calls AbortController.abort()
  startedAt: float,
}

// Module-level refs
let currentTask: ref<option<task>> = ref(None)
let status: ref<status> = ref(Idle)
let listeners: ref<array<status => unit>> = ref([])

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

let statusToString = (s: status): string => {
  switch s {
  | Idle => "Idle"
  | Loading(taskId, sceneId) => `Loading(${taskId}, ${sceneId})`
  | Swapping(taskId, sceneId) => `Swapping(${taskId}, ${sceneId})`
  | Stabilizing(taskId, sceneId) => `Stabilizing(${taskId}, ${sceneId})`
  }
}

let requestNavigation = (targetSceneId: string): unit => {
  // Cancel previous task if it exists
  switch currentTask.contents {
  | Some(task) =>
    task.abort()
    Logger.info(
      ~module_="NavigationSupervisor",
      ~message="PREVIOUS_TASK_CANCELLED",
      ~data=Some({
        "previousTaskId": task.id,
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
  let taskId = `task_${Date.now()->Float.toString}`
  let task = {
    id: taskId,
    targetSceneId,
    signal: abortSignal,
    abort: () => {
      BrowserBindings.AbortController.abort(controller)
    },
    startedAt: Date.now(),
  }

  currentTask := Some(task)
  status := Loading(taskId, targetSceneId)
  notifyListeners()

  Logger.info(
    ~module_="NavigationSupervisor",
    ~message="NAVIGATION_REQUESTED",
    ~data=Some({
      "taskId": taskId,
      "targetSceneId": targetSceneId,
    }),
    (),
  )

  // Dispatch FSM event to update UI state (LockFeedback, ViewerHUD, etc.)
  GlobalStateBridge.dispatch(
    Actions.DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: targetSceneId})),
  )
}

let transitionTo = (taskId: taskId, newStatus: status): unit => {
  // Only process if taskId matches current task (stale-task guard)
  let shouldProcess = switch currentTask.contents {
  | Some(task) => task.id == taskId
  | None => false
  }

  if shouldProcess {
    let prevStatus = status.contents
    status := newStatus
    notifyListeners()

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
  } else {
    Logger.debug(
      ~module_="NavigationSupervisor",
      ~message="STALE_TASK_IGNORED",
      ~data=Some({
        "staleTaskId": taskId,
        "currentTaskId": switch currentTask.contents {
        | Some(t) => t.id
        | None => "none"
        },
      }),
      (),
    )
  }
}

let complete = (taskId: taskId): unit => {
  // Only process if taskId matches current task
  let shouldComplete = switch currentTask.contents {
  | Some(task) => task.id == taskId
  | None => false
  }

  if shouldComplete {
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
  let shouldAbort = switch currentTask.contents {
  | Some(task) => task.id == taskId
  | None => false
  }

  if shouldAbort {
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

    // Dispatch FSM abort event to update UI state
    GlobalStateBridge.dispatch(Actions.DispatchNavigationFsmEvent(Aborted))
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
