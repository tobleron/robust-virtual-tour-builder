/* src/systems/Scene/SceneTransition.res */

open ReBindings
open Types
open Actions

type viewport = ViewerSystem.Pool.viewport

type getStateFn = unit => state

let swapFinalizeRetryMs = 50
let maxSwapFinalizeAttempts = 200

let syncSceneCoupledState = (~viewer, ~state, ~dispatch) => {
  SceneTransitionSupport.syncSceneCoupledState(~viewer, ~state, ~dispatch)
}

let completeSwapTransition = (~getState, ~loadedScene: scene, ~dispatch) => {
  SceneTransitionSupport.completeSwapTransition(~getState, ~loadedScene, ~dispatch)
}

let completeSupervisorTask = (~taskId: option<string>=?) => {
  switch taskId {
  | Some(tid) => NavigationSupervisor.complete(tid)
  | None => ()
  }
}

let rec finalizeSwap = (
  ~getState,
  ~dispatch,
  ~loadedScene: scene,
  ~taskId: option<string>=?,
  ~attempt=0,
) => {
  let shouldFinalize = switch taskId {
  | Some(tid) => NavigationSupervisor.isCurrentTaskId(tid)
  | None => true
  }

  if shouldFinalize {
    switch ViewerSystem.getActiveViewerReadyForScene(loadedScene.id) {
    | Some(v) =>
      let currentState: state = getState()
      syncSceneCoupledState(~viewer=v, ~state=currentState, ~dispatch)
      EventBus.dispatch(ForceHotspotSync)
      HotspotLine.updateLines(
        v,
        currentState,
        ~mouseEvent=?ViewerState.state.contents.lastMouseEvent->Nullable.toOption,
        (),
      )
      completeSwapTransition(~getState, ~loadedScene, ~dispatch)
      completeSupervisorTask(~taskId?)
    | None =>
      if attempt < maxSwapFinalizeAttempts {
        let _ = Window.setTimeout(
          () => finalizeSwap(~getState, ~dispatch, ~loadedScene, ~taskId?, ~attempt=attempt + 1),
          swapFinalizeRetryMs,
        )
      } else {
        Logger.error(
          ~module_="SceneTransition",
          ~message="SWAP_FINALIZE_TIMEOUT",
          ~data=Some({"sceneId": loadedScene.id, "attempts": attempt}),
          (),
        )
        // Fail closed: recover FSM/task but do not emit SimulationAdvanceComplete.
        dispatch(DispatchNavigationFsmEvent(StabilizeComplete))
        completeSupervisorTask(~taskId?)
      }
    }
  }
}

@set external setPannellumViewerOnWindow: ({..}, ReBindings.Viewer.t) => unit = "pannellumViewer"
let assignGlobalViewer = nv => setPannellumViewerOnWindow(Window.window, nv)

let clearHotspotLines = () => {
  Dom.getElementById("viewer-hotspot-lines")
  ->Nullable.toOption
  ->Option.forEach(svg => Dom.setTextContent(svg, ""))
}

let updateGlobalStateAndViewer = (
  ~getState,
  ~dispatch,
  ~loadedScene: scene,
  nv,
  ~taskId: option<string>=?,
) => {
  ViewerSystem.Pool.swapActive()
  ViewerSystem.Pool.getActive()->Option.forEach(v => ViewerSystem.Pool.clearCleanupTimeout(v.id))

  assignGlobalViewer(nv)
  clearHotspotLines()

  let _ = Window.setTimeout(() => finalizeSwap(~getState, ~dispatch, ~loadedScene, ~taskId?), 50)
}

let updateDomTransitions = (~transition: transition, ~isSimulationActive: bool, av, iv) => {
  SceneTransitionSupport.updateDomTransitions(~transition, ~isSimulationActive, av, iv)
}

