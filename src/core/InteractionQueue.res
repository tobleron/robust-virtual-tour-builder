/* src/core/InteractionQueue.res */
// @efficiency-role: core

open Types
open Actions

type queueItem =
  | Action(action)
  | Thunk(unit => Promise.t<unit>)

type state = {
  queue: array<queueItem>,
  isProcessing: bool,
  timerId: option<int>,
}

let internalState = ref({
  queue: [],
  isProcessing: false,
  timerId: None,
})

let stabilityCheckInterval = 50
let maxStabilityWait = 8000

// --- Stability Checks ---

let isNavigationStable = () => {
  let state = GlobalStateBridge.getState()
  switch state.navigationFsm {
  | Idle
  | Preloading(_) => true // Preloading is non-blocking for UI interactions
  | Error(_) => true // Errors are considered stable (we can proceed to recovery)
  | Transitioning(_)
  | Stabilizing(_) => false
  }
}

let isUiStable = () => {
  // Check if the global processing UI is visible
  let processingUi = ReBindings.Dom.getElementById("processing-ui")->Nullable.toOption
  switch processingUi {
  | Some(el) =>
    let classList = ReBindings.Dom.classList(el)
    // If it has 'hidden' class, it is stable. If not, it's busy.
    // Note: The logic in ViewerFollow.res implies !hidden == busy.
    classList->ReBindings.Dom.ClassList.contains("hidden")
  | None => true // If UI element is missing, assume stable
  }
}

let isAppStable = () => {
  isNavigationStable() && isUiStable()
}

// --- Queue Processing ---

let rec waitForStability = (startTime: float): Promise.t<unit> => {
  if isAppStable() {
    Promise.resolve()
  } else {
    let elapsed = Date.now() -. startTime
    if elapsed > Belt.Float.fromInt(maxStabilityWait) {
      Logger.warn(
        ~module_="InteractionQueue",
        ~message="STABILITY_TIMEOUT",
        ~data=Logger.castToJson({
          "elapsed": elapsed,
          "navStable": isNavigationStable(),
          "uiStable": isUiStable(),
          "fsmState": switch GlobalStateBridge.getState().navigationFsm {
          | Idle => "Idle"
          | Preloading(_) => "Preloading"
          | Transitioning(_) => "Transitioning"
          | Stabilizing(_) => "Stabilizing"
          | Error(_) => "Error"
          },
        }),
        (),
      )
      // Force release lock by resolving, effectively ignoring the unstable state
      Promise.resolve()
    } else {
      Promise.make((resolve, _) => {
        let _ = setTimeout(() => {
          waitForStability(startTime)
          ->Promise.then(
            () => {
              resolve()
              Promise.resolve()
            },
          )
          ->ignore
        }, stabilityCheckInterval)
      })
    }
  }
}

let rec processNext = () => {
  let {queue} = internalState.contents
  switch queue[0] {
  | None =>
    internalState.contents = {...internalState.contents, isProcessing: false}
    Logger.debug(~module_="InteractionQueue", ~message="QUEUE_DRAINED", ())
  | Some(item) =>
    internalState.contents = {
      ...internalState.contents,
      isProcessing: true,
      queue: Array.slice(queue, ~start=1),
    }

    let executionPromise = switch item {
    | Action(action) =>
      Logger.debug(
        ~module_="InteractionQueue",
        ~message="PROCESS_ACTION",
        ~data=Logger.castToJson({"action": Actions.actionToString(action)}),
        (),
      )
      GlobalStateBridge.dispatch(action)
      // After dispatch, we must wait for the side effects to "settle"
      // We wait a tick first to allow React/Reducers to update state
      Promise.make((resolve, _) => {
        let _ = setTimeout(() => resolve(), 0)
      })->Promise.then(() => waitForStability(Date.now()))

    | Thunk(fn) =>
      Logger.debug(~module_="InteractionQueue", ~message="PROCESS_THUNK", ())
      fn()->Promise.then(() => waitForStability(Date.now()))
    }

    executionPromise
    ->Promise.then(() => {
      processNext()
      Promise.resolve()
    })
    ->ignore
  }
}

let enqueue = (item: queueItem) => {
  internalState.contents = {
    ...internalState.contents,
    queue: Array.concat(internalState.contents.queue, [item]),
  }
  Logger.debug(
    ~module_="InteractionQueue",
    ~message="ENQUEUE",
    ~data=Logger.castToJson({
      "queueLength": Array.length(internalState.contents.queue),
      "isProcessing": internalState.contents.isProcessing,
    }),
    (),
  )

  if !internalState.contents.isProcessing {
    processNext()
  }
}

// Helper to wrap standard dispatch
let dispatch = (action: action) => {
  enqueue(Action(action))
}
