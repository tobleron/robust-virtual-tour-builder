// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

external idToUnknown: string => unknown = "%identity"

// Hook 2: Scene Cleanup
let useSceneCleanup = (state: state) => {
  React.useEffect1(() => {
    if Belt.Array.length(state.scenes) == 0 {
      ViewerSystem.Pool.pool.contents->Belt.Array.forEach(vVp => {
        switch vVp.instance {
        | Some(instance) => ViewerSystem.Adapter.destroy(instance)
        | None => ()
        }
      })
      ViewerSystem.Pool.reset()

      ViewerSystem.resetState()

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
      preIndex != ViewerState.state.contents.lastPreloadingIndex &&
      preIndex != state.activeIndex
    ) {
      ViewerState.state := {...ViewerState.state.contents, lastPreloadingIndex: preIndex}
      switch Belt.Array.get(state.scenes, preIndex) {
      | Some(s) =>
        dispatch(DispatchNavigationFsmEvent(StartAnticipatoryLoad({targetSceneId: s.id})))
      | None => ()
      }
    }
    None
  }, [state.preloadingSceneIndex])
}

let handleMainSceneLoad = (state: state, scene: Types.scene, dispatch: action => unit) => {
  let lastId = Nullable.toOption(ViewerState.state.contents.lastSceneId)

  let isLastIdValid = switch lastId {
  | Some(id) => Belt.Array.some(state.scenes, s => s.id == id)
  | None => true
  }

  if !isLastIdValid {
    Logger.info(~module_="ViewerManagerLogic", ~message="PROJECT_CONTEXT_RESET", ())

    ViewerSystem.Pool.pool.contents->Belt.Array.forEach(vVp => {
      switch vVp.instance {
      | Some(instance) => ViewerSystem.Adapter.destroy(instance)
      | None => ()
      }
    })
    ViewerSystem.Pool.reset()

    ViewerSystem.resetState()

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

  let currentLastId = Nullable.toOption(ViewerState.state.contents.lastSceneId)
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
    let v = ViewerSystem.getActiveViewer()
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
        Scene.Switcher.handleAutoForward(dispatch, state, scene)
      }
    | None => ()
    }
  }
}

// Hook 4: Main Scene Loading
let useMainSceneLoading = (state: state, dispatch: action => unit) => {
  React.useEffect3(() => {
    if state.activeIndex != -1 {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(scene) => handleMainSceneLoad(state, scene, dispatch)
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
  React.useEffect3(() => {
    // Only run if we are NOT in linking mode (to avoid wiping the draft lines)
    if state.activeIndex != -1 && !state.isLinking {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(scene) =>
        let v = ViewerSystem.getActiveViewer()
        switch Nullable.toOption(v) {
        | Some(viewer) =>
          // Robustness: Only sync if the viewer actually belongs to this scene
          let viewerSceneId = ViewerSystem.Adapter.getMetaData(viewer, "sceneId")
          let targetId = idToUnknown(scene.id)

          if viewerSceneId == Some(targetId) {
            Logger.debug(
              ~module_="ViewerManagerLogic",
              ~message="SYNC_HOTSPOTS",
              ~data=Some({"sceneId": scene.id}),
              (),
            )
            HotspotManager.syncHotspots(viewer, state, scene, dispatch)
            HotspotLine.updateLines(viewer, state, ())
          }
        | None => ()
        }
      | None => ()
      }
    }
    None
  }, (state.scenes, state.isLinking, state.activeIndex))
}

// Hook 6: Ratchet State
let useRatchetState = (state: state) => {
  React.useEffect1(() => {
    if state.isLinking {
      ViewerState.state := {
          ...ViewerState.state.contents,
          ratchetState: {
            yawOffset: 0.0,
            pitchOffset: 0.0,
            maxYawOffset: 0.0,
            minYawOffset: 0.0,
            maxPitchOffset: 0.0,
            minPitchOffset: 0.0,
          },
        }

      if !ViewerState.state.contents.followLoopActive {
        ViewerState.state := {...ViewerState.state.contents, followLoopActive: true}
        ViewerSystem.Follow.updateFollowLoop()
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

// Hook 9: Hotspot Line Render Loop
let useHotspotLineLoop = (_state: state, dispatch: action => unit) => {
  React.useEffect0(() => {
    let animationFrameId = ref(None)
    let lastPitch = ref(-999.0)
    let lastYaw = ref(-999.0)
    let lastHfov = ref(-999.0)

    // Handle Forced Sync from EventBus (breaks dependencies)
    let unsub = EventBus.subscribe(e => {
      if e == ForceHotspotSync {
        let v = ViewerSystem.getActiveViewer()
        let currentState = GlobalStateBridge.getState()
        switch (Nullable.toOption(v), Belt.Array.get(currentState.scenes, currentState.activeIndex)) {
        | (Some(viewer), Some(scene)) => HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
        | _ => ()
        }
      }
    })

    let rec loop = () => {
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) =>
        let currentState = GlobalStateBridge.getState()

        // CRITICAL: Skip updates during viewer swap to prevent race condition
        let isSwapping = ViewerState.state.contents.isSwapping

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
        unsub()
        switch animationFrameId.contents {
        | Some(id) => Window.cancelAnimationFrame(id)
        | None => ()
        }
      },
    )
  })
}
