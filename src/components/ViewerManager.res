/* src/components/ViewerManager.res */

open ReBindings
open ViewerState
open ViewerLoader
open Types

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Initialization (once)
  React.useEffect0(() => {
    let cleanupInput = InputSystem.initInputSystem()
    NavigationRenderer.init() // Legacy init for now

    let handleResize = _ => {
      let v = getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) => HotspotLine.updateLines(viewer, GlobalStateBridge.getState(), ())
      | None => ()
      }
    }
    Window.addEventListener("resize", handleResize)

    // Initialize Guide
    ViewerState.state.guide = Dom.getElementById("cursor-guide")

    let stage = Dom.getElementById("viewer-stage")
    switch Nullable.toOption(stage) {
    | Some(el) =>
      Logger.debug(
        ~module_="ViewerManager",
        ~message="LISTENER_ATTACHED",
        ~data=Some({"element": "viewer-stage"}),
        (),
      )
      Dom.addEventListener(el, "mousemove", InputSystem.handleMouseMove)
      Dom.addEventListenerCapture(el, "pointerdown", LinkEditorLogic.handleStagePointerDown, true)
      Dom.addEventListenerCapture(el, "click", LinkEditorLogic.handleStageClick, true)
    | None => Logger.error(~module_="ViewerManager", ~message="STAGE_NOT_FOUND", ())
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

  // 1. Cleanup when no scenes
  React.useEffect1(() => {
    if Belt.Array.length(state.scenes) == 0 {
      let vA = ViewerState.state.viewerA
      let vB = ViewerState.state.viewerB

      switch Nullable.toOption(vA) {
      | Some(v) =>
        try {Viewer.destroy(v)} catch {
        | _ => ()
        }
      | None => ()
      }
      switch Nullable.toOption(vB) {
      | Some(v) =>
        try {Viewer.destroy(v)} catch {
        | _ => ()
        }
      | None => ()
      }

      ViewerState.state.viewerA = Nullable.null
      ViewerState.state.viewerB = Nullable.null
      ViewerState.state.activeViewerKey = A
      ViewerState.resetState()

      let pA = Dom.getElementById("panorama-a")
      let pB = Dom.getElementById("panorama-b")
      switch Nullable.toOption(pA) {
      | Some(el) => Dom.add(el, "active")
      | None => ()
      }
      switch Nullable.toOption(pB) {
      | Some(el) => Dom.remove(el, "active")
      | None => ()
      }
    }
    None
  }, [Belt.Array.length(state.scenes)])

  // 2. Scene Preloading
  React.useEffect1(() => {
    let preIndex = state.preloadingSceneIndex
    if (
      preIndex != -1 &&
      preIndex != ViewerState.state.lastPreloadingIndex &&
      preIndex != state.activeIndex
    ) {
      ViewerState.state.lastPreloadingIndex = preIndex
      Loader.loadNewScene(Nullable.toOption(ViewerState.state.lastSceneId), Some(preIndex))
    }
    None
  }, [state.preloadingSceneIndex])

  // 3. Main Scene Loading & Hotspot Sync
  React.useEffect3(() => {
    if state.activeIndex != -1 {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(scene) =>
        let lastId = Nullable.toOption(ViewerState.state.lastSceneId)

        // SAFETY FIX: If lastSceneId exists but is not in the current project scenes,
        // it means we switched projects or deleted the scene.
        // We must reset ViewerState to prevent ID collisions, stale reuse, or stuck loading states.
        let isLastIdValid = switch lastId {
        | Some(id) => Belt.Array.some(state.scenes, s => s.id == id)
        | None => true
        }

        if !isLastIdValid {
          Logger.info(~module_="ViewerManager", ~message="PROJECT_CONTEXT_RESET", ())
          let vA = ViewerState.state.viewerA
          let vB = ViewerState.state.viewerB

          switch Nullable.toOption(vA) {
          | Some(v) =>
            try {Viewer.destroy(v)} catch {
            | _ => ()
            }
          | None => ()
          }
          switch Nullable.toOption(vB) {
          | Some(v) =>
            try {Viewer.destroy(v)} catch {
            | _ => ()
            }
          | None => ()
          }

          ViewerState.state.viewerA = Nullable.null
          ViewerState.state.viewerB = Nullable.null
          ViewerState.state.activeViewerKey = A
          ViewerState.resetState()

          let pA = Dom.getElementById("panorama-a")
          let pB = Dom.getElementById("panorama-b")
          switch Nullable.toOption(pA) {
          | Some(el) => Dom.add(el, "active")
          | None => ()
          }
          switch Nullable.toOption(pB) {
          | Some(el) => Dom.remove(el, "active")
          | None => ()
          }
        }

        let currentLastId = Nullable.toOption(ViewerState.state.lastSceneId)
        let hasSceneChanged = switch currentLastId {
        | Some(prev) => prev != scene.id
        | None => true
        }

        if hasSceneChanged {
          Loader.loadNewScene(currentLastId, None)
        } else {
          let v = ViewerState.getActiveViewer()
          switch Nullable.toOption(v) {
          | Some(viewer) =>
            if !state.isLinking {
              // Orientation Sync: Force view position if state changed but scene didn't (e.g. ESC/Stop)
              let currentYaw = Viewer.getYaw(viewer)
              let currentPitch = Viewer.getPitch(viewer)

              if (
                Math.abs(currentYaw -. state.activeYaw) > 0.01 ||
                  Math.abs(currentPitch -. state.activePitch) > 0.01
              ) {
                Viewer.setYaw(viewer, state.activeYaw, false)
                Viewer.setPitch(viewer, state.activePitch, false)
              }

              HotspotManager.syncHotspots(viewer, state, scene, dispatch)
              HotspotLine.updateLines(viewer, state, ())
              Navigation.handleAutoForward(dispatch, state, scene)
            }
          | None => ()
          }
        }
      | None => ()
      }
    }
    None
  }, (
    Belt.Int.toString(state.activeIndex) ++
    "_" ++
    Belt.Int.toString(Belt.Array.length(state.scenes)),
    state.isLinking,
    Float.toString(state.activeYaw) ++ "_" ++ Float.toString(state.activePitch),
  ))

  // 4. Hotspot Sync for Metadata changes (Return links etc)
  React.useEffect2(() => {
    // Only run if we are NOT in linking mode (to avoid wiping the draft lines)
    if state.activeIndex != -1 && !state.isLinking {
      Logger.debug(
        ~module_="ViewerManager",
        ~message="SYNC_EFFECT_TRIGGERED",
        ~data=Some({"reason": "Scenes or Linking State Changed"}),
        (),
      )
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(scene) =>
        let v = ViewerState.getActiveViewer()
        switch Nullable.toOption(v) {
        | Some(viewer) =>
          // We don't trigger auto-forward here, only sync visual hotspots
          HotspotManager.syncHotspots(viewer, state, scene, dispatch)
          HotspotLine.updateLines(viewer, state, ())
        | None => ()
        }
      | None => ()
      }
    }
    None
  }, (state.scenes, state.isLinking))

  // 5. Ratchet State Reset
  React.useEffect1(() => {
    if state.isLinking {
      ViewerState.state.ratchetState.yawOffset = 0.0
      ViewerState.state.ratchetState.pitchOffset = 0.0
      ViewerState.state.ratchetState.maxYawOffset = 0.0
      ViewerState.state.ratchetState.minYawOffset = 0.0
      ViewerState.state.ratchetState.maxPitchOffset = 0.0
      ViewerState.state.ratchetState.minPitchOffset = 0.0

      if !ViewerState.state.followLoopActive {
        ViewerState.state.followLoopActive = true
        ViewerFollow.updateFollowLoop()
      }
    }
    None
  }, [state.isLinking])

  // Arrival tracking for Simulation
  React.useEffect2(() => {
    // Replaced legacy simulation check with safe one
    if state.activeIndex != -1 && state.simulation.status == Running {
      ()
    }
    None
  }, (state.activeIndex, state.simulation.status))

  // Sync Linking Cursor & Simulation Class
  React.useEffect3(() => {
    let body = Dom.documentBody
    let guide = Dom.getElementById("cursor-guide")

    if state.isLinking {
      Logger.debug(~module_="ViewerManager", ~message="LINKING_MODE_ON", ())
      Dom.classList(body)->Dom.ClassList.add("linking-mode")
      switch Nullable.toOption(guide) {
      | Some(g) =>
        Dom.setProperty(g, "display", "block")
        Dom.setProperty(g, "z-index", "9999")
        Dom.setLeft(g, "0px")
        Dom.setTop(g, "0px")
      | None => Logger.error(~module_="ViewerManager", ~message="ROD_NOT_FOUND_IN_EFFECT", ())
      }
    } else {
      Dom.classList(body)->Dom.ClassList.remove("linking-mode")
      switch Nullable.toOption(guide) {
      | Some(g) => Dom.setProperty(g, "display", "none")
      | None => ()
      }
    }

    let isSimulationActive = state.simulation.status != Idle

    if isSimulationActive {
      Dom.classList(body)->Dom.ClassList.add("auto-pilot-active")

      // CRITICAL: We no longer clear the SVG overlay here because SvgManager handles it.
      // And we want lines to persist if needed.
      /*
      let svgOpt = Dom.getElementById("viewer-hotspot-lines")
      switch Nullable.toOption(svgOpt) {
      | Some(svg) => Dom.setTextContent(svg, "")
      | None => ()
      }
 */

      // Sync Hotspots immediately to apply hidden-in-sim class
      let v = ViewerState.getActiveViewer()
      switch (Nullable.toOption(v), Belt.Array.get(state.scenes, state.activeIndex)) {
      | (Some(viewer), Some(scene)) =>
        Logger.debug(
          ~module_="ViewerManager",
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
  }, (state.isLinking, state.simulation.status, state.navigation))

  // 7. Render Loop for Hotspot Lines (Fix for sticky waypoints)
  React.useEffect0(() => {
    let animationFrameId = ref(None)
    let lastPitch = ref(-999.0)
    let lastYaw = ref(-999.0)
    let lastHfov = ref(-999.0)

    let rec loop = () => {
      let v = ViewerState.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) =>
        let currentState = GlobalStateBridge.getState()

        // CRITICAL: Skip updates during viewer swap to prevent race condition
        let isSwapping = ViewerState.state.isSwapping

        // Performance optimization: We now ALLOW updates during navigation
        // because SvgManager handles retained mode and prevents layout thrashing.
        // We only skip if swapping scenes.

        if !isSwapping {
          let p = Viewer.getPitch(viewer)
          let y = Viewer.getYaw(viewer)
          let h = Viewer.getHfov(viewer)

          // Always update if we are not swapping, to ensure smooth tracking
          lastPitch := p
          lastYaw := y
          lastHfov := h
          HotspotLine.updateLines(viewer, currentState, ())
        }
      | None => ()
      }
      animationFrameId := Some(Window.requestAnimationFrame(loop))
    }

    // Start loop
    animationFrameId := Some(Window.requestAnimationFrame(loop))

    Some(
      () => {
        switch animationFrameId.contents {
        | Some(id) => Window.cancelAnimationFrame(id)
        | None => ()
        }
      },
    )
  })

  React.null
}
