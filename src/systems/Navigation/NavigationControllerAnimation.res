open Types
open ReBindings

let handleJourneyAnimation = (~journey: journeyData, ~dispatch, ~getState, ~req) => {
  Logger.debug(
    ~module_="NavigationController",
    ~message="START_JOURNEY_ANIMATION",
    ~data=Some({"journeyId": journey.journeyId}),
    (),
  )
  let viewerOpt = ViewerSystem.getActiveViewer()->Nullable.toOption
  Logger.debug(
    ~module_="NavigationController",
    ~message="VIEWER_CHECK_FOR_ANIMATION",
    ~data=Some({
      "journeyId": journey.journeyId,
      "hasViewer": viewerOpt->Option.isSome,
      "hasPathData": journey.pathData->Option.isSome,
    }),
    (),
  )
  viewerOpt->Option.forEach(v => {
    switch journey.pathData {
    | Some(pd) =>
      let currentState = getState()
      let scenes = SceneInventory.getActiveScenes(currentState.inventory, currentState.sceneOrder)
      let targetSceneId = scenes->Belt.Array.get(journey.targetIndex)->Option.map(s => s.id)
      let isBuilder =
        Constants.isDebugBuild() ||
        Option.isSome(currentState.sessionId) ||
        currentState.isLinking ||
        currentState.movingHotspot != None
      let hasAnimated = if isBuilder {
          false
        } else {
          switch targetSceneId {
          | Some(id) => HubScene.hasSceneAnimated(id, currentState)
          | None => false
          }
        }

      if hasAnimated {
        Logger.info(
          ~module_="NavigationController",
          ~message="SCENE_ANIMATION_SKIPPED_REVISIT",
          ~data=Some({"sceneId": targetSceneId->Option.getOr("unknown")}),
          (),
        )
        Viewer.setPitch(v, pd.targetPitchForPan, false)
        Viewer.setYaw(v, pd.targetYawForPan, false)
        dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
      } else {
        Logger.debug(
          ~module_="NavigationController",
          ~message="STARTING_ANIMATION_LOOP",
          ~data=Some({"journeyId": journey.journeyId}),
          (),
        )
        NavigationRenderer.AnimationLoop.startLoop(v, journey, pd, getState, dispatch, req)

        if !isBuilder {
          targetSceneId->Option.forEach(id => dispatch(MarkSceneVisited(id)))
        }
      }
    | None =>
      Logger.warn(~module_="NavigationController", ~message="NO_PATH_DATA_FALLBACK", ())
      dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
    }
  })

  if viewerOpt->Option.isNone {
    Logger.warn(
      ~module_="NavigationController",
      ~message="NO_ACTIVE_VIEWER_FALLBACK",
      ~data=Some({
        "journeyId": journey.journeyId,
        "hasPathData": journey.pathData->Option.isSome,
      }),
      (),
    )
    dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
  }
}
