open Types
open Actions

let run = () => {
  Console.log("Running NavigationReducer tests...")

  let initialState = State.initialState

  // Helper to create basic journey data
  let createJourney = (journeyId, targetIndex, sourceIndex, hotspotIndex, previewOnly) => {
    journeyId,
    targetIndex,
    sourceIndex,
    hotspotIndex,
    arrivalYaw: 90.0,
    arrivalPitch: 10.0,
    arrivalHfov: 100.0,
    previewOnly,
    pathData: None,
  }

  // --- Test 1: SetSimulationMode enables simulation mode ---
  Console.log("Test 1: SetSimulationMode enables simulation mode")
  let action = SetSimulationMode(true)
  let result = NavigationReducer.reduce(initialState, action)

  switch result {
  | Some(state) => {
      assert(state.isSimulationMode == true)
      assert(state.autoForwardChain == [])
      assert(state.incomingLink == None)
      assert(state.currentJourneyId == 1) // Incremented from 0
      assert(state.navigation == Idle)
      Console.log("✓ SetSimulationMode enables simulation mode correctly")
    }
  | None => assert(false)
  }

  // --- Test 2: SetSimulationMode disables simulation mode ---
  Console.log("Test 2: SetSimulationMode disables simulation mode")
  let stateWithSimulation = {
    ...initialState,
    isSimulationMode: true,
    autoForwardChain: [1, 2, 3],
    currentJourneyId: 5,
  }
  let actionDisable = SetSimulationMode(false)
  let resultDisable = NavigationReducer.reduce(stateWithSimulation, actionDisable)

  switch resultDisable {
  | Some(state) => {
      assert(state.isSimulationMode == false)
      assert(state.autoForwardChain == [])
      assert(state.currentJourneyId == 6) // Incremented from 5
      Console.log("✓ SetSimulationMode disables simulation mode correctly")
    }
  | None => assert(false)
  }

  // --- Test 3: SetNavigationStatus updates navigation status ---
  Console.log("Test 3: SetNavigationStatus updates navigation status")
  let journey = createJourney(1, 2, 0, 0, false)
  let actionNav = SetNavigationStatus(Navigating(journey))
  let resultNav = NavigationReducer.reduce(initialState, actionNav)

  switch resultNav {
  | Some(state) => switch state.navigation {
    | Navigating(j) => {
        assert(j.journeyId == 1)
        assert(j.targetIndex == 2)
        Console.log("✓ SetNavigationStatus updates to Navigating")
      }
    | _ => assert(false)
    }
  | None => assert(false)
  }

  // --- Test 4: SetNavigationStatus to Idle ---
  Console.log("Test 4: SetNavigationStatus to Idle")
  let stateNavigating = {...initialState, navigation: Navigating(journey)}
  let actionIdle = SetNavigationStatus(Idle)
  let resultIdle = NavigationReducer.reduce(stateNavigating, actionIdle)

  switch resultIdle {
  | Some(state) => {
      assert(state.navigation == Idle)
      Console.log("✓ SetNavigationStatus updates to Idle")
    }
  | None => assert(false)
  }

  // --- Test 5: SetIncomingLink sets incoming link ---
  Console.log("Test 5: SetIncomingLink sets incoming link")
  let linkInfo: linkInfo = {sceneIndex: 3, hotspotIndex: 1}
  let actionLink = SetIncomingLink(Some(linkInfo))
  let resultLink = NavigationReducer.reduce(initialState, actionLink)

  switch resultLink {
  | Some(state) => switch state.incomingLink {
    | Some(link) => {
        assert(link.sceneIndex == 3)
        assert(link.hotspotIndex == 1)
        Console.log("✓ SetIncomingLink sets incoming link correctly")
      }
    | None => assert(false)
    }
  | None => assert(false)
  }

  // --- Test 6: SetIncomingLink clears incoming link ---
  Console.log("Test 6: SetIncomingLink clears incoming link")
  let stateWithLink = {...initialState, incomingLink: Some(linkInfo)}
  let actionClearLink = SetIncomingLink(None)
  let resultClearLink = NavigationReducer.reduce(stateWithLink, actionClearLink)

  switch resultClearLink {
  | Some(state) => {
      assert(state.incomingLink == None)
      Console.log("✓ SetIncomingLink clears incoming link correctly")
    }
  | None => assert(false)
  }

  // --- Test 7: ResetAutoForwardChain clears chain ---
  Console.log("Test 7: ResetAutoForwardChain clears chain")
  let stateWithChain = {...initialState, autoForwardChain: [1, 2, 3, 4]}
  let actionResetChain = ResetAutoForwardChain
  let resultResetChain = NavigationReducer.reduce(stateWithChain, actionResetChain)

  switch resultResetChain {
  | Some(state) => {
      assert(state.autoForwardChain == [])
      Console.log("✓ ResetAutoForwardChain clears chain correctly")
    }
  | None => assert(false)
  }

  // --- Test 8: AddToAutoForwardChain adds new index ---
  Console.log("Test 8: AddToAutoForwardChain adds new index")
  let actionAddChain = AddToAutoForwardChain(5)
  let resultAddChain = NavigationReducer.reduce(initialState, actionAddChain)

  switch resultAddChain {
  | Some(state) => {
      assert(Array.length(state.autoForwardChain) == 1)
      assert(Array.getUnsafe(state.autoForwardChain, 0) == 5)
      Console.log("✓ AddToAutoForwardChain adds new index correctly")
    }
  | None => assert(false)
  }

  // --- Test 9: AddToAutoForwardChain prevents duplicates ---
  Console.log("Test 9: AddToAutoForwardChain prevents duplicates")
  let stateWithChain2 = {...initialState, autoForwardChain: [1, 2, 3]}
  let actionAddDuplicate = AddToAutoForwardChain(2)
  let resultAddDuplicate = NavigationReducer.reduce(stateWithChain2, actionAddDuplicate)

  switch resultAddDuplicate {
  | Some(state) => {
      assert(Array.length(state.autoForwardChain) == 3)
      assert(state.autoForwardChain == [1, 2, 3])
      Console.log("✓ AddToAutoForwardChain prevents duplicates correctly")
    }
  | None => assert(false)
  }

  // --- Test 10: AddToAutoForwardChain appends to existing chain ---
  Console.log("Test 10: AddToAutoForwardChain appends to existing chain")
  let stateWithChain3 = {...initialState, autoForwardChain: [1, 2]}
  let actionAppend = AddToAutoForwardChain(3)
  let resultAppend = NavigationReducer.reduce(stateWithChain3, actionAppend)

  switch resultAppend {
  | Some(state) => {
      assert(Array.length(state.autoForwardChain) == 3)
      assert(Array.getUnsafe(state.autoForwardChain, 2) == 3)
      Console.log("✓ AddToAutoForwardChain appends correctly")
    }
  | None => assert(false)
  }

  // --- Test 11: SetPendingReturnSceneName sets scene name ---
  Console.log("Test 11: SetPendingReturnSceneName sets scene name")
  let actionSetReturn = SetPendingReturnSceneName(Some("scene_5"))
  let resultSetReturn = NavigationReducer.reduce(initialState, actionSetReturn)

  switch resultSetReturn {
  | Some(state) => {
      assert(state.pendingReturnSceneName == Some("scene_5"))
      Console.log("✓ SetPendingReturnSceneName sets scene name correctly")
    }
  | None => assert(false)
  }

  // --- Test 12: SetPendingReturnSceneName clears scene name ---
  Console.log("Test 12: SetPendingReturnSceneName clears scene name")
  let stateWithReturn = {...initialState, pendingReturnSceneName: Some("scene_3")}
  let actionClearReturn = SetPendingReturnSceneName(None)
  let resultClearReturn = NavigationReducer.reduce(stateWithReturn, actionClearReturn)

  switch resultClearReturn {
  | Some(state) => {
      assert(state.pendingReturnSceneName == None)
      Console.log("✓ SetPendingReturnSceneName clears scene name correctly")
    }
  | None => assert(false)
  }

  // --- Test 13: IncrementJourneyId increments ID ---
  Console.log("Test 13: IncrementJourneyId increments ID")
  let stateWithJourney = {...initialState, currentJourneyId: 10}
  let actionIncrement = IncrementJourneyId
  let resultIncrement = NavigationReducer.reduce(stateWithJourney, actionIncrement)

  switch resultIncrement {
  | Some(state) => {
      assert(state.currentJourneyId == 11)
      Console.log("✓ IncrementJourneyId increments ID correctly")
    }
  | None => assert(false)
  }

  // --- Test 14: SetCurrentJourneyId sets specific ID ---
  Console.log("Test 14: SetCurrentJourneyId sets specific ID")
  let actionSetJourney = SetCurrentJourneyId(42)
  let resultSetJourney = NavigationReducer.reduce(initialState, actionSetJourney)

  switch resultSetJourney {
  | Some(state) => {
      assert(state.currentJourneyId == 42)
      Console.log("✓ SetCurrentJourneyId sets ID correctly")
    }
  | None => assert(false)
  }

  // --- Test 15: NavigationCompleted with matching journey ID (preview) ---
  Console.log("Test 15: NavigationCompleted with matching journey ID (preview)")
  let journeyPreview = createJourney(5, 3, 1, 0, true)
  let stateForNav = {...initialState, currentJourneyId: 5, navigation: Navigating(journeyPreview)}
  let actionCompleted = NavigationCompleted(journeyPreview)
  let resultCompleted = NavigationReducer.reduce(stateForNav, actionCompleted)

  switch resultCompleted {
  | Some(state) => {
      assert(state.navigation == Idle)
      // Preview mode should not update activeIndex or incomingLink
      assert(state.activeIndex == -1)
      assert(state.incomingLink == None)
      Console.log("✓ NavigationCompleted with preview mode handled correctly")
    }
  | None => assert(false)
  }

  // --- Test 16: NavigationCompleted with matching journey ID (non-preview) ---
  Console.log("Test 16: NavigationCompleted with matching journey ID (non-preview)")
  let journeyNonPreview = createJourney(7, 4, 2, 1, false)
  let stateForNav2 = {
    ...initialState,
    currentJourneyId: 7,
    navigation: Navigating(journeyNonPreview),
  }
  let actionCompleted2 = NavigationCompleted(journeyNonPreview)
  let resultCompleted2 = NavigationReducer.reduce(stateForNav2, actionCompleted2)

  switch resultCompleted2 {
  | Some(state) => {
      assert(state.navigation == Idle)
      assert(state.activeIndex == 4)
      assert(state.activeYaw == 90.0)
      assert(state.activePitch == 10.0)

      switch state.incomingLink {
      | Some(link) => {
          assert(link.sceneIndex == 2)
          assert(link.hotspotIndex == 1)
          Console.log("✓ NavigationCompleted with non-preview mode handled correctly")
        }
      | None => assert(false)
      }

      switch state.transition.type_ {
      | Some(t) => assert(t == "link")
      | None => assert(false)
      }
    }
  | None => assert(false)
  }

  // --- Test 17: NavigationCompleted with mismatched journey ID ---
  Console.log("Test 17: NavigationCompleted with mismatched journey ID")
  let journeyMismatch = createJourney(10, 5, 3, 2, false)
  let stateForNav3 = {...initialState, currentJourneyId: 15, activeIndex: 2}
  let actionMismatch = NavigationCompleted(journeyMismatch)
  let resultMismatch = NavigationReducer.reduce(stateForNav3, actionMismatch)

  switch resultMismatch {
  | Some(state) => {
      // State should remain unchanged
      assert(state.currentJourneyId == 15)
      assert(state.activeIndex == 2)
      Console.log("✓ NavigationCompleted with mismatched journey ID ignored correctly")
    }
  | None => assert(false)
  }

  // --- Test 18: Unhandled action returns None ---
  Console.log("Test 18: Unhandled action returns None")
  let actionUnhandled = SetTourName("Test")
  let resultUnhandled = NavigationReducer.reduce(initialState, actionUnhandled)

  switch resultUnhandled {
  | None => Console.log("✓ Unhandled action returns None correctly")
  | Some(_) => assert(false)
  }

  // --- Test 19: State immutability ---
  Console.log("Test 19: State immutability")
  let originalState = {...initialState, currentJourneyId: 5, isSimulationMode: false}
  let actionMutate = SetSimulationMode(true)
  let newState = NavigationReducer.reduce(originalState, actionMutate)

  switch newState {
  | Some(state) => {
      assert(originalState.currentJourneyId == 5)
      assert(originalState.isSimulationMode == false)
      assert(state.currentJourneyId == 6)
      assert(state.isSimulationMode == true)
      Console.log("✓ State immutability preserved")
    }
  | None => assert(false)
  }

  // --- Test 20: NavigationCompleted transition field ---
  Console.log("Test 20: NavigationCompleted transition field")
  let journeyTransition = createJourney(8, 6, 4, 2, false)
  let stateForNav4 = {...initialState, currentJourneyId: 8}
  let actionTransition = NavigationCompleted(journeyTransition)
  let resultTransition = NavigationReducer.reduce(stateForNav4, actionTransition)

  switch resultTransition {
  | Some(state) => {
      assert(state.transition.targetHotspotIndex == -1)
      assert(state.transition.fromSceneName == None)
      Console.log("✓ NavigationCompleted transition field set correctly")
    }
  | None => assert(false)
  }

  Console.log("NavigationReducer tests completed.")
}
