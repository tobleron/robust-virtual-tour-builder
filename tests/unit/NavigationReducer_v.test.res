/* tests/unit/NavigationReducer.test.res */
open Vitest
open Actions
open Types
open TestUtils

let createJourney = (journeyId, targetIndex, sourceIndex, hotspotIndex, previewOnly) => {
  {
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
}

test("NavigationReducer: SetSimulationMode resets chain and increments journeyId", t => {
  let state = createMockState(~activeIndex=0, ())
  let state = {...state, autoForwardChain: [1, 2], currentJourneyId: 5}

  let action = SetSimulationMode(true)
  let result = RootReducer.reducer(state, action)

  t->expect(result.autoForwardChain->Array.length)->Expect.toBe(0)
  t->expect(result.currentJourneyId)->Expect.toBe(6)
})

test("NavigationReducer: SetNavigationStatus updates state", t => {
  let state = createMockState()
  let journey = createJourney(1, 2, 0, 0, false)
  let status = Navigating(journey)

  let action = SetNavigationStatus(status)
  let result = RootReducer.reducer(state, action)

  let isNavigating = switch result.navigation {
  | Navigating(_) => true
  | _ => false
  }
  t->expect(isNavigating)->Expect.toBe(true)
})

test("NavigationReducer: AddToAutoForwardChain prevents duplicates", t => {
  let state = createMockState()
  let state = {...state, autoForwardChain: [1, 2]}

  let action = AddToAutoForwardChain(2) // Duplicate
  let result = RootReducer.reducer(state, action)

  t->expect(result.autoForwardChain->Array.length)->Expect.toBe(2)

  let actionNew = AddToAutoForwardChain(3)
  let resultNew = RootReducer.reducer(result, actionNew)
  t->expect(resultNew.autoForwardChain->Array.length)->Expect.toBe(3)
})

test("NavigationReducer: NavigationCompleted updates state for non-preview", t => {
  let journey = createJourney(10, 5, 3, 2, false)
  let state = createMockState(
    ~scenes=[
      createMockScene(),
      createMockScene(),
      createMockScene(),
      createMockScene(),
      createMockScene(),
      createMockScene(),
    ],
    (),
  )
  let state = {...state, currentJourneyId: 10, navigation: Navigating(journey)}

  let action = NavigationCompleted(journey)
  let result = RootReducer.reducer(state, action)

  t->expect(result.navigation)->Expect.toEqual(Idle)
  t->expect(result.activeIndex)->Expect.toBe(5)
  t->expect(result.activeYaw)->Expect.toBe(90.0)

  let incoming = result.incomingLink->Option.getOrThrow
  t->expect(incoming.sceneIndex)->Expect.toBe(3)
  t->expect(incoming.hotspotIndex)->Expect.toBe(2)

  t->expect(result.transition.type_)->Expect.toEqual(Some("link"))
})

test("NavigationReducer: NavigationCompleted ignores mismatched journeyId", t => {
  let journey = createJourney(10, 5, 3, 2, false)
  let state = createMockState(~activeIndex=2, ())
  let state = {...state, currentJourneyId: 15}

  let action = NavigationCompleted(journey)
  let result = RootReducer.reducer(state, action)

  // Should not change activeIndex
  t->expect(result.activeIndex)->Expect.toBe(2)
})

test("NavigationReducer: NavigationCompleted handles previewOnly", t => {
  let journey = createJourney(10, 5, 3, 2, true)
  let state = createMockState(~activeIndex=2, ())
  let state = {...state, currentJourneyId: 10, navigation: Navigating(journey)}

  let action = NavigationCompleted(journey)
  let result = RootReducer.reducer(state, action)

  t->expect(result.navigation)->Expect.toEqual(Idle)
  t->expect(result.activeIndex)->Expect.toBe(2) // Unchanged
})
