/* src/systems/Scene/SceneTransition.res */

open ReBindings
open Types

type viewport = ViewerSystem.Pool.viewport

let finalizeSwap = () => {
  ViewerSystem.getActiveViewer()
  ->Nullable.toOption
  ->Option.forEach(v => {
    if ViewerSystem.isViewerReady(v) {
      let state = GlobalStateBridge.getState()
      if state.activeIndex != -1 {
        // Break direct dependency on HotspotManager by using EventBus
        EventBus.dispatch(ForceHotspotSync)
        HotspotLine.updateLines(
          v,
          state,
          ~mouseEvent=?ViewerState.state.contents.lastMouseEvent->Nullable.toOption,
          (),
        )
      }
    }
  })
}

let assignGlobalViewer = nv => {
  let assignGlobal: Nullable.t<ReBindings.Viewer.t> => unit = %raw(
    "(v) => window.pannellumViewer = v"
  )
  assignGlobal(nv)
}

let clearHotspotLines = () => {
  Dom.getElementById("viewer-hotspot-lines")
  ->Nullable.toOption
  ->Option.forEach(svg => Dom.setTextContent(svg, ""))
}

let updateGlobalStateAndViewer = nv => {
  ViewerSystem.Pool.swapActive()
  ViewerSystem.Pool.getActive()->Option.forEach(v => ViewerSystem.Pool.clearCleanupTimeout(v.id))

  assignGlobalViewer(nv)
  clearHotspotLines()

  let _ = Window.setTimeout(finalizeSwap, 50)
}

let updateDomTransitions = (av, iv) => {
  let isCut = GlobalStateBridge.getState().transition.type_ == Cut
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
        Dom.setTransition(a, "")
        Dom.setTransition(i, "")
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
        Dom.setTransition(i, "")
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

  // 1. Resource Lifecycle (Cancellable)
  // We schedule the destruction of the viewer but allow it to be cancelled
  // if SceneLoader decides to reuse this instance.
  let resourceCleanupId = Window.setTimeout(() => {
    ov->Nullable.toOption->Option.forEach(ViewerSystem.Adapter.destroy)
    ViewerSystem.Pool.clearInstance(vp.containerId)
    ViewerSystem.Pool.clearCleanupTimeout(vp.id)
  }, 500)

  // Register the resource cleanup task so it can be cancelled
  ViewerSystem.Pool.setCleanupTimeout(vp.id, Some(resourceCleanupId))

  // 2. State Lifecycle (Guaranteed)
  // This runs independently of the resource cleanup. The Supervisor completes the task.
  let _ = Window.setTimeout(() => {
    switch taskId {
    | Some(tid) => NavigationSupervisor.complete(tid)
    | None => ()
    }
  }, 550) // Small buffer to ensure it runs after cleanup if both proceed
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

let performSwap = (loadedScene: scene, _loadStartTime, ~taskId: option<string>=?) => {
  Logger.debug(
    ~module_="SceneTransition",
    ~message="PERFORM_SWAP",
    ~data=Some({"targetScene": loadedScene.name}),
    (),
  )

  switch taskId {
  | Some(tid) => NavigationSupervisor.transitionTo(tid, Swapping(tid, loadedScene.id))
  | None => ()
  }

  let (av, iv) = (ViewerSystem.Pool.getActive(), ViewerSystem.Pool.getInactive())
  let (ov, nv) = (ViewerSystem.getActiveViewer(), ViewerSystem.getInactiveViewer())

  switch Nullable.toOption(nv) {
  | Some(_newViewer) =>
    Logger.debug(~module_="SceneTransition", ~message="SWAPPING_VIEWERS", ())
    updateGlobalStateAndViewer(nv)
    updateDomTransitions(av, iv)
    scheduleCleanup(ov, ~taskId?)
  | None =>
    Logger.warn(~module_="SceneTransition", ~message="NO_INACTIVE_VIEWER_FOR_SWAP", ())
    // Failsafe: if we don't have a second viewer, we still need to finish the transition
    GlobalStateBridge.dispatch(SyncSceneNames) // Force some state change
    switch taskId {
    | Some(tid) => NavigationSupervisor.abort(tid)
    | None => ()
    }
  }

  ViewerSnapshot.requestIdleSnapshot()
  ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(loadedScene.id)}

  Logger.debug(~module_="SceneTransition", ~message="SWAP_COMPLETE_FSM_SIGNAL", ())
  GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(StabilizeComplete))
}
