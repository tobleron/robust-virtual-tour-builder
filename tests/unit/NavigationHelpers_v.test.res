/* tests/unit/NavigationHelpers_v.test.res */
open Vitest
open Types
open TestUtils

test("NavigationHelpers: handleAddToAutoForwardChain adds unique index", t => {
  let state = createMockState()
  let state = NavigationHelpers.handleAddToAutoForwardChain(state, 1)
  t->expect(state.navigationState.autoForwardChain)->Expect.toEqual([1])

  let state = NavigationHelpers.handleAddToAutoForwardChain(state, 1)
  t->expect(state.navigationState.autoForwardChain)->Expect.toEqual([1])

  let state = NavigationHelpers.handleAddToAutoForwardChain(state, 2)
  t->expect(state.navigationState.autoForwardChain)->Expect.toEqual([1, 2])
})

test("NavigationHelpers: handleNavigationCompleted success", t => {
  let state = createMockState(~activeIndex=0, ())

  // Create a journey object matching Types.journeyData
  let journey = {
    journeyId: 10,
    targetIndex: 5,
    sourceIndex: 0,
    hotspotIndex: 0,
    arrivalYaw: 1.0,
    arrivalPitch: 2.0,
    arrivalHfov: 100.0,
    previewOnly: false,
    pathData: None,
  }

  let state = {
    ...state,
    navigationState: {
      ...state.navigationState,
      currentJourneyId: 10,
      navigation: Navigating(journey)
    }
  }

  let next = NavigationHelpers.handleNavigationCompleted(state, journey)

  t->expect(next.activeIndex)->Expect.toBe(5)
  t->expect(next.activeYaw)->Expect.toBe(1.0)
  t->expect(next.activePitch)->Expect.toBe(2.0)

  // Navigation state should be reset
  t->expect(next.navigationState.navigation)->Expect.toEqual(Idle)
  t->expect(next.navigationState.currentJourneyId)->Expect.toBe(11)
  t->expect(Array.length(next.navigationState.autoForwardChain))->Expect.toBe(0)

  // Check incoming link
  switch next.navigationState.incomingLink {
  | Some(link) => {
      t->expect(link.sceneIndex)->Expect.toBe(0)
      t->expect(link.hotspotIndex)->Expect.toBe(0)
    }
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("NavigationHelpers: handleNavigationCompleted previewOnly", t => {
  let state = createMockState(~activeIndex=0, ())

  let journey = {
    journeyId: 10,
    targetIndex: 5,
    sourceIndex: 0,
    hotspotIndex: 0,
    arrivalYaw: 1.0,
    arrivalPitch: 2.0,
    arrivalHfov: 100.0,
    previewOnly: true,
    pathData: None,
  }

  let state = {
    ...state,
    navigationState: {
      ...state.navigationState,
      currentJourneyId: 10,
      navigation: Navigating(journey)
    }
  }

  let next = NavigationHelpers.handleNavigationCompleted(state, journey)

  // Active index shouldn't change
  t->expect(next.activeIndex)->Expect.toBe(0)

  // Navigation state reset
  t->expect(next.navigationState.navigation)->Expect.toEqual(Idle)
  t->expect(next.navigationState.currentJourneyId)->Expect.toBe(11)

  // No incoming link for preview
  t->expect(next.navigationState.incomingLink)->Expect.toBe(None)
})

test("NavigationHelpers: handleNavigationCompleted mismatch id", t => {
  let state = createMockState(~activeIndex=0, ())

  let journey = {
    journeyId: 99,
    targetIndex: 5,
    sourceIndex: 0,
    hotspotIndex: 0,
    arrivalYaw: 1.0,
    arrivalPitch: 2.0,
    arrivalHfov: 100.0,
    previewOnly: false,
    pathData: None,
  }

  let state = {
    ...state,
    navigationState: {
      ...state.navigationState,
      currentJourneyId: 10,
      navigation: Navigating(journey)
    }
  }

  let next = NavigationHelpers.handleNavigationCompleted(state, journey)

  // State unchanged
  t->expect(next.activeIndex)->Expect.toBe(0)
  t->expect(next.navigationState.currentJourneyId)->Expect.toBe(10)
})
