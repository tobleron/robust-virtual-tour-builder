/* src/systems/SceneSwitcher.res */

open Types

/* --- ORCHESTRATION --- */

let navStartTime = ref(0.0)

let navigateToScene = (
  dispatch: Actions.action => unit,
  state: state,
  targetIndex: int,
  sourceSceneIndex: int,
  sourceHotspotIndex: int,
  ~targetYaw: float=0.0,
  ~targetPitch: float=0.0,
  ~targetHfov: float=90.0,
  ~previewOnly: bool=false,
  (),
) => {
  navStartTime := Date.now()
  Logger.startOperation(
    ~module_="SceneSwitcher",
    ~operation="NAV",
    ~data={
      "targetIndex": targetIndex,
      "previewOnly": previewOnly,
    },
    (),
  )
  if (
    switch state.navigation {
    | Navigating(_) => true
    | _ => false
    }
  ) {
    Logger.warn(
      ~module_="SceneSwitcher",
      ~message="NAV_BLOCKED",
      ~data={"reason": "Navigation already in progress"},
      (),
    )
  } else {
    let newJourneyId = state.currentJourneyId + 1
    dispatch(IncrementJourneyId)

    let currentView = NavigationGraph.getCurrentView()

    if previewOnly {
      dispatch(
        SetNavigationStatus(
          Previewing({sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex}),
        ),
      )
    }

    let shouldAnimate = state.simulation.status == Running || previewOnly

    if shouldAnimate {
      let pathData = NavigationGraph.calculatePathData(
        state,
        sourceSceneIndex,
        sourceHotspotIndex,
        targetIndex,
        targetYaw,
        targetPitch,
        targetHfov,
        currentView,
      )

      let journey: journeyData = {
        journeyId: newJourneyId,
        targetIndex,
        sourceIndex: sourceSceneIndex,
        hotspotIndex: sourceHotspotIndex,
        arrivalYaw: targetYaw, // Default if pathData None
        arrivalPitch: targetPitch,
        arrivalHfov: targetHfov,
        previewOnly,
        pathData,
      }

      // If pathData is some, adjust arrival from pathData
      let finalJourney = switch pathData {
      | Some(pd) => {
          ...journey,
          arrivalYaw: pd.arrivalYaw,
          arrivalPitch: pd.arrivalPitch,
          arrivalHfov: pd.arrivalHfov,
        }
      | None => journey
      }

      dispatch(SetNavigationStatus(Navigating(finalJourney)))

      switch Belt.Array.get(state.scenes, targetIndex) {
      | Some(targetScene) =>
        dispatch(DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: targetScene.id})))
      | None => ()
      }

      // Dispatch via typed EventBus
      switch pathData {
      | Some(pd) =>
        let payload: EventBus.navStartPayload = {
          journeyId: newJourneyId,
          targetIndex,
          sourceIndex: sourceSceneIndex,
          hotspotIndex: sourceHotspotIndex,
          previewOnly,
          pathData: pd,
        }
        EventBus.dispatch(NavStart(payload))
      | None => ()
      }
    } else {
      /* Manual Jump */
      let (arrYaw, arrPitch, _arrHfov) = NavigationGraph.calculateSmartArrivalTarget(
        state.scenes,
        targetIndex,
      )

      dispatch(
        SetIncomingLink(Some({sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex})),
      )

      let transition: transition = {
        type_: Link,
        targetHotspotIndex: -1,
        fromSceneName: None,
      }

      dispatch(SetActiveScene(targetIndex, arrYaw, arrPitch, Some(transition)))

      switch Belt.Array.get(state.scenes, targetIndex) {
      | Some(targetScene) =>
        dispatch(DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: targetScene.id})))
      | None => ()
      }

      Logger.endOperation(
        ~module_="SceneSwitcher",
        ~operation="NAV",
        ~data={
          "targetIndex": targetIndex,
          "type": "manual_jump",
          "durationMs": Date.now() -. navStartTime.contents,
        },
        (),
      )
      // In simulation mode, we might need to trigger arrival callback
      // For now, dispathing SetActiveScene should handle it in components
    }
  }
}

