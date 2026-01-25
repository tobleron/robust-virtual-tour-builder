open ReBindings
open ViewerTypes
open ViewerState

let performSwap = (loadedScene: Types.scene, loadStartTime: float) => {
  let _swapStartTime = Date.now()

  // CRITICAL: Set swap lock FIRST to prevent render loop from drawing during swap
  // This prevents race condition where render loop uses mismatched viewer/state
  state.isSwapping = true

  let inactiveKey = switch state.activeViewerKey {
  | A => B
  | B => A
  }
  let activeContainerId = getActiveContainerId()
  let inactiveContainerId = getInactiveContainerId()

  let activeEl = Dom.getElementById(activeContainerId)
  let inactiveEl = Dom.getElementById(inactiveContainerId)

  let oldViewer = getActiveViewer()
  let newViewer = getInactiveViewer()

  state.activeViewerKey = inactiveKey

  // Clear any existing cleanup timeout for the NEWLY ACTIVE key (v4.7.12)
  switch inactiveKey {
  | A =>
    switch Nullable.toOption(state.cleanupTimeoutA) {
    | Some(t) => Window.clearTimeout(t)
    | None => ()
    }
    state.cleanupTimeoutA = Nullable.null
  | B =>
    switch Nullable.toOption(state.cleanupTimeoutB) {
    | Some(t) => Window.clearTimeout(t)
    | None => ()
    }
    state.cleanupTimeoutB = Nullable.null
  }

  let assignGlobal: Nullable.t<ReBindings.Viewer.t> => unit = %raw(
    "(v) => window.pannellumViewer = v"
  )
  assignGlobal(newViewer)

  // Clear SVG overlay immediately before swap to prevent stale arrows
  // This prevents arrows calculated from old viewer camera data from appearing
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch Nullable.toOption(svgOpt) {
  | Some(svg) => Dom.setTextContent(svg, "")
  | None => ()
  }

  // Delay hotspot line update to ensure new viewer is fully stable
  // This prevents race condition where camera values are read before initialization
  let _ = Window.setTimeout(() => {
    let vOpt = getActiveViewer()
    switch Nullable.toOption(vOpt) {
    | Some(v) =>
      // Only update if viewer is valid AND active (proper camera data)
      if HotspotLine.isViewerReady(v) {
        let mouseEv = switch Nullable.toOption(state.lastMouseEvent) {
        | Some(e) => Some(e)
        | None => None
        }
        HotspotLine.updateLines(v, GlobalStateBridge.getState(), ~mouseEvent=?mouseEv, ())
      }

      // Release swap lock after viewer is ready and lines are updated
      state.isSwapping = false
    | None =>
      // Release lock even if viewer is not available
      state.isSwapping = false
    }
  }, 50)

  /* Transition */
  let isCut = switch GlobalStateBridge.getState().transition.type_ {
  | Some("cut") => true
  | _ => false
  }

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

  /* Cleanup old viewer with tracked timeout to prevent race conditions (v4.7.12) */
  let cleanupKey = switch state.activeViewerKey {
  | A => B
  | B => A
  }

  // Clear any existing cleanup timeout for this key before starting a new one
  switch cleanupKey {
  | A =>
    switch Nullable.toOption(state.cleanupTimeoutA) {
    | Some(t) => Window.clearTimeout(t)
    | None => ()
    }
  | B =>
    switch Nullable.toOption(state.cleanupTimeoutB) {
    | Some(t) => Window.clearTimeout(t)
    | None => ()
    }
  }

  let cleanup = () => {
    switch Nullable.toOption(oldViewer) {
    | Some(v) =>
      PannellumLifecycle.destroyViewer(v)
      switch cleanupKey {
      | A =>
        state.viewerA = Nullable.null
        state.cleanupTimeoutA = Nullable.null
      | B =>
        state.viewerB = Nullable.null
        state.cleanupTimeoutB = Nullable.null
      }
    | None => ()
    }
  }

  let timerId = Window.setTimeout(cleanup, 500)
  switch cleanupKey {
  | A => state.cleanupTimeoutA = Nullable.make(timerId)
  | B => state.cleanupTimeoutB = Nullable.make(timerId)
  }

  /* Snapshot */
  let snapshot = Dom.getElementById("viewer-snapshot-overlay")

  switch Nullable.toOption(snapshot) {
  | Some(s) =>
    // Unified smooth fade-out for snapshots in all modes
    Dom.remove(s, "snapshot-visible")
    let _ = Window.setTimeout(() => {
      if !(Dom.classList(s)->Dom.ClassList.contains("snapshot-visible")) {
        Dom.setBackgroundImage(s, "none")
      }
    }, 450)
  | None => ()
  }

  // Enable snapshot capture during simulation to provide visual continuity for subsequent jumps
  ViewerSnapshot.requestIdleSnapshot()

  state.isSceneLoading = false
  state.loadingSceneId = Nullable.null
  state.lastSceneId = Nullable.make(loadedScene.id)

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
