// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

external idToUnknown: string => unknown = "%identity"

// Hook 2: Scene Cleanup
let useSceneCleanup = (~scenes: array<scene>) => {
  React.useEffect1(() => {
    if Belt.Array.length(scenes) == 0 {
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
  }, [Belt.Array.length(scenes)])
}

// Hook 3: Preloading
let usePreloading = (
  ~preloadingSceneIndex: int,
  ~scenes: array<scene>,
  ~activeIndex: int,
  ~dispatch: action => unit,
) => {
  React.useEffect1(() => {
    if (
      preloadingSceneIndex != -1 &&
      preloadingSceneIndex != ViewerState.state.contents.lastPreloadingIndex &&
      preloadingSceneIndex != activeIndex
    ) {
      ViewerState.state := {
          ...ViewerState.state.contents,
          lastPreloadingIndex: preloadingSceneIndex,
        }
      switch Belt.Array.get(scenes, preloadingSceneIndex) {
      | Some(s) =>
        dispatch(DispatchNavigationFsmEvent(StartAnticipatoryLoad({targetSceneId: s.id})))
      | None => ()
      }
    }
    None
  }, [preloadingSceneIndex])
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
    // NOTE: This is a recovery/initialization path, not user-initiated navigation.
    // We dispatch FSM event directly to synchronize viewer state with Redux.
    // This does NOT go through Supervisor to avoid circular dependencies during init.
    dispatch(
      DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: scene.id, previewOnly: false})),
    )
  } else {
    let v = ViewerSystem.getActiveViewer()
    switch Nullable.toOption(v) {
    | Some(viewer) =>
      if !state.isLinking && !(!NavigationSupervisor.isIdle()) {
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
let useMainSceneLoading = (
  ~scenes: array<scene>,
  ~activeIndex: int,
  ~isLinking: bool,
  ~activeYaw: float,
  ~activePitch: float,
  ~getState: unit => state,
  ~dispatch: action => unit,
) => {
  React.useEffect3(() => {
    if activeIndex != -1 {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        let currentState = getState()
        handleMainSceneLoad(currentState, scene, dispatch)
      | None => ()
      }
    }
    None
  }, (
    Belt.Int.toString(activeIndex) ++ "_" ++ Belt.Int.toString(Belt.Array.length(scenes)),
    isLinking,
    Float.toString(activeYaw) ++ "_" ++ Float.toString(activePitch),
  ))
}

// Hook 5: Hotspot Sync
let useHotspotSync = (
  ~scenes: array<scene>,
  ~activeIndex: int,
  ~isLinking: bool,
  ~getState: unit => state,
  ~dispatch: action => unit,
) => {
  React.useEffect3(() => {
    // Only run if we are NOT in linking mode (to avoid wiping the draft lines)
    if activeIndex != -1 && !isLinking && !(!NavigationSupervisor.isIdle()) {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        let v = ViewerSystem.getActiveViewer()
        switch Nullable.toOption(v) {
        | Some(viewer) =>
          // Robustness: Only sync if the viewer actually belongs to this scene
          let viewerSceneId = ViewerSystem.Adapter.getMetaData(viewer, "sceneId")
          let targetId = idToUnknown(scene.id)
          let currentState = getState()

          if viewerSceneId == Some(targetId) {
            Logger.debug(
              ~module_="ViewerManagerLogic",
              ~message="SYNC_HOTSPOTS",
              ~data=Some({"sceneId": scene.id}),
              (),
            )
            HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
            HotspotLine.updateLines(viewer, currentState, ())
          }
        | None => ()
        }
      | None => ()
      }
    }
    None
  }, (scenes, isLinking, activeIndex))
}

// Hook 6: Ratchet State
let useRatchetState = (~isLinking: bool) => {
  React.useEffect1(() => {
    if isLinking {
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
        ViewerSystem.Follow.updateFollowLoop(~getState=AppContext.getBridgeState)
      }
    }
    None
  }, [isLinking])
}

// Hook 7: Simulation Arrival
let useSimulationArrival = (~activeIndex: int, ~simulationStatus: simulationStatus) => {
  React.useEffect2(() => {
    if activeIndex != -1 && simulationStatus == Running {
      ()
    }
    None
  }, (activeIndex, simulationStatus))
}

