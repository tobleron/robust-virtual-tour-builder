// @efficiency-role: ui-component

open ReBindings
open Types
open Actions

let useInitialization = () => {
  React.useEffect0(() => {
    let cleanupInput = InputSystem.initInputSystem()

    let handleResize = _ => {
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) => HotspotLine.updateLines(viewer, GlobalStateBridge.getState(), ())
      | None => ()
      }
    }
    Window.addEventListener("resize", handleResize)

    // Initialize Guide
    ViewerState.state := {...ViewerState.state.contents, guide: Dom.getElementById("cursor-guide")}

    let stage = Dom.getElementById("viewer-stage")
    switch Nullable.toOption(stage) {
    | Some(el) =>
      Logger.debug(
        ~module_="ViewerManagerLogic",
        ~message="LISTENER_ATTACHED",
        ~data=Some({"element": "viewer-stage"}),
        (),
      )
      Dom.addEventListener(el, "mousemove", InputSystem.handleMouseMove)
      Dom.addEventListenerCapture(el, "pointerdown", LinkEditorLogic.handleStagePointerDown, true)
      Dom.addEventListenerCapture(el, "click", LinkEditorLogic.handleStageClick, true)
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
          Dom.removeEventListener(el, "mousemove", InputSystem.handleMouseMove)
          Dom.removeEventListenerCapture(
            el,
            "pointerdown",
            LinkEditorLogic.handleStagePointerDown,
            true,
          )
          Dom.removeEventListenerCapture(el, "click", LinkEditorLogic.handleStageClick, true)
        | None => ()
        }
      },
    )
  })
}

let useLinkingAndSimUI = (state: state, dispatch: action => unit) => {
  React.useEffect3(() => {
    let body = Dom.documentBody
    let guide = Dom.getElementById("cursor-guide")

    if state.isLinking {
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
      if !state.isLinking {
        Logger.info(~module_="ViewerManagerLifecycle", ~message="CLEARING_LINK_DRAFT_LINES", ())
      }
      HotspotLine.updateLines(viewer, state, ())
    | None => ()
    }

    let isSimulationActive = state.simulation.status != Idle

    if isSimulationActive {
      Dom.classList(body)->Dom.ClassList.add("auto-pilot-active")

      // Sync Hotspots immediately to apply hidden-in-sim class
      let v = ViewerSystem.getActiveViewer()
      switch (Nullable.toOption(v), Belt.Array.get(state.scenes, state.activeIndex)) {
      | (Some(viewer), Some(scene)) if !TransitionLock.isSwapping() =>
        Logger.debug(
          ~module_="ViewerManagerLogic",
          ~message="SIMULATION_STATE_SYNC",
          ~data=Some({"status": state.simulation.status, "sceneId": scene.id}),
          (),
        )
        HotspotManager.syncHotspots(viewer, state, scene, dispatch)
      | _ => ()
      }
    } else {
      Dom.classList(body)->Dom.ClassList.remove("auto-pilot-active")
    }
    None
  }, (state.isLinking, state.simulation.status, state.navigationState.navigation))
}
