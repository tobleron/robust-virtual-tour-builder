/* src/systems/Scene/SceneTransition.res */

open ReBindings
open Types
open Actions

type viewport = ViewerSystem.Pool.viewport

type getStateFn = unit => state

let finalizeSwap = (~getState) => {
  ViewerSystem.getActiveViewer()
  ->Nullable.toOption
  ->Option.forEach(v => {
    if ViewerSystem.isViewerReady(v) {
      let currentState: state = getState()
      if currentState.activeIndex != -1 {
        EventBus.dispatch(ForceHotspotSync)
        HotspotLine.updateLines(
          v,
          currentState,
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

let updateGlobalStateAndViewer = (~getState, nv) => {
  ViewerSystem.Pool.swapActive()
  ViewerSystem.Pool.getActive()->Option.forEach(v => ViewerSystem.Pool.clearCleanupTimeout(v.id))

  assignGlobalViewer(nv)
  clearHotspotLines()

  let _ = Window.setTimeout(() => finalizeSwap(~getState), 50)
}

let updateDomTransitions = (~transition: transition, av, iv) => {
  let isCut = transition.type_ == Cut
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

  // Single-owner completion lifecycle:
  // Cleanup and supervisor completion are tied to the same timer callback
  // so stale timers cannot complete a newer task.
  let resourceCleanupId = Window.setTimeout(() => {
    let shouldFinalize = switch taskId {
    | Some(tid) => NavigationSupervisor.isCurrentTask(tid)
    | None => true
    }
    if !shouldFinalize {
      ViewerSystem.Pool.clearCleanupTimeout(vp.id)
    } else {
      ov->Nullable.toOption->Option.forEach(ViewerSystem.Adapter.destroy)
      ViewerSystem.Pool.clearInstance(vp.containerId)
      ViewerSystem.Pool.clearCleanupTimeout(vp.id)
      switch taskId {
      | Some(tid) => NavigationSupervisor.complete(tid)
      | None => ()
      }
    }
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

let performSwap = (
  loadedScene: scene,
  _loadStartTime,
  ~taskId: option<string>=?,
  ~getState: getStateFn,
  ~dispatch,
  ~transition,
) => {
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
    updateGlobalStateAndViewer(~getState, nv)
    updateDomTransitions(~transition, av, iv)
    scheduleCleanup(ov, ~taskId?)
  | None =>
    Logger.warn(~module_="SceneTransition", ~message="NO_INACTIVE_VIEWER_FOR_SWAP", ())
    // Failsafe: if we don't have a second viewer, we still need to finish the transition
    let activeViewer = ViewerSystem.getActiveViewer()
    if activeViewer->Nullable.toOption->Option.isSome {
      assignGlobalViewer(activeViewer)
    }
    dispatch(SyncSceneNames) // Force some state change
    switch taskId {
    | Some(tid) => NavigationSupervisor.abort(tid)
    | None => ()
    }
  }

  ViewerSnapshot.requestIdleSnapshot()
  ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(loadedScene.id)}

  Logger.debug(~module_="SceneTransition", ~message="SWAP_COMPLETE_FSM_SIGNAL", ())
  dispatch(DispatchNavigationFsmEvent(StabilizeComplete))
}
