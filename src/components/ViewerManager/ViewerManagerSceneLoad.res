// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

let handleMainSceneLoad = (state: state, scene: Types.scene, dispatch: action => unit) => {
  let lastId = Nullable.toOption(ViewerState.state.contents.lastSceneId)

  let isLastIdValid = switch lastId {
  | Some(id) => Belt.Array.some(state.scenes, s => s.id == id)
  | None => true
  }

  if !isLastIdValid {
    Logger.info(~module_="ViewerManagerSceneLoad", ~message="PROJECT_CONTEXT_RESET", ())

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
      ~module_="ViewerManagerSceneLoad",
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
