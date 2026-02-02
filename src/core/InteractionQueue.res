/* src/core/InteractionQueue.res */
// @efficiency-role: core

open Types
open Actions

type queueItem =
  | Action(action)
  | Thunk(unit => Promise.t<unit>)

type state = {
  mutable queue: array<queueItem>,
  mutable isProcessing: bool,
  mutable timerId: option<int>,
}

let internalState = {
  queue: [],
  isProcessing: false,
  timerId: None,
}

let stabilityCheckInterval = 50
let maxStabilityWait = 2000

// --- Stability Checks ---

let isNavigationStable = () => {
  let state = GlobalStateBridge.getState()
  switch state.navigationFsm {
  | Idle => true
  | Error(_) => true // Errors are considered stable (we can proceed to recovery)
  | Preloading(_)
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
        ~data=Logger.castToJson({"elapsed": elapsed}),
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
  if Belt.Array.length(internalState.queue) == 0 {
    internalState.isProcessing = false
    Logger.debug(~module_="InteractionQueue", ~message="QUEUE_DRAINED", ())
  } else {
    internalState.isProcessing = true
    let item = Array.shift(internalState.queue)

    let executionPromise = switch item {
    | Some(Action(action)) =>
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

    | Some(Thunk(fn)) =>
      Logger.debug(~module_="InteractionQueue", ~message="PROCESS_THUNK", ())
      fn()->Promise.then(() => waitForStability(Date.now()))

    | None => Promise.resolve()
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
  Array.push(internalState.queue, item)
  Logger.debug(
    ~module_="InteractionQueue",
    ~message="ENQUEUE",
    ~data=Logger.castToJson({
      "queueLength": Belt.Array.length(internalState.queue),
      "isProcessing": internalState.isProcessing,
    }),
    (),
  )

  if !internalState.isProcessing {
    processNext()
  }
}

// Helper to wrap standard dispatch
let dispatch = (action: action) => {
  enqueue(Action(action))
}
