open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | SetSimulationMode(_val) =>
    Some({
      ...state,
      // isSimulationMode: val, // DEPRECATED handled by SimulationReducer
      autoForwardChain: [],
      incomingLink: None,
      currentJourneyId: state.currentJourneyId + 1,
      navigation: Idle,
    })
  | SetNavigationStatus(status) => Some({...state, navigation: status})
  | SetIncomingLink(link) => Some({...state, incomingLink: link})
  | ResetAutoForwardChain => Some({...state, autoForwardChain: []})
  | AddToAutoForwardChain(idx) =>
    let chain = state.autoForwardChain
    if !Array.includes(chain, idx) {
      Some({...state, autoForwardChain: Belt.Array.concat(chain, [idx])})
    } else {
      Some(state)
    }
  | SetPendingReturnSceneName(name) => Some({...state, pendingReturnSceneName: name})
  | IncrementJourneyId => Some({...state, currentJourneyId: state.currentJourneyId + 1})
  | SetCurrentJourneyId(id) => Some({...state, currentJourneyId: id})
  | NavigationCompleted(journey) =>
    if journey.journeyId == state.currentJourneyId {
      if journey.previewOnly {
        Some({...state, navigation: Idle})
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
        Some({
          ...state,
          navigation: Idle,
          incomingLink: Some(incomingLinkVal),
          activeIndex: journey.targetIndex,
          activeYaw: journey.arrivalYaw,
          activePitch: journey.arrivalPitch,
          transition,
        })
      }
    } else {
      Some(state)
    }
  | _ => None
  }
}
