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
      let key = Obj.magic(e)["key"]
      if key == "Escape" {
        if state.isLinking {
          dispatch(Actions.StopLinking)
          EventBus.dispatch(ShowNotification("Link Cancelled", #Info))
        }
      }
    }

    Window.addEventListener("keydown", handleKeyDown)

    // Initialize Guide
    ViewerState.state.guide = Dom.getElementById("cursor-guide")

    // Mouse Move listener for Stage (to track lastMouseEvent and update cursor logic)
    let handleMouseMove = e => {
      ViewerState.state.lastMouseEvent = Nullable.make(e)

      let stage = Dom.getElementById("viewer-stage")
      switch Nullable.toOption(stage) {
      | Some(el) =>
        let rect = Dom.getBoundingClientRect(el)
        let clientX = Belt.Int.toFloat(Obj.magic(e)["clientX"])
        let clientY = Belt.Int.toFloat(Obj.magic(e)["clientY"])

        let x = clientX -. rect.left
        let y = clientY -. rect.top

        ViewerState.state.mouseXNorm = x /. rect.width *. 2.0 -. 1.0
        ViewerState.state.mouseYNorm =
          (y +. Constants.linkingRodHeight) /. rect.height *. 2.0 -. 1.0

        // Update Rod Position (Yellow Vertical Guide)
        let guide = Dom.getElementById("cursor-guide")
        switch Nullable.toOption(guide) {
        | Some(g) =>
          if state.isLinking {
            Dom.setDisplay(g, "block")
            Dom.classList(g)->Dom.ClassList.add("cursor-dot-blinking")
            // Use relative stage coordinates x/y since guide is a child of the stage
            Dom.setLeft(g, Float.toString(Math.round(x)) ++ "px")
            Dom.setTop(g, Float.toString(Math.round(y)) ++ "px")
            // Rod extension length (v4.2.18 behavior)
            Dom.setStyleHeight(g, Float.toString(Constants.linkingRodHeight) ++ "px")

            // Re-enable follow loop for wider waypoints navigation (Stage 2)
            if !ViewerState.state.followLoopActive {
              ViewerState.state.followLoopActive = true
              ViewerFollow.updateFollowLoop()
            }
          } else {
            Dom.setDisplay(g, "none")
            Dom.classList(g)->Dom.ClassList.remove("cursor-dot-blinking")
          }
        | None => ()
        }
      | None => ()
      }
    }

    let handleStageClick = e => {
      // Trace log
      Logger.debug(
        ~module_="ViewerManager",
        ~message="CLICK_DETECTED",
        ~data=Some({
          "eventPhase": if e["eventPhase"] == 1 {
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
            "clientX": Belt.Int.toFloat(Obj.magic(e)["clientX"]),
            "clientY": Belt.Int.toFloat(Obj.magic(e)["clientY"]) +. Constants.linkingRodHeight,
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
                HotspotLine.updateLines(v, mockState, ~mouseEvent=Some(e), ())
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
                HotspotLine.updateLines(v, mockState, ~mouseEvent=Some(e), ())
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
        // Ensure guide is hidden on unmount/cleanup
        let guide = Dom.getElementById("cursor-guide")
        switch Nullable.toOption(guide) {
        | Some(g) => Dom.setDisplay(g, "none")
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

  // State Sync
  React.useEffect1(() => {
    if Belt.Array.length(state.scenes) == 0 {
      /* Cleanup logic */
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
    } else {
      /* Check Link Follow Loop */
      if state.isLinking && !ViewerState.state.followLoopActive {
        // Reset ratchet state to prevent jump from stale mouse position (Stage 2)
        ViewerState.state.ratchetState.yawOffset = 0.0
        ViewerState.state.ratchetState.pitchOffset = 0.0
        ViewerState.state.ratchetState.maxYawOffset = 0.0
        ViewerState.state.ratchetState.minYawOffset = 0.0
        ViewerState.state.ratchetState.maxPitchOffset = 0.0
        ViewerState.state.ratchetState.minPitchOffset = 0.0

        ViewerState.state.followLoopActive = true
        ViewerFollow.updateFollowLoop()
      }

      /* Load Scene */
      let preIndex = state.preloadingSceneIndex
      let isPre =
        preIndex != -1 &&
        preIndex != ViewerState.state.lastPreloadingIndex &&
        preIndex != state.activeIndex

      if isPre {
        ViewerState.state.lastPreloadingIndex = preIndex
        Loader.loadNewScene(Nullable.toOption(ViewerState.state.lastSceneId), Some(preIndex))
      }

      // Rebuild trigger
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(scene) =>
        // Strict ID check for unnecessary reloading
        let lastId = Nullable.toOption(ViewerState.state.lastSceneId)
        let hasSceneChanged = switch lastId {
        | Some(prev) => prev != scene.id
        | None => true // Allow initial load
        }

        if hasSceneChanged {
          Loader.loadNewScene(lastId, None)
        } else {
          let v = ViewerState.getActiveViewer()
          switch Nullable.toOption(v) {
          | Some(viewer) =>
            // CRITICAL: Block hotspot rebuild and auto-forward during linking (Stage 0-4)
            if !state.isLinking {
              HotspotManager.syncHotspots(viewer, state, scene, dispatch)
              Navigation.handleAutoForward(dispatch, state, scene)
            }
          | None => ()
          }
        }
      | None => ()
      }
    }
    None
  }, [state])

  // Arrival tracking for Simulation
  React.useEffect2(() => {
    // Replaced legacy simulation check with safe one
    if state.activeIndex != -1 && state.simulation.status == Running {
      ()
    }
    None
  }, (state.activeIndex, state.simulation.status))

  // Sync Linking Cursor & Simulation Class
  React.useEffect2(() => {
    let body = Dom.documentBody
    if state.isLinking {
      Dom.classList(body)->Dom.ClassList.add("linking-mode")
    } else {
      Dom.classList(body)->Dom.ClassList.remove("linking-mode")
    }

    if state.simulation.status == Running {
      Dom.classList(body)->Dom.ClassList.add("auto-pilot-active")
    } else {
      Dom.classList(body)->Dom.ClassList.remove("auto-pilot-active")
    }
    None
  }, (state.isLinking, state.simulation.status))

  React.null
}