let handleAutoForward = (dispatch: Actions.action => unit, state: state, currentScene: scene) => {
  /* Recursion / Logic port from JS */
  if state.simulation.status == Running {
    /* Skipped in Sim Mode */
    ()
  } else if currentScene.isAutoForward {
    if !state.isLinking {
      Logger.debug(
        ~module_="SceneSwitcher",
        ~message="AUTO_FORWARD_CHECK",
        ~data={"sceneName": currentScene.name},
        (),
      )

      /* Chain Logic */
      let chain = state.autoForwardChain
      if Array.length(chain) == 0 {
        switch state.incomingLink {
        | Some(l) => dispatch(AddToAutoForwardChain(l.sceneIndex))
        | None => ()
        }
      }

      if Array.includes(chain, state.activeIndex) {
        Logger.warn(
          ~module_="SceneSwitcher",
          ~message="LOOP_DETECTED",
          ~data={"sceneName": currentScene.name},
          (),
        )
        dispatch(ResetAutoForwardChain)
        EventBus.dispatch(ShowNotification("Loop detected", #Warning))
      } else {
        dispatch(AddToAutoForwardChain(state.activeIndex))

        /* Find best forward link */
        let nextLink = Belt.Array.getBy(currentScene.hotspots, h => {
          switch h.isReturnLink {
          | Some(true) => false
          | _ => true
          }
        })

        switch nextLink {
        | Some(h) =>
          switch Belt.Array.getIndexBy(state.scenes, s => s.name == h.target) {
          | Some(targetIdx) =>
            let hIdx =
              Belt.Array.getIndexBy(currentScene.hotspots, hh =>
                hh.linkId == h.linkId
              )->Belt.Option.getWithDefault(0)

            Logger.info(
              ~module_="SceneSwitcher",
              ~message="AUTO_FORWARD_JUMP",
              ~data={"from": currentScene.name, "to": h.target},
              (),
            )

            // Wait a small delay to allow viewer to stabilize if needed, but JS was immediate
            navigateToScene(dispatch, state, targetIdx, state.activeIndex, hIdx, ())
          | None =>
            Logger.error(
              ~module_="SceneSwitcher",
              ~message="AUTO_FORWARD_FAILED",
              ~data={"reason": "Target not found", "target": h.target},
              (),
            )
          }
        | None =>
          Logger.warn(
            ~module_="SceneSwitcher",
            ~message="AUTO_FORWARD_FAILED",
            ~data={"reason": "No forward link found"},
            (),
          )
        }
      }
    }
  }
}

let setSimulationMode = (dispatch: Actions.action => unit, state: state, val: bool) => {
  dispatch(SetSimulationMode(val))
  Logger.info(
    ~module_="SceneSwitcher",
    ~message="SIMULATION_MODE_CHANGED",
    ~data={"enabled": val},
    (),
  )

  dispatch(ResetAutoForwardChain)
  dispatch(SetIncomingLink(None))
  dispatch(IncrementJourneyId)
  EventBus.dispatch(ClearSimUi)
  dispatch(SetNavigationStatus(Idle))

  if val {
    if state.activeIndex >= 0 {
      /* Timeout 100ms logic */
      let _ = ReBindings.Window.setTimeout(() => {
        switch Belt.Array.get(state.scenes, state.activeIndex) {
        | Some(scene) => handleAutoForward(dispatch, state, scene)
        | None => ()
        }
      }, 100)
    }
  }
}

/* Initialization */

let cancelNavigation = () => {
  Logger.info(~module_="SceneSwitcher", ~message="NAV_CANCELLED", ())
  EventBus.dispatch(NavCancelled)
}

let initNavigation = (dispatch: Actions.action => unit) => {
  dispatch(SetSimulationMode(false))
  dispatch(SetCurrentJourneyId(0))
  dispatch(SetNavigationStatus(Idle))
  dispatch(SetIncomingLink(None))
  dispatch(ResetAutoForwardChain)

  /* Subscribe */
  /* Subscribe via EventBus */
  let _ = EventBus.subscribe(event => {
    switch event {
    | NavCompleted(journey) =>
      dispatch(NavigationCompleted(journey))
      Logger.endOperation(
        ~module_="SceneSwitcher",
        ~operation="NAV",
        ~data={
          "targetIndex": journey.targetIndex,
          "journeyId": journey.journeyId,
          "durationMs": Date.now() -. navStartTime.contents,
        },
        (),
      )
    | NavCancelled =>
      dispatch(SetNavigationStatus(Idle))
      Logger.info(~module_="SceneSwitcher", ~message="NAV_CANCELLED_CLEANUP", ())
    | _ => ()
    }
  })

  Logger.initialized(~module_="SceneSwitcher")
}
