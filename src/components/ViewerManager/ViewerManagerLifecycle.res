// @efficiency-role: ui-component

open ReBindings
open Types
open Actions

let resizeSyncTimeoutId: ref<option<int>> = ref(None)

let updateViewerStateClasses = () => {
  let classes = Dom.classList(Dom.documentBody)
  let clearStateClasses = () => {
    classes->Dom.ClassList.remove("viewer-state-desktop")
    classes->Dom.ClassList.remove("viewer-state-tablet")
    classes->Dom.ClassList.remove("viewer-state-portrait")
    // Compatibility aliases kept for existing CSS/tests.
    classes->Dom.ClassList.remove("viewer-state-4k")
    classes->Dom.ClassList.remove("viewer-state-2k")
    classes->Dom.ClassList.remove("viewer-force-fallback")
  }

  // Builder is intentionally desktop-only to avoid multi-viewport overlay drift.
  clearStateClasses()
  classes->Dom.ClassList.add("viewer-state-desktop")
  classes->Dom.ClassList.add("viewer-state-4k")
}

let computeDynamicStageHfov = (): float => {
  ViewerSystem.getCorrectHfov()
}

let applyDynamicStageHfov = () => {
  let v = ViewerSystem.getActiveViewer()
  updateViewerStateClasses()
  switch Nullable.toOption(v) {
  | Some(viewer) =>
    ViewerSystem.Adapter.resize(viewer)
    ViewerSystem.Adapter.setHfov(viewer, computeDynamicStageHfov(), false)
    // Safety delay to catch post-layout transitions
    let _ = Window.setTimeout(() => {
      ViewerSystem.Adapter.resize(viewer)
    }, 100)
  | None => ()
  }
}

let useInitialization = (~getState, ~dispatch) => {
  React.useEffect0(() => {
    LinkEditorLogic.configure(~getState, ~dispatch)
    let cleanupInput = InputSystem.initInputSystem(~getState, ~dispatch)

    let handleResize = _ => {
      applyDynamicStageHfov()
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) => HotspotLine.updateLines(viewer, getState(), ())
      | None => ()
      }

      resizeSyncTimeoutId.contents->Option.forEach(id => Window.clearTimeout(id))
      let timeoutId = Window.setTimeout(() => {
        applyDynamicStageHfov()
        let settledViewer = ViewerSystem.getActiveViewer()
        switch Nullable.toOption(settledViewer) {
        | Some(viewer) => HotspotLine.updateLines(viewer, getState(), ())
        | None => ()
        }
        resizeSyncTimeoutId := None
      }, 160)
      resizeSyncTimeoutId := Some(timeoutId)
    }
    Window.addEventListener("resize", handleResize)

    // Initialize Guide
    ViewerState.state := {...ViewerState.state.contents, guide: Dom.getElementById("cursor-guide")}

    let moveHandler = e => InputSystem.handleMouseMove(~getState, e)
    let stage = Dom.getElementById("viewer-stage")
    switch Nullable.toOption(stage) {
    | Some(el) =>
      Logger.debug(
        ~module_="ViewerManagerLogic",
        ~message="LISTENER_ATTACHED",
        ~data=Some({"element": "viewer-stage"}),
        (),
      )
      Dom.addEventListener(el, "mousemove", moveHandler)
      Dom.addEventListenerCapture(el, "pointerdown", LinkEditorLogic.handleStagePointerDown, true)
      Dom.addEventListenerCapture(el, "click", LinkEditorLogic.handleStageClick, true)
      applyDynamicStageHfov()
    | None => Logger.error(~module_="ViewerManagerLogic", ~message="STAGE_NOT_FOUND", ())
    }

    Some(
      () => {
        cleanupInput()
        Window.removeEventListener("resize", handleResize)
        // Ensure guide is hidden on unmount/cleanup
        let guide = Dom.getElementById("cursor-guide")
        switch Nullable.toOption(guide) {
        | Some(g) =>
          Dom.setProperty(g, "display", "none")
          Dom.setProperty(g, "transform", "none")
        | None => ()
        }

        switch Nullable.toOption(stage) {
        | Some(el) =>
          Dom.removeEventListener(el, "mousemove", moveHandler)
          Dom.removeEventListenerCapture(
            el,
            "pointerdown",
            LinkEditorLogic.handleStagePointerDown,
            true,
          )
          Dom.removeEventListenerCapture(el, "click", LinkEditorLogic.handleStageClick, true)
        | None => ()
        }
        Dom.classList(Dom.documentBody)->Dom.ClassList.remove("viewer-force-fallback")
        resizeSyncTimeoutId.contents->Option.forEach(id => Window.clearTimeout(id))
        resizeSyncTimeoutId := None
      },
    )
  })
}

let useLinkingAndSimUI = (
  ~isLinking: bool,
  ~simulation: simulationState,
  ~navigationState: navigationState,
  ~scenes: array<scene>,
  ~activeIndex: int,
  ~getState: unit => state,
  ~dispatch: action => unit,
) => {
  React.useEffect3(() => {
    let body = Dom.documentBody
    let guide = Dom.getElementById("cursor-guide")
    let currentState = getState()

    if isLinking {
      Logger.debug(~module_="ViewerManagerLogic", ~message="LINKING_MODE_ON", ())
      Dom.classList(body)->Dom.ClassList.add("linking-mode")
      switch Nullable.toOption(guide) {
      | Some(g) =>
        Dom.setProperty(g, "display", "block")
        Dom.setProperty(g, "z-index", "9999")
        Dom.setLeft(g, "0px")
        Dom.setTop(g, "0px")
      | None => Logger.error(~module_="ViewerManagerLogic", ~message="ROD_NOT_FOUND_IN_EFFECT", ())
      }
    } else {
      Dom.classList(body)->Dom.ClassList.remove("linking-mode")
      switch Nullable.toOption(guide) {
      | Some(g) => Dom.setProperty(g, "display", "none")
      | None => ()
      }
    }

    // Redraw hotspot lines when linking mode changes to immediately clear/show draft lines
    let v = ViewerSystem.getActiveViewer()
    switch Nullable.toOption(v) {
    | Some(viewer) =>
      applyDynamicStageHfov()
      if !isLinking {
        Logger.info(~module_="ViewerManagerLifecycle", ~message="CLEARING_LINK_DRAFT_LINES", ())
      }
      HotspotLine.updateLines(viewer, currentState, ())
    | None => ()
    }

    let isSimulationActive = simulation.status != Idle

    if isSimulationActive {
      Dom.classList(body)->Dom.ClassList.add("auto-pilot-active")

      // Sync Hotspots immediately to apply hidden-in-sim class
      let v = ViewerSystem.getActiveViewer()
      switch (Nullable.toOption(v), Belt.Array.get(scenes, activeIndex)) {
      | (Some(viewer), Some(scene)) if NavigationSupervisor.isIdle() =>
        Logger.debug(
          ~module_="ViewerManagerLogic",
          ~message="SIMULATION_STATE_SYNC",
          ~data=Some({"status": simulation.status, "sceneId": scene.id}),
          (),
        )
        HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
      | _ => ()
      }
    } else {
      Dom.classList(body)->Dom.ClassList.remove("auto-pilot-active")
    }
    None
  }, (isLinking, simulation.status, navigationState.navigation))
}
