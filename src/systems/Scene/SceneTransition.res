/* src/systems/Scene/SceneTransition.res */

open ReBindings
open Types
open Actions

external idToUnknown: string => unknown = "%identity"

type viewport = ViewerSystem.Pool.viewport

type getStateFn = unit => state

let syncSceneCoupledState = (~viewer, ~state, ~dispatch) => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let viewerSceneId = Viewer.getScene(viewer)
  let resolvedIndex = activeScenes->Belt.Array.getIndexBy(scene => scene.id == viewerSceneId)

  resolvedIndex->Option.forEach(index => {
    let committedYaw = Viewer.getYaw(viewer)
    let committedPitch = Viewer.getPitch(viewer)

    let needsSceneSync =
      state.activeIndex != index ||
      Math.abs(state.activeYaw -. committedYaw) > 0.01 ||
      Math.abs(state.activePitch -. committedPitch) > 0.01

    if needsSceneSync {
      dispatch(
        SetActiveScene(
          index,
          committedYaw,
          committedPitch,
          Some({type_: Cut, targetHotspotIndex: -1, fromSceneName: None}),
        ),
      )
    }

    let nextTimelineStepId =
      state.timeline
      ->Belt.Array.getBy(step => step.sceneId == viewerSceneId)
      ->Option.map(step => step.id)

    let needsTimelineSync = switch (state.activeTimelineStepId, nextTimelineStepId) {
    | (Some(current), Some(next)) => current != next
    | (None, Some(_)) | (Some(_), None) => true
    | (None, None) => false
    }

    if needsTimelineSync {
      dispatch(SetActiveTimelineStep(nextTimelineStepId))
    }
  })
}

let finalizeSwap = (~getState, ~dispatch, ~taskId: option<string>=?) => {
  let shouldFinalize = switch taskId {
  | Some(tid) => NavigationSupervisor.isCurrentTaskId(tid)
  | None => true
  }

  if shouldFinalize {
    ViewerSystem.getActiveViewer()
    ->Nullable.toOption
    ->Option.forEach(v => {
      if ViewerSystem.isViewerReady(v) {
        let currentState: state = getState()
        syncSceneCoupledState(~viewer=v, ~state=currentState, ~dispatch)
        EventBus.dispatch(ForceHotspotSync)
        HotspotLine.updateLines(
          v,
          currentState,
          ~mouseEvent=?ViewerState.state.contents.lastMouseEvent->Nullable.toOption,
          (),
        )
      }
    })

    switch taskId {
    | Some(tid) => NavigationSupervisor.complete(tid)
    | None => ()
    }
  }
}

let assignGlobalViewer = nv => {
  let assignGlobal: ReBindings.Viewer.t => unit = %raw("(v) => window.pannellumViewer = v")
  assignGlobal(nv)
}

let clearHotspotLines = () => {
  Dom.getElementById("viewer-hotspot-lines")
  ->Nullable.toOption
  ->Option.forEach(svg => Dom.setTextContent(svg, ""))
}

let updateGlobalStateAndViewer = (~getState, ~dispatch, nv, ~taskId: option<string>=?) => {
  ViewerSystem.Pool.swapActive()
  ViewerSystem.Pool.getActive()->Option.forEach(v => ViewerSystem.Pool.clearCleanupTimeout(v.id))

  assignGlobalViewer(nv)
  clearHotspotLines()

  let _ = Window.setTimeout(() => finalizeSwap(~getState, ~dispatch, ~taskId?), 50)
}

let updateDomTransitions = (~transition: transition, ~isSimulationActive: bool, av, iv) => {
  let isCut = transition.type_ == Cut && !isSimulationActive
  let transitionValue = if isSimulationActive {
    // During simulation/teaser, always enforce a visible crossfade between scenes.
    "opacity 1s ease-in-out"
  } else {
    ""
  }
  switch (av, iv) {
  | (Some(act: viewport), Some(inact: viewport)) =>
    let (actEl, inactEl) = (
      Dom.getElementById(act.containerId),
      Dom.getElementById(inact.containerId),
    )
    switch (actEl->Nullable.toOption, inactEl->Nullable.toOption) {
    | (Some(a), Some(i)) =>
      if isCut {
        Dom.setTransition(a, "none")
        Dom.setTransition(i, "none")
      } else {
        Dom.setTransition(a, transitionValue)
        Dom.setTransition(i, transitionValue)
      }
      Dom.remove(a, "active")
      Dom.add(i, "active")
      if isCut {
        let _ = Window.setTimeout(() => {
          Dom.setTransition(a, "")
          Dom.setTransition(i, "")
        }, 50)
      }
    | _ => ()
    }
  | (None, Some(inact: viewport)) =>
    // Robustness: If no previous active viewport (first load), just activate the new one
    switch Dom.getElementById(inact.containerId)->Nullable.toOption {
    | Some(i) =>
      if !isCut {
        Dom.setTransition(i, transitionValue)
      }
      Dom.add(i, "active")
      if isCut {
        let _ = Window.setTimeout(() => {
          Dom.setTransition(i, "")
        }, 50)
      }
    | None => ()
    }
  | _ => ()
  }
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
  let now = Date.now()
  if now -. lastNoInactiveViewerWarnAt.contents >= noInactiveViewerWarnCooldownMs {
    lastNoInactiveViewerWarnAt := now
    Logger.warn(~module_="SceneTransition", ~message="NO_INACTIVE_VIEWER_FOR_SWAP", ())
  } else {
    Logger.debug(~module_="SceneTransition", ~message="NO_INACTIVE_VIEWER_FOR_SWAP_SUPPRESSED", ())
  }
}

let completeSwapTransition = (~getState, ~loadedScene: scene, ~dispatch) => {
  ViewerSnapshot.requestIdleSnapshot(~getState)
  ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(loadedScene.id)}
  Logger.debug(~module_="SceneTransition", ~message="SWAP_COMPLETE_FSM_SIGNAL", ())
  dispatch(DispatchNavigationFsmEvent(StabilizeComplete))
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
    | Some(v) => ViewerSystem.Adapter.getMetaData(v, "sceneId") == Some(idToUnknown(loadedScene.id))
    | None => false
    }

    let firstLoad = isActiveViewerTarget && retryCount == 0

    if firstLoad {
      Logger.debug(~module_="SceneTransition", ~message="INITIAL_SWAP_NO_INACTIVE", ())
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(assignGlobalViewer)
      completeSwapTransition(~getState, ~loadedScene, ~dispatch)
    } else {
      switch Nullable.toOption(nv) {
      | Some(newViewer) =>
        Logger.debug(~module_="SceneTransition", ~message="SWAPPING_VIEWERS", ())
        updateGlobalStateAndViewer(~getState, ~dispatch, newViewer, ~taskId?)
        let isSimulationActive = getState().simulation.status == Running
        updateDomTransitions(~transition, ~isSimulationActive, av, iv)
        scheduleCleanup(ov, ~taskId?)
        completeSwapTransition(~getState, ~loadedScene, ~dispatch)
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
          finalizeSwap(~getState, ~dispatch, ~taskId?)
          completeSwapTransition(~getState, ~loadedScene, ~dispatch)
        }
      }
    }
  }

  attemptSwap(~retryCount=0)
}
