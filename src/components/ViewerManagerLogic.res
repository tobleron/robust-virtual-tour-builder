/* src/components/ViewerManagerLogic.res */

open ReBindings
open ViewerState
open Types
open Actions

// Hook 1: Initialization
let useInitialization = () => {
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
      Logger.debug(~module_="ViewerManagerLogic", ~message="LISTENER_ATTACHED", ~data=Some({"element": "viewer-stage"}), ())
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

// Hook 2: Scene Cleanup
let useSceneCleanup = (state: state) => {
  React.useEffect1(() => {
    if Belt.Array.length(state.scenes) == 0 {
      ViewerPool.pool->Belt.Array.forEach(vVp => {
        switch vVp.instance {
        | Some(instance) => PannellumAdapter.destroy(instance)
        | None => ()
        }
        vVp.instance = None
      })

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
}

// Hook 3: Preloading
let usePreloading = (state: state, dispatch: action => unit) => {
  React.useEffect1(() => {
    let preIndex = state.preloadingSceneIndex
    if (
      preIndex != -1 &&
      preIndex != ViewerState.state.lastPreloadingIndex &&
      preIndex != state.activeIndex
    ) {
      ViewerState.state.lastPreloadingIndex = preIndex
      switch Belt.Array.get(state.scenes, preIndex) {
      | Some(s) =>
        dispatch(DispatchNavigationFsmEvent(StartAnticipatoryLoad({targetSceneId: s.id})))
      | None => ()
      }
    }
    None
  }, [state.preloadingSceneIndex])
}

// Hook 4: Main Scene Loading
let useMainSceneLoading = (state: state, dispatch: action => unit) => {
  React.useEffect3(() => {
    if state.activeIndex != -1 {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(scene) =>
        let lastId = Nullable.toOption(ViewerState.state.lastSceneId)

        let isLastIdValid = switch lastId {
        | Some(id) => Belt.Array.some(state.scenes, s => s.id == id)
        | None => true
        }

        if !isLastIdValid {
          Logger.info(~module_="ViewerManagerLogic", ~message="PROJECT_CONTEXT_RESET", ())

          ViewerPool.pool->Belt.Array.forEach(vVp => {
            switch vVp.instance {
            | Some(instance) => PannellumAdapter.destroy(instance)
            | None => ()
            }
            vVp.instance = None
          })

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
          Logger.info(
            ~module_="ViewerManagerLogic",
            ~message="SCENE_CHANGE_DETECTED",
            ~data=Some({"targetId": scene.id, "prevId": currentLastId}),
            (),
          )
          dispatch(DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: scene.id})))
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
              SceneSwitcher.handleAutoForward(dispatch, state, scene)
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
}

// Hook 5: Hotspot Sync
let useHotspotSync = (state: state, dispatch: action => unit) => {
  React.useEffect2(() => {
    // Only run if we are NOT in linking mode (to avoid wiping the draft lines)
    if state.activeIndex != -1 && !state.isLinking {
      Logger.debug(
        ~module_="ViewerManagerLogic",
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
}

// Hook 6: Ratchet State
let useRatchetState = (state: state) => {
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
}

// Hook 7: Simulation Arrival
let useSimulationArrival = (state: state) => {
  React.useEffect2(() => {
    if state.activeIndex != -1 && state.simulation.status == Running {
      ()
    }
    None
  }, (state.activeIndex, state.simulation.status))
}

// Hook 8: Linking & Simulation UI
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

    let isSimulationActive = state.simulation.status != Idle

    if isSimulationActive {
      Dom.classList(body)->Dom.ClassList.add("auto-pilot-active")

      // Sync Hotspots immediately to apply hidden-in-sim class
      let v = ViewerState.getActiveViewer()
      switch (Nullable.toOption(v), Belt.Array.get(state.scenes, state.activeIndex)) {
      | (Some(viewer), Some(scene)) =>
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
  }, (state.isLinking, state.simulation.status, state.navigation))
}

// Hook 9: Hotspot Line Render Loop
let useHotspotLineLoop = () => {
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

        if !isSwapping {
          let p = Viewer.getPitch(viewer)
          let y = Viewer.getYaw(viewer)
          let h = Viewer.getHfov(viewer)

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
}
