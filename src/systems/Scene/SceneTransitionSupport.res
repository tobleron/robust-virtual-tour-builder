// @efficiency-role: service-orchestrator

open ReBindings
open Types
open Actions

type viewport = ViewerSystem.Pool.viewport
type getStateFn = unit => state

let syncSceneCoupledState = (~viewer, ~state, ~dispatch) => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  let viewerSceneId = Viewer.getScene(viewer)
  let resolvedIndex = activeScenes->Belt.Array.getIndexBy(scene => scene.id == viewerSceneId)

  resolvedIndex->Option.forEach(index => {
    let committedYaw = Viewer.getYaw(viewer)
    let committedPitch = Viewer.getPitch(viewer)

    let needsSceneSync =
      state.activeIndex != index ||
      Math.abs(state.activeYaw -. committedYaw) > 0.01 ||
      Math.abs(state.activePitch -. committedPitch) > 0.01

    if needsSceneSync {
      dispatch(
        SetActiveScene(
          index,
          committedYaw,
          committedPitch,
          Some({type_: Cut, targetHotspotIndex: -1, fromSceneName: None}),
        ),
      )
    }

    let nextTimelineStepId =
      state.timeline
      ->Belt.Array.getBy(step => step.sceneId == viewerSceneId)
      ->Option.map(step => step.id)

    let needsTimelineSync = switch (state.activeTimelineStepId, nextTimelineStepId) {
    | (Some(current), Some(next)) => current != next
    | (None, Some(_)) | (Some(_), None) => true
    | (None, None) => false
    }

    if needsTimelineSync {
      dispatch(SetActiveTimelineStep(nextTimelineStepId))
    }
  })
}

let completeSwapTransition = (~getState, ~loadedScene: scene, ~dispatch) => {
  ViewerSnapshot.requestIdleSnapshot(~getState)
  ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(loadedScene.id)}
  Logger.debug(~module_="SceneTransition", ~message="SWAP_COMPLETE_FSM_SIGNAL", ())
  dispatch(DispatchNavigationFsmEvent(StabilizeComplete))

  let activeScenes = SceneInventory.getActiveScenes(getState().inventory, getState().sceneOrder)
  let sceneIndex =
    activeScenes->Belt.Array.getIndexBy(s => s.id == loadedScene.id)->Option.getOr(-1)

  Logger.info(
    ~module_="SceneTransition",
    ~message="SIMULATION_ADVANCE_READY",
    ~data=Some({
      "sceneId": loadedScene.id,
      "sceneIndex": sceneIndex,
      "sceneName": loadedScene.name,
    }),
    (),
  )

  if sceneIndex >= 0 {
    EventBus.dispatch(SimulationAdvanceComplete({sceneId: loadedScene.id, sceneIndex}))
  } else {
    Logger.warn(
      ~module_="SceneTransition",
      ~message="SIMULATION_ADVANCE_SCENE_INDEX_NOT_FOUND",
      ~data=Some({"sceneId": loadedScene.id}),
      (),
    )
  }
}

let updateDomTransitions = (~transition: transition, ~isSimulationActive: bool, av, iv) => {
  let isCut = transition.type_ == Cut && !isSimulationActive
  let transitionValue = if isSimulationActive { "opacity 1s ease-in-out" } else { "" }
  switch (av, iv) {
  | (Some(act: viewport), Some(inact: viewport)) =>
    let (actEl, inactEl) = (
      Dom.getElementById(act.containerId),
      Dom.getElementById(inact.containerId),
    )
    switch (actEl->Nullable.toOption, inactEl->Nullable.toOption) {
    | (Some(a), Some(i)) =>
      if isCut {
        Dom.setTransition(a, "none")
        Dom.setTransition(i, "none")
      } else {
        Dom.setTransition(a, transitionValue)
        Dom.setTransition(i, transitionValue)
      }
      Dom.remove(a, "active")
      Dom.add(i, "active")
      if isCut {
        let _ = Window.setTimeout(() => {
          Dom.setTransition(a, "")
          Dom.setTransition(i, "")
        }, 50)
      }
    | _ => ()
    }
  | (None, Some(inact: viewport)) =>
    switch Dom.getElementById(inact.containerId)->Nullable.toOption {
    | Some(i) =>
      if !isCut {
        Dom.setTransition(i, transitionValue)
      }
      Dom.add(i, "active")
      if isCut {
        let _ = Window.setTimeout(() => {
          Dom.setTransition(i, "")
        }, 50)
      }
    | None => ()
    }
  | _ => ()
  }
}

let logNoInactiveViewerFallback = (~lastNoInactiveViewerWarnAt: ref<float>, ~cooldownMs: float) => {
  let now = Date.now()
  if now -. lastNoInactiveViewerWarnAt.contents >= cooldownMs {
    lastNoInactiveViewerWarnAt := now
    Logger.warn(~module_="SceneTransition", ~message="NO_INACTIVE_VIEWER_FOR_SWAP", ())
  } else {
    Logger.debug(~module_="SceneTransition", ~message="NO_INACTIVE_VIEWER_FOR_SWAP_SUPPRESSED", ())
  }
}
