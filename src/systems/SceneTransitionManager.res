/* src/systems/SceneTransitionManager.res */

open ReBindings
open ViewerState

let performSwap = (loadedScene: Types.scene, loadStartTime: float) => {
  let _swapStartTime = Date.now()

  // CRITICAL: Set swap lock FIRST to prevent render loop from drawing during swap
  state.isSwapping = true

  let activeViewport = ViewerPool.getActive()
  let inactiveViewport = ViewerPool.getInactive()

  let oldViewer = getActiveViewer()
  let newViewer = getInactiveViewer()

  // Transition active state in pool
  ViewerPool.swapActive()

  // Clear any existing cleanup timeout for the NEWLY ACTIVE viewport
  switch ViewerPool.getActive() {
  | Some(v) => ViewerPool.clearCleanupTimeout(v.id)
  | None => ()
  }

  let assignGlobal: Nullable.t<ReBindings.Viewer.t> => unit = %raw(
    "(v) => window.pannellumViewer = v"
  )
  assignGlobal(newViewer)

  // Clear SVG overlay immediately before swap to prevent stale arrows
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch Nullable.toOption(svgOpt) {
  | Some(svg) => Dom.setTextContent(svg, "")
  | None => ()
  }

  // Delay hotspot line update to ensure new viewer is fully stable
  let _ = Window.setTimeout(() => {
    let vOpt = getActiveViewer()
    switch Nullable.toOption(vOpt) {
    | Some(v) =>
      if HotspotLine.isViewerReady(v) {
        let mouseEv = switch Nullable.toOption(state.lastMouseEvent) {
        | Some(e) => Some(e)
        | None => None
        }
        HotspotLine.updateLines(v, GlobalStateBridge.getState(), ~mouseEvent=?mouseEv, ())
      }
      state.isSwapping = false
    | None => state.isSwapping = false
    }
  }, 50)

  /* Transition */
  let isCut = switch GlobalStateBridge.getState().transition.type_ {
  | Cut => true
  | _ => false
  }

  switch (activeViewport, inactiveViewport) {
  | (Some(actVp), Some(inactVp)) =>
    let activeEl = Dom.getElementById(actVp.containerId)
    let inactiveEl = Dom.getElementById(inactVp.containerId)

    switch (Nullable.toOption(activeEl), Nullable.toOption(inactiveEl)) {
    | (Some(act), Some(inact)) =>
      if isCut {
        Dom.setTransition(act, "none")
        Dom.setTransition(inact, "none")
      } else {
        Dom.setTransition(act, "")
        Dom.setTransition(inact, "")
      }
      Dom.remove(act, "active")
      Dom.add(inact, "active")

      if isCut {
        let _ = Window.setTimeout(() => {
          Dom.setTransition(act, "")
          Dom.setTransition(inact, "")
        }, 50)
      }
    | _ => ()
    }
  | _ => ()
  }

  /* Cleanup old viewer with tracked timeout */
  let cleanupViewport = ViewerPool.getInactive()

  let cleanup = () => {
    switch (cleanupViewport, Nullable.toOption(oldViewer)) {
    | (Some(vp), Some(v)) =>
      PannellumAdapter.destroy(v)
      ViewerPool.clearInstance(vp.containerId)
      ViewerPool.clearCleanupTimeout(vp.id)
    | _ => ()
    }
  }

  switch cleanupViewport {
  | Some(vp) =>
    let timerId = Window.setTimeout(cleanup, 500)
    ViewerPool.setCleanupTimeout(vp.id, Some(timerId))
  | None => ()
  }

  /* Snapshot */
  let snapshot = Dom.getElementById("viewer-snapshot-overlay")

  switch Nullable.toOption(snapshot) {
  | Some(s) =>
    Dom.remove(s, "snapshot-visible")
    let _ = Window.setTimeout(() => {
      if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
        Dom.setBackgroundImage(s, "none")
      }
    }, 450)
  | None => ()
  }

  ViewerSnapshot.requestIdleSnapshot()

  state.lastSceneId = Nullable.make(loadedScene.id)

  GlobalStateBridge.dispatch(DispatchNavigationFsmEvent(StabilizeComplete))

  Logger.endOperation(
    ~module_="Viewer",
    ~operation="SCENE_LOAD",
    ~data=Some({
      "sceneName": loadedScene.name,
      "durationMs": Date.now() -. loadStartTime,
    }),
    (),
  )
}