let cleanupViewerInstance = (ov, vp: viewport, ~taskId: option<string>=?) => {
  let sceneId = switch taskId {
  | Some(_tid) =>
    NavigationSupervisor.getCurrentTask()
    ->Option.map(t => t.targetSceneId)
    ->Option.getOr("unknown")
  | None => "unknown"
  }

  switch taskId {
  | Some(tid) => NavigationSupervisor.transitionTo(tid, Stabilizing(tid, sceneId))
  | None => ()
  }

  // Decoupled completion lifecycle:
  // Task completes via finalizeSwap (~50ms), but resource cleanup happens here (~500ms).
  // Cancellation is handled by ViewerPool via clearCleanupTimeout.
  let resourceCleanupId = Window.setTimeout(() => {
    ov->Nullable.toOption->Option.forEach(ViewerSystem.Adapter.destroy)
    ViewerSystem.Pool.clearInstance(vp.containerId)
    ViewerSystem.Pool.clearCleanupTimeout(vp.id)
  }, 500)

  // Register the resource cleanup task so it can be cancelled
  ViewerSystem.Pool.setCleanupTimeout(vp.id, Some(resourceCleanupId))
}

let cleanupSnapshotOverlay = () => {
  Dom.getElementById("viewer-snapshot-overlay")
  ->Nullable.toOption
  ->Option.forEach(s => {
    Dom.remove(s, "snapshot-visible")
    let _ = Window.setTimeout(() => {
      if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
        Dom.setBackgroundImage(s, "none")
      }
    }, 450)
  })
}

let scheduleCleanup = (ov, ~taskId: option<string>=?) => {
  let clv = ViewerSystem.Pool.getInactive()
  switch clv {
  | Some(vp) => cleanupViewerInstance(ov, vp, ~taskId?)
  | None => ()
  }
  cleanupSnapshotOverlay()
}

let maxSwapRetries = 3
let noInactiveViewerWarnCooldownMs = 5000.0
let lastNoInactiveViewerWarnAt = ref(0.0)

let logNoInactiveViewerFallback = () => {
  SceneTransitionSupport.logNoInactiveViewerFallback(
    ~lastNoInactiveViewerWarnAt,
    ~cooldownMs=noInactiveViewerWarnCooldownMs,
  )
}

let performSwap = (
  loadedScene: scene,
  _loadStartTime,
  ~taskId: option<string>=?,
  ~getState: getStateFn,
  ~dispatch,
  ~transition,
) => {
  let rec attemptSwap = (~retryCount: int) => {
    Logger.debug(
      ~module_="SceneTransition",
      ~message="PERFORM_SWAP",
      ~data=Some({"targetScene": loadedScene.name, "attempt": retryCount + 1}),
      (),
    )

    switch taskId {
    | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, loadedScene.id))
    | None => ()
    }

    let (av, iv) = (ViewerSystem.Pool.getActive(), ViewerSystem.Pool.getInactive())
    let (ov, nv) = (ViewerSystem.getActiveViewer(), ViewerSystem.getInactiveViewer())
    let isActiveViewerTarget = switch Nullable.toOption(ov) {
    | Some(v) => ViewerSystem.isViewerReadyForScene(v, loadedScene.id)
    | None => false
    }

    let firstLoad = isActiveViewerTarget && retryCount == 0

    if firstLoad {
      Logger.debug(~module_="SceneTransition", ~message="INITIAL_SWAP_NO_INACTIVE", ())
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(assignGlobalViewer)
      finalizeSwap(~getState, ~dispatch, ~loadedScene, ~taskId?)
    } else {
      switch Nullable.toOption(nv) {
      | Some(newViewer) =>
        Logger.debug(~module_="SceneTransition", ~message="SWAPPING_VIEWERS", ())
        updateGlobalStateAndViewer(~getState, ~dispatch, ~loadedScene, newViewer, ~taskId?)
        let isSimulationActive = getState().simulation.status == Running
        updateDomTransitions(~transition, ~isSimulationActive, av, iv)
        scheduleCleanup(ov, ~taskId?)
      | None =>
        if retryCount < maxSwapRetries {
          Logger.debug(
            ~module_="SceneTransition",
            ~message="RETRY_SWAP_BECAUSE_NO_INACTIVE_VIEWER",
            ~data=Some({"attempt": retryCount + 1}),
            (),
          )
          let delay = 50 * (retryCount + 1)
          let _ = Window.setTimeout(() => attemptSwap(~retryCount=retryCount + 1), delay)
        } else {
          logNoInactiveViewerFallback()
          ViewerSystem.getActiveViewer()
          ->Nullable.toOption
          ->Option.forEach(assignGlobalViewer)
          dispatch(SyncSceneNames)
          finalizeSwap(~getState, ~dispatch, ~loadedScene, ~taskId?)
        }
      }
    }
  }

  attemptSwap(~retryCount=0)
}