// Hook 9: Hotspot Line Render Loop
let useHotspotLineLoop = (~getState: unit => state, dispatch: action => unit) => {
  React.useEffect0(() => {
    let animationFrameId = ref(None)
    let lastPitch = ref(-999.0)
    let lastYaw = ref(-999.0)
    let lastHfov = ref(-999.0)

    // Handle Forced Sync from EventBus (breaks dependencies)
    let unsub = EventBus.subscribe(e => {
      switch e {
      | ForceHotspotSync =>
        let _ = Window.requestAnimationFrame(
          _ => {
            let v = ViewerSystem.getActiveViewer()
            let currentState = getState()
            switch (
              Nullable.toOption(v),
              Belt.Array.get(currentState.scenes, currentState.activeIndex),
            ) {
            | (Some(viewer), Some(scene)) =>
              // During forced sync, we allow it even if Stabilizing as long as it's not Loading/Swapping
              let status = NavigationSupervisor.getStatus()
              let isBusy = switch status {
              | Loading(_) | Swapping(_) => true
              | _ => false
              }

              if !isBusy {
                try {
                  HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
                } catch {
                | e =>
                  let (msg, _) = Logger.getErrorDetails(e)
                  Logger.warn(
                    ~module_="ViewerManagerLogic",
                    ~message="FORCE_SYNC_FAILED",
                    ~data=Some({"error": msg}),
                    (),
                  )
                }
              }
            | _ => ()
            }
          },
        )
      | PreviewLinkId(linkId) =>
        let currentState = getState()
        switch Belt.Array.get(currentState.scenes, currentState.activeIndex) {
        | Some(currentScene) =>
          switch Belt.Array.getIndexBy(currentScene.hotspots, h => h.linkId == linkId) {
          | Some(hIdx) =>
            switch currentScene.hotspots[hIdx] {
            | Some(hotspot) =>
              switch HotspotTarget.resolveSceneIndex(currentState.scenes, hotspot) {
              | Some(tIdx) =>
                let (ny, np, nh) = PreviewArrow.Logic.calculateNavParams(hotspot)
                Scene.Switcher.navigateToScene(
                  dispatch,
                  currentState,
                  tIdx,
                  currentState.activeIndex,
                  hIdx,
                  ~targetYaw=ny,
                  ~targetPitch=np,
                  ~targetHfov=nh,
                  ~previewOnly=true,
                  (),
                )
              | None => ()
              }
            | None => ()
            }
          | None => ()
          }
        | None => ()
        }
      | _ => ()
      }
    })

    let rec loop = () => {
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) =>
        let currentState = getState()

        // CRITICAL: Skip updates during viewer swap to prevent race condition

        let status = NavigationSupervisor.getStatus()
        let isCriticalBusy = switch status {
        | Loading(_) | Swapping(_) => true
        | _ => false
        }

        if !isCriticalBusy {
          let p = Viewer.getPitch(viewer)
          let y = Viewer.getYaw(viewer)
          let h = Viewer.getHfov(viewer)

          lastPitch := p
          lastYaw := y
          lastHfov := h
          try {
            HotspotLine.updateLines(viewer, currentState, ())
          } catch {
          | _ => () // Transient error during viewer swap/init is expected
          }
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
// Hook 10: Intro Pan logic
let useIntroPan = (
  ~navigationState: navigationState,
  ~activeIndex: int,
  ~isLinking: bool,
  ~isTeasing: bool,
  ~scenes: array<scene>,
  ~simulationStatus: simulationStatus,
) => {
  let lastPannedSceneId = React.useRef(Nullable.null)

  React.useEffect3(() => {
    let isIdle = navigationState.navigationFsm == IdleFsm

    if isIdle && activeIndex != -1 && !isLinking && !isTeasing {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        if lastPannedSceneId.current != Nullable.make(scene.id) {
          let hotspotsWithWaypoints = scene.hotspots->Belt.Array.keep(h =>
            switch h.waypoints {
            | Some(w) => Array.length(w) > 0
            | None => false
            }
          )

          if Array.length(hotspotsWithWaypoints) == 0 {
            lastPannedSceneId.current = Nullable.make(scene.id)
          } else {
            let v = ViewerSystem.getActiveViewer()
            switch Nullable.toOption(v) {
            | Some(viewer) =>
              if ViewerSystem.isViewerReady(viewer) {
                let targetHotspot =
                  hotspotsWithWaypoints
                  ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
                  ->Option.getOr(hotspotsWithWaypoints->Belt.Array.get(0)->Option.getOrThrow)

                let ty = targetHotspot.startYaw->Option.getOr(targetHotspot.yaw)
                let tp = targetHotspot.startPitch->Option.getOr(targetHotspot.pitch)

                Logger.info(
                  ~module_="ViewerManagerLogic",
                  ~message="INTRO_PAN_TRIGGERED",
                  ~data=Some({"sceneId": scene.id, "targetYaw": ty, "targetPitch": tp}),
                  (),
                )

                lastPannedSceneId.current = Nullable.make(scene.id)

                // Slow, gentle pan (2000ms duration)
                Viewer.setYawWithDuration(viewer, ty, 2000)
                Viewer.setPitchWithDuration(viewer, tp, 2000)
              }
            | None => ()
            }
          }
        }
      | None => ()
      }
    }
    None
  }, (activeIndex, navigationState.navigationFsm, simulationStatus))
}
