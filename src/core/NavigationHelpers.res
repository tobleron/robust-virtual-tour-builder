open Types

let handleAddToAutoForwardChain = (state: state, idx: int): state => {
  let chain = state.autoForwardChain
  if !Array.includes(chain, idx) {
    {...state, autoForwardChain: Belt.Array.concat(chain, [idx])}
  } else {
    state
  }
}

let handleNavigationCompleted = (state: state, journey: journeyData): state => {
  if journey.journeyId == state.currentJourneyId {
    if journey.previewOnly {
      {...state, navigation: Idle}
    } else {
      let incomingLinkVal: linkInfo = {
        sceneIndex: journey.sourceIndex,
        hotspotIndex: journey.hotspotIndex,
      }

      let transition = {
        type_: Link,
        targetHotspotIndex: -1,
        fromSceneName: None,
      }
      {
        ...state,
        navigation: Idle,
        incomingLink: Some(incomingLinkVal),
        activeIndex: journey.targetIndex,
        activeYaw: journey.arrivalYaw,
        activePitch: journey.arrivalPitch,
        transition,
      }
    }
  } else {
    state
  }
}

let handleDispatchNavigationFsmEvent = (state: state, event: NavigationFSM.event): state => {
  let nextFsmState = NavigationFSM.reducer(state.navigationFsm, event)
  if nextFsmState != state.navigationFsm {
    {...state, navigationFsm: nextFsmState}
  } else {
    state
  }
}
