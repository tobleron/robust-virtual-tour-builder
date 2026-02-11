/* src/core/NavigationState.res
   Navigation domain slice - extracted from monolithic state
   Handles all navigation-related state: FSM, journey tracking, forward chain
*/

open Types
open Actions

// ============================================================================
// INITIALIZER
// ============================================================================

let initial = (): navigationState => {
  {
    navigationFsm: IdleFsm,
    navigation: Idle,
    incomingLink: None,
    autoForwardChain: [],
    currentJourneyId: 0,
  }
}

// ============================================================================
// REDUCER
// ============================================================================

let reduce = (navState: navigationState, action: action): option<navigationState> => {
  switch action {
  // Navigation FSM state transitions
  | SetNavigationFsmState(fsmState) => Some({...navState, navigationFsm: fsmState})

  // Navigation FSM event dispatch (handled by NavigationFSM module)
  | DispatchNavigationFsmEvent(event) =>
    let nextFsmState = NavigationFSM.reducer(navState.navigationFsm, event)
    Some({...navState, navigationFsm: nextFsmState})

  // Navigation status updates (Idle, Navigating, Previewing)
  | SetNavigationStatus(status) => Some({...navState, navigation: status})

  // Journey tracking
  | IncrementJourneyId => Some({...navState, currentJourneyId: navState.currentJourneyId + 1})

  | SetCurrentJourneyId(id) => Some({...navState, currentJourneyId: id})

  // Link preview
  | SetIncomingLink(link) => Some({...navState, incomingLink: link})

  // Auto-forward chain management
  | ResetAutoForwardChain => Some({...navState, autoForwardChain: []})

  | AddToAutoForwardChain(sceneIndex) =>
    let newChain = Belt.Array.concat(navState.autoForwardChain, [sceneIndex])
    Some({...navState, autoForwardChain: newChain})

  // Navigation completion (reset journey to new ID, clear chain)
  | NavigationCompleted(_journeyData) =>
    Some({
      ...navState,
      autoForwardChain: [],
      incomingLink: None,
      currentJourneyId: navState.currentJourneyId + 1,
      navigation: Idle,
    })

  // Not a navigation action
  | _ => None
  }
}

// ============================================================================
// UTILITIES
// ============================================================================

let isNavigating = (navState: navigationState): bool => {
  switch navState.navigationFsm {
  | IdleFsm => false
  | _ => true
  }
}

let isLoading = (navState: navigationState): bool => {
  switch navState.navigationFsm {
  | Preloading(_) => true
  | _ => false
  }
}

let isTransitioning = (navState: navigationState): bool => {
  switch navState.navigationFsm {
  | Transitioning(_) => true
  | _ => false
  }
}
