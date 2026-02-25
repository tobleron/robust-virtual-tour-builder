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
    let njid = state.navigationState.currentJourneyId + 1
    let currView = NavigationGraph.getCurrentView()
    let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
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

      scenes[targetIdx]->Option.forEach(ts => {
        // Call Supervisor to manage navigation lifecycle and dispatch FSM event
        NavigationSupervisor.requestNavigation(ts.id, ~previewOnly)
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
      let (ay, ap, _) = NavigationGraph.calculateSmartArrivalTarget(scenes, targetIdx)
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
      scenes[targetIdx]->Option.forEach(ts => {
        // Call Supervisor to manage navigation lifecycle and dispatch FSM event
        NavigationSupervisor.requestNavigation(ts.id)
      })
    }
    dispatch(Batch(actions))
    Promise.resolve()
  }

  switch InteractionGuard.attempt("scene_navigation", InteractionPolicies.sceneNavigation, action) {
  | Ok(_) => ()
  | Error(_) =>
    NotificationManager.dispatch({
      id: "",
      importance: Warning,
      context: Operation("scene_switcher"),
      message: "Switching too fast...",
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Warning),
      dismissible: true,
      createdAt: Date.now(),
    })
  }
}

let handleAutoForward = (dispatch, state: state, currentScene: scene) => {
  if state.simulation.status != Running && !state.isLinking {
    // 1. Explicitly marked hotspot (New precise logic)
    let explicitHotspot =
      currentScene.hotspots->Belt.Array.getBy(h => h.isAutoForward == Some(true))

    // 2. Fallback to first link if scene belongs to legacy auto-forward chain
    let fallbackHotspot = if currentScene.isAutoForward {
      currentScene.hotspots->Belt.Array.get(0)
    } else {
      None
    }

    let targetHotspot = explicitHotspot->Option.orElse(fallbackHotspot)

    targetHotspot->Option.forEach(h => {
      let chain = state.navigationState.autoForwardChain
      if Array.length(chain) == 0 {
        state.navigationState.incomingLink->Option.forEach(l =>
          dispatch(Actions.AddToAutoForwardChain(l.sceneIndex))
        )
      }

      if Array.includes(chain, state.activeIndex) {
        dispatch(ResetAutoForwardChain)
      } else {
        dispatch(AddToAutoForwardChain(state.activeIndex))
        HotspotTarget.resolveSceneIndex(
          SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
          h,
        )->Option.forEach(tIdx => {
          let hIdx =
            currentScene.hotspots
            ->Belt.Array.getIndexBy(hh => hh.linkId == h.linkId)
            ->Option.getOr(0)
          navigateToScene(dispatch, state, tIdx, state.activeIndex, hIdx, ())
        })
      }
    })
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
    let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    scenes[state.activeIndex]->Option.forEach(s => handleAutoForward(dispatch, state, s))
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
