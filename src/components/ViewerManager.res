/* src/components/ViewerManager.res */

open ReBindings
open ViewerTypes
open ViewerState
open ViewerLoader
open EventBus
open Types

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Initialization (once)
  React.useEffect0(() => {
    NavigationRenderer.init() // Legacy init for now

    let handleKeyDown = e => {
      let key = Dom.key(e)
      if key == "Escape" {
        if state.isLinking {
          dispatch(Actions.StopLinking)
          EventBus.dispatch(ShowNotification("Link Cancelled", #Info))
        }
      }
    }

    Window.addEventListener("keydown", handleKeyDown)

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

    // Mouse Move listener for Stage (to track lastMouseEvent and update cursor logic)
    let handleMouseMove = e => {
      ViewerState.state.lastMouseEvent = Nullable.make(e)

      let stage = Dom.getElementById("viewer-stage")
      switch Nullable.toOption(stage) {
      | Some(el) =>
        let rect = Dom.getBoundingClientRect(el)
        let clientX = Belt.Int.toFloat(Dom.clientX(e))
        let clientY = Belt.Int.toFloat(Dom.clientY(e))

        let x = clientX -. rect.left
        let y = clientY -. rect.top

        // DEBUG: Track rod coordinates if it's acting up
        // Logger.debug(~module_="ViewerManager", ~message="ROD_POS", ~data=Some({"x": x, "y": y}), ())

        ViewerState.state.mouseXNorm = x /. rect.width *. 2.0 -. 1.0
        ViewerState.state.mouseYNorm =
          (y +. Constants.linkingRodHeight) /. rect.height *. 2.0 -. 1.0

        // Calculate Velocity
        let now = Date.now()
        let dt = (now -. ViewerState.state.lastMoveTime) /. 1000.0 // seconds
        if dt > 0.0 && dt < 0.1 {
          // Only calculate if the time delta is reasonable (e.g., skip big gaps or 0ms)
          let velX = (x -. ViewerState.state.lastMoveX) /. dt
          let velY = (y -. ViewerState.state.lastMoveY) /. dt

          // Apply a bit of smoothing (low-pass filter) to avoid spikes
          let smoothing = 0.7
          ViewerState.state.mouseVelocityX =
            ViewerState.state.mouseVelocityX *. smoothing +. velX *. (1.0 -. smoothing)
          ViewerState.state.mouseVelocityY =
            ViewerState.state.mouseVelocityY *. smoothing +. velY *. (1.0 -. smoothing)
        }

        ViewerState.state.lastMoveX = x
        ViewerState.state.lastMoveY = y
        ViewerState.state.lastMoveTime = now

        // Update Rod Position (Yellow Vertical Guide)
        let guide = Dom.getElementById("cursor-guide")
        let currentState = GlobalStateBridge.getState()

        switch Nullable.toOption(guide) {
        | Some(g) =>
          if currentState.isLinking {
            // Ensure rod is visible and accurately positioned (v4.3.1 fix)
            Dom.setProperty(g, "display", "block")

            // Use transform for more reliable positioning that ignores layout flow

            Dom.setProperty(
              g,
              "transform",
              "translate(" ++
              Float.toString(Math.round(x)) ++
              "px, " ++
              Float.toString(Math.round(y)) ++ "px)",
            )

            // Reset left/top to avoid conflicts with transform

            Dom.setLeft(g, "0px")

            Dom.setTop(g, "0px")

            Dom.setStyleHeight(g, Float.toString(Constants.linkingRodHeight) ++ "px")

            // Re-enable follow loop for wider waypoints navigation (Stage 2)
            if !ViewerState.state.followLoopActive {
              ViewerState.state.followLoopActive = true
              ViewerFollow.updateFollowLoop()
            }
          } else {
            Dom.setProperty(g, "display", "none !important")
            Dom.classList(g)->Dom.ClassList.remove("cursor-dot-blinking")
          }
        | None => ()
        }
      | None => ()
      }
    }

    let handleStageClick = (e: Dom.event) => {
      // Trace log
      Logger.debug(
        ~module_="ViewerManager",
        ~message="CLICK_DETECTED",
        ~data=Some({
          "eventPhase": if Dom.eventPhase(e) == 1 {
            "capture"
          } else {
            "target/bubble"
          },
        }),
        (),
      )

      let currentState = GlobalStateBridge.getState()

      if currentState.isLinking && currentState.simulation.status != Running {
        let viewer = getActiveViewer()

        switch Nullable.toOption(viewer) {
        | Some(v) =>
          // Offset click by linkingRodHeight to match visual tip (v4.2.18 behavior)
          let mockEvent = {
            "clientX": Belt.Int.toFloat(Dom.clientX(e)),
            "clientY": Belt.Int.toFloat(Dom.clientY(e)) +. Constants.linkingRodHeight,
          }
          let coords = Viewer.mouseEventToCoords(v, mockEvent)
          let pitchOpt = Belt.Array.get(coords, 0)
          let yawOpt = Belt.Array.get(coords, 1)

          switch (pitchOpt, yawOpt) {
          | (Some(pitch), Some(yaw)) =>
            // Valid coordinates, prevent default path

            Logger.debug(
              ~module_="ViewerManager",
              ~message="STAGE_CLICK_LINKING",
              ~data=Some({"pitch": pitch, "yaw": yaw}),
              (),
            )

            let draft = currentState.linkDraft

            switch draft {
            | None =>
              let hfov = Viewer.getHfov(v)
              let camPitch = Viewer.getPitch(v)
              let camYaw = Viewer.getYaw(v)

              let initialDraft = {
                yaw,
                pitch,
                camYaw,
                camPitch,
                camHfov: hfov,
                intermediatePoints: None,
              }

              GlobalStateBridge.dispatch(Actions.StartLinking(Some(initialDraft)))

              // Force update lines immediately for the very first click
              switch Nullable.toOption(viewer) {
              | Some(v) =>
                let mockState = {...currentState, linkDraft: Some(initialDraft)}
                HotspotLine.updateLines(v, mockState, ~mouseEvent=e, ())
              | None => ()
              }
            | Some(d) =>
              let currentPoints = switch d.intermediatePoints {
              | Some(pts) => pts
              | None => []
              }
              let camPitch = Viewer.getPitch(v)
              let camYaw = Viewer.getYaw(v)
              let camHfov = Viewer.getHfov(v)

              let newPoint: Types.linkDraft = {
                yaw,
                pitch,
                camYaw,
                camPitch,
                camHfov,
                intermediatePoints: None,
              }

              let newPoints = Belt.Array.concat(currentPoints, [newPoint])

              let updatedDraft = {...d, intermediatePoints: Some(newPoints)}
              GlobalStateBridge.dispatch(Actions.UpdateLinkDraft(updatedDraft))

              // Force update lines immediately
              switch Nullable.toOption(viewer) {
              | Some(v) =>
                // We construct a mock state for immediate feedback since the global state
                // dispatch might take a tick to propagate to the loop
                let mockState = {...currentState, linkDraft: Some(updatedDraft)}
                HotspotLine.updateLines(v, mockState, ~mouseEvent=e, ())
              | None => ()
              }
            }
          | _ => Logger.warn(~module_="ViewerManager", ~message="STAGE_CLICK_INVALID_COORDS", ())
          }
        | None => Logger.warn(~module_="ViewerManager", ~message="NO_ACTIVE_VIEWER", ())
        }
      } else {
        Logger.debug(
          ~module_="ViewerManager",
          ~message="CLICK_IGNORED_STATE",
          ~data=Some({
            "isLinking": currentState.isLinking,
            "simStatus": currentState.simulation.status,
          }),
          (),
        )
      }
    }

    let handleStagePointerDown = e => {
      let currentState = GlobalStateBridge.getState()
      if currentState.isLinking && currentState.simulation.status != Running {
        Logger.debug(
          ~module_="ViewerManager",
          ~message="POINTER_DOWN_CAPTURE",
          ~data=Some({"action": "stopPropagation"}),
          (),
        )
        Dom.stopPropagation(e)
        // We do NOT preventDefault, to allow 'click' to generate
      }
    }

    let stage = Dom.getElementById("viewer-stage")
    switch Nullable.toOption(stage) {
    | Some(el) =>
      Logger.debug(
        ~module_="ViewerManager",
        ~message="LISTENER_ATTACHED",
        ~data=Some({"element": "viewer-stage"}),
        (),
      )
      Dom.addEventListener(el, "mousemove", handleMouseMove)
      Dom.addEventListenerCapture(el, "pointerdown", handleStagePointerDown, true)
      Dom.addEventListenerCapture(el, "click", handleStageClick, true)
    | None => Logger.error(~module_="ViewerManager", ~message="STAGE_NOT_FOUND", ())
    }

    Some(
      () => {
        Window.removeEventListener("keydown", handleKeyDown)
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
          Dom.removeEventListener(el, "mousemove", handleMouseMove)
          Dom.removeEventListenerCapture(el, "pointerdown", handleStagePointerDown, true)
          Dom.removeEventListenerCapture(el, "click", handleStageClick, true)
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
  React.useEffect1(() => {
    if state.activeIndex != -1 && !state.isLinking {
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
  }, [state.scenes])

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
