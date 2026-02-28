// @efficiency-role: ui-component

open ReBindings
open ViewerState
open Types
open Actions

let sceneIdFromMeta: option<unknown> => string = %raw("(meta) => typeof meta === 'string' ? meta : ''")

let handleMainSceneLoad = (
  ~activeScenes: array<scene>,
  state: state,
  scene: Types.scene,
  dispatch: action => unit,
) => {
  let lastId = Nullable.toOption(ViewerState.state.contents.lastSceneId)

  let isLastIdValid = switch lastId {
  | Some(id) => Belt.Array.some(activeScenes, s => s.id == id)
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

    if NavigationSupervisor.isIdle() {
      switch ViewerSystem.getActiveViewer()->Nullable.toOption {
      | Some(activeViewer) =>
        let activeViewerSceneId =
          ViewerSystem.Adapter.getMetaData(activeViewer, "sceneId")->sceneIdFromMeta
        if activeViewerSceneId == "" {
          // Synchronize lastSceneId immediately to prevent infinite dispatch loops in Idle case
          ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(scene.id)}

          // NOTE: This is a recovery/initialization path, not user-initiated navigation.
          dispatch(
            DispatchNavigationFsmEvent(
              UserClickedScene({targetSceneId: scene.id, previewOnly: false}),
            ),
          )
        } else if activeViewerSceneId != scene.id {
          let viewerSceneIndex = activeScenes->Belt.Array.getIndexBy(s => s.id == activeViewerSceneId)
          switch viewerSceneIndex {
          | Some(idx) =>
            ViewerState.state := {
              ...ViewerState.state.contents,
              lastSceneId: Nullable.make(activeViewerSceneId),
            }
            Logger.info(
              ~module_="ViewerManagerSceneLoad",
              ~message="REALIGN_TO_ACTIVE_VIEWER_SCENE",
              ~data=Some({"viewerSceneId": activeViewerSceneId, "viewerSceneIndex": idx}),
              (),
            )
            dispatch(
              SetActiveScene(
                idx,
                Viewer.getYaw(activeViewer),
                Viewer.getPitch(activeViewer),
                Some({type_: Cut, targetHotspotIndex: -1, fromSceneName: None}),
              ),
            )
          | None =>
            // Viewer scene metadata is not represented in state; recover by reloading current state scene.
            ViewerState.state := {
              ...ViewerState.state.contents,
              lastSceneId: Nullable.make(scene.id),
            }
            dispatch(
              DispatchNavigationFsmEvent(
                UserClickedScene({targetSceneId: scene.id, previewOnly: false}),
              ),
            )
          }
        } else {
          // Scene is already loaded in active viewer; keep state in sync without forcing reload.
          ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(scene.id)}
          if (
            Math.abs(state.activeYaw -. Viewer.getYaw(activeViewer)) > 0.01 ||
              Math.abs(state.activePitch -. Viewer.getPitch(activeViewer)) > 0.01
          ) {
            dispatch(
              SetActiveScene(
                state.activeIndex,
                Viewer.getYaw(activeViewer),
                Viewer.getPitch(activeViewer),
                Some({type_: Cut, targetHotspotIndex: -1, fromSceneName: None}),
              ),
            )
          }
        }
      | None =>
        // Synchronize lastSceneId immediately to prevent infinite dispatch loops in Idle case
        ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(scene.id)}

        // NOTE: This is a recovery/initialization path, not user-initiated navigation.
        dispatch(
          DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: scene.id, previewOnly: false})),
        )
      }
    } else {
      let fsm = state.navigationState.navigationFsm
      let isTargeted = switch fsm {
      | Preloading(t) => t.targetSceneId == scene.id
      | Transitioning(t) => t.toSceneId == scene.id
      | Stabilizing(t) => t.targetSceneId == scene.id
      | _ => false
      }

      if isTargeted {
        // Break the loop if we are already transitioning to this scene
        ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(scene.id)}
      } else {
        Logger.debug(
          ~module_="ViewerManagerSceneLoad",
          ~message="BYPASS_SKIPPED_ACTIVE_SUPERVISOR",
          ~data=Some({
            "supervisorStatus": NavigationSupervisor.statusToString(NavigationSupervisor.getStatus()),
            "targetId": scene.id,
            "fsm": NavigationFSM.toString(fsm),
          }),
          (),
        )
      }
    }
  } else {
    let v = ViewerSystem.getActiveViewer()
    switch Nullable.toOption(v) {
    | Some(viewer) =>
      if !(!NavigationSupervisor.isIdle()) {
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
        if !state.isLinking {
          Scene.Switcher.handleAutoForward(dispatch, state, scene)
        }
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
  React.useEffect2(() => {
    if activeIndex != -1 {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        let bridgeState = getState()
        // Guard against bridge lag: use latest render values for linking/pose-sensitive paths.
        let currentState = {
          ...bridgeState,
          activeIndex,
          activeYaw,
          activePitch,
          isLinking,
        }
        handleMainSceneLoad(~activeScenes=scenes, currentState, scene, dispatch)
      | None => ()
      }
    }
    None
  }, (
    Belt.Int.toString(activeIndex) ++ "_" ++ Belt.Int.toString(Belt.Array.length(scenes)),
    Float.toString(activeYaw) ++ "_" ++ Float.toString(activePitch),
  ))
}
