open Types

let handleAddToAutoForwardChain = (state: state, idx: int): state => {
  let chain = state.navigationState.autoForwardChain
  if !Array.includes(chain, idx) {
    {
      ...state,
      navigationState: {
        ...state.navigationState,
        autoForwardChain: Belt.Array.concat(chain, [idx]),
      },
    }
  } else {
    state
  }
}

let handleNavigationCompleted = (state: state, journey: journeyData): state => {
  if journey.journeyId == state.navigationState.currentJourneyId {
    let nextJourneyId = state.navigationState.currentJourneyId + 1
    let baseNavState = {
      ...state.navigationState,
      navigation: Idle,
      autoForwardChain: [],
      currentJourneyId: nextJourneyId,
    }

    if journey.previewOnly {
      {
        ...state,
        navigationState: {...baseNavState, incomingLink: None},
      }
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
        navigationState: {
          ...baseNavState,
          incomingLink: Some(incomingLinkVal),
        },
        activeIndex: journey.targetIndex,
        activeYaw: journey.arrivalYaw,
        activePitch: journey.arrivalPitch,
        transition,
        isLinking: false,
        linkDraft: None,
      }
    }
  } else {
    state
  }
}

let handleDispatchNavigationFsmEvent = (state: state, event: NavigationFSM.event): state => {
  let nextFsmState = NavigationFSM.reducer(state.navigationState.navigationFsm, event)
  if nextFsmState != state.navigationState.navigationFsm {
    {
      ...state,
      navigationState: {...state.navigationState, navigationFsm: nextFsmState},
    }
  } else {
    state
  }
}
