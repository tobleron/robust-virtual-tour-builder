/* src/systems/Scene/SceneSwitcher.res */

open Types
open Actions

let navStartTime = ref(0.0)

let navigateToScene = (
  dispatch,
  state: state,
  targetIdx,
  sourceIdx,
  sourceHIdx,
  ~targetYaw=0.0,
  ~targetPitch=0.0,
  ~targetHfov=Constants.globalHfov,
  ~previewOnly=false,
  (),
) => {
  let action = () => {
    navStartTime := Date.now()
    if (
      state.navigation->(
        s =>
          switch s {
          | Navigating(_) => true
          | _ => false
          }
      )
    ) {
      ()
    } else {
      let njid = state.currentJourneyId + 1
      let currView = NavigationGraph.getCurrentView()
      let actions = []
      let _ = Js.Array.push(Actions.IncrementJourneyId, actions)

      if previewOnly {
        let _ = Js.Array.push(
          SetNavigationStatus(Previewing({sceneIndex: sourceIdx, hotspotIndex: sourceHIdx})),
          actions,
        )
      }

      if state.simulation.status == Running || previewOnly {
        let pd = NavigationGraph.calculatePathData(
          state,
          sourceIdx,
          sourceHIdx,
          targetIdx,
          targetYaw,
          targetPitch,
          targetHfov,
          currView,
        )
        let j: journeyData = {
          journeyId: njid,
          targetIndex: targetIdx,
          sourceIndex: sourceIdx,
          hotspotIndex: sourceHIdx,
          arrivalYaw: pd->Option.map(p => p.arrivalYaw)->Option.getOr(targetYaw),
          arrivalPitch: pd->Option.map(p => p.arrivalPitch)->Option.getOr(targetPitch),
          arrivalHfov: pd->Option.map(p => p.arrivalHfov)->Option.getOr(targetHfov),
          previewOnly,
          pathData: pd,
        }
        let _ = Js.Array.push(SetNavigationStatus(Navigating(j)), actions)

        state.scenes[targetIdx]->Option.forEach(ts => {
          let _ = Js.Array.push(
            DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: ts.id})),
            actions,
          )
        })

        pd->Option.forEach(p =>
          EventBus.dispatch(
            NavStart({
              journeyId: njid,
              targetIndex: targetIdx,
              sourceIndex: sourceIdx,
              hotspotIndex: sourceHIdx,
              previewOnly,
              pathData: p,
            }),
          )
        )
      } else {
        let (ay, ap, _) = NavigationGraph.calculateSmartArrivalTarget(state.scenes, targetIdx)
        let _ = Js.Array.push(
          SetIncomingLink(Some({sceneIndex: sourceIdx, hotspotIndex: sourceHIdx})),
          actions,
        )
        let _ = Js.Array.push(
          SetActiveScene(
            targetIdx,
            ay,
            ap,
            Some({type_: Link, targetHotspotIndex: -1, fromSceneName: None}),
          ),
          actions,
        )
        state.scenes[targetIdx]->Option.forEach(ts => {
          let _ = Js.Array.push(
            DispatchNavigationFsmEvent(UserClickedScene({targetSceneId: ts.id})),
            actions,
          )
        })
      }
      dispatch(Batch(actions))
    }
    Promise.resolve()
  }

  switch InteractionGuard.attempt("scene_navigation", InteractionPolicies.sceneNavigation, action) {
  | Ok(_) => ()
  | Error(_) => EventBus.dispatch(ShowNotification("Switching too fast...", #Warning, None))
  }
}

let handleAutoForward = (dispatch, state: state, currentScene: scene) => {
  if state.simulation.status != Running && currentScene.isAutoForward && !state.isLinking {
    let chain = state.autoForwardChain
    if Array.length(chain) == 0 {
      state.incomingLink->Option.forEach(l => dispatch(Actions.AddToAutoForwardChain(l.sceneIndex)))
    }
    if Array.includes(chain, state.activeIndex) {
      dispatch(ResetAutoForwardChain)
      EventBus.dispatch(ShowNotification("Loop detected", #Warning, None))
    } else {
      dispatch(AddToAutoForwardChain(state.activeIndex))
      currentScene.hotspots
      ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
      ->Option.forEach(h => {
        state.scenes
        ->Belt.Array.getIndexBy(s => s.name == h.target)
        ->Option.forEach(tIdx => {
          let hIdx =
            currentScene.hotspots
            ->Belt.Array.getIndexBy(hh => hh.linkId == h.linkId)
            ->Option.getOr(0)
          navigateToScene(dispatch, state, tIdx, state.activeIndex, hIdx, ())
        })
      })
    }
  }
}

let setSimulationMode = (dispatch, state: state, val) => {
  let actions = [
    SetSimulationMode(val),
    ResetAutoForwardChain,
    SetIncomingLink(None),
    IncrementJourneyId,
    SetNavigationStatus(Idle),
  ]
  EventBus.dispatch(ClearSimUi)
  dispatch(Batch(actions))

  if val && state.activeIndex >= 0 {
    state.scenes[state.activeIndex]->Option.forEach(s => handleAutoForward(dispatch, state, s))
  }
}

let cancelNavigation = () => {
  EventBus.dispatch(NavCancelled)
}

let initNavigation = dispatch => {
  dispatch(
    Batch([
      SetSimulationMode(false),
      SetCurrentJourneyId(0),
      SetNavigationStatus(Idle),
      SetIncomingLink(None),
      ResetAutoForwardChain,
    ]),
  )
  let _ = EventBus.subscribe(e => {
    switch e {
    | NavCompleted(j) => dispatch(NavigationCompleted(j))
    | NavCancelled => dispatch(SetNavigationStatus(Idle))
    | _ => ()
    }
  })
}
