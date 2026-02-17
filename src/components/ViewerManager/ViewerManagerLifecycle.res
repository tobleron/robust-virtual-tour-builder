// @efficiency-role: ui-component

open ReBindings
open Types
open Actions

let clamp = (value: float, minValue: float, maxValue: float): float => {
  if value < minValue {
    minValue
  } else if value > maxValue {
    maxValue
  } else {
    value
  }
}

let forceViewerFallback = ref(false)
let resizeSettled = ref(true)
let fallbackSettleTimeoutId: ref<option<int>> = ref(None)

let updateForcedViewerFallbackMode = () => {
  let body = Dom.documentBody
  switch (
    Nullable.toOption(Dom.getElementById("viewer-utility-bar")),
    Nullable.toOption(Dom.getElementById("viewer-floor-nav")),
  ) {
  | (Some(utilityBar), Some(floorNav)) =>
    let utilRect = Dom.getBoundingClientRect(utilityBar)
    let floorRect = Dom.getBoundingClientRect(floorNav)
    let gap = floorRect.top -. utilRect.bottom

    // Enter early before overlap; only exit after resize settles to avoid flicker.
    let shouldEnter = gap <= 36.0
    let canExit = resizeSettled.contents && gap > 60.0

    if shouldEnter && !forceViewerFallback.contents {
      forceViewerFallback := true
      Dom.classList(body)->Dom.ClassList.add("viewer-force-fallback")
    } else if forceViewerFallback.contents && canExit {
      forceViewerFallback := false
      Dom.classList(body)->Dom.ClassList.remove("viewer-force-fallback")
    }
  | _ =>
    if forceViewerFallback.contents {
      forceViewerFallback := false
      Dom.classList(body)->Dom.ClassList.remove("viewer-force-fallback")
    }
  }
}

let startFallbackSettleWindow = () => {
  resizeSettled := false
  fallbackSettleTimeoutId.contents->Option.forEach(id => Window.clearTimeout(id))
  let timeoutId = Window.setTimeout(() => {
    resizeSettled := true
    fallbackSettleTimeoutId := None
    updateForcedViewerFallbackMode()
  }, 220)
  fallbackSettleTimeoutId := Some(timeoutId)
}

let getStageWidth = (): float => {
  switch Nullable.toOption(Dom.getElementById("viewer-stage")) {
  | Some(stageEl) =>
    let rect = Dom.getBoundingClientRect(stageEl)
    if rect.width > 0.0 {
      rect.width
    } else {
      Constants.builderLandscapeMaxWidth
    }
  | None => Constants.builderLandscapeMaxWidth
  }
}

let computeDynamicStageHfov = (): float => {
  let minWidth = Constants.builderLandscapeMinWidth
  let maxWidth = Constants.builderLandscapeMaxWidth
  let width = clamp(getStageWidth(), minWidth, maxWidth)
  let span = maxWidth -. minWidth
  if span <= 0.0 {
    Constants.globalMaxHfov
  } else {
    let progress = (width -. minWidth) /. span
    Constants.globalMinHfov +. (Constants.globalMaxHfov -. Constants.globalMinHfov) *. progress
  }
}

let applyDynamicStageHfov = () => {
  let v = ViewerSystem.getActiveViewer()
  switch Nullable.toOption(v) {
  | Some(viewer) => ViewerSystem.Adapter.setHfov(viewer, computeDynamicStageHfov(), false)
  | None => ()
  }
  updateForcedViewerFallbackMode()
}

let useInitialization = (~getState, ~dispatch) => {
  React.useEffect0(() => {
    LinkEditorLogic.configure(~getState, ~dispatch)
    let cleanupInput = InputSystem.initInputSystem(~getState, ~dispatch)

    let handleResize = _ => {
      startFallbackSettleWindow()
      applyDynamicStageHfov()
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) => HotspotLine.updateLines(viewer, getState(), ())
      | None => ()
      }
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
      updateForcedViewerFallbackMode()
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
        if forceViewerFallback.contents {
          forceViewerFallback := false
          Dom.classList(Dom.documentBody)->Dom.ClassList.remove("viewer-force-fallback")
        }
        fallbackSettleTimeoutId.contents->Option.forEach(id => Window.clearTimeout(id))
        fallbackSettleTimeoutId := None
        resizeSettled := true
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
      updateForcedViewerFallbackMode()
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
