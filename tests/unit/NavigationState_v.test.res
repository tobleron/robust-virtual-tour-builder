/* tests/unit/NavigationState_v.test.res */
open Vitest
open Types
open Actions

let createJourney = (journeyId) => {
  {
    journeyId,
    targetIndex: 1,
    sourceIndex: 0,
    hotspotIndex: 0,
    arrivalYaw: 0.0,
    arrivalPitch: 0.0,
    arrivalHfov: 100.0,
    previewOnly: false,
    pathData: None,
  }
}

test("NavigationState: isNavigating checks FSM state", t => {
  let state = NavigationState.initial()
  t->expect(NavigationState.isNavigating(state))->Expect.toBe(false)

  let state = {...state, navigationFsm: Preloading({targetSceneId: "1", attempt: 1, isAnticipatory: false})}
  t->expect(NavigationState.isNavigating(state))->Expect.toBe(true)
})

test("NavigationState: isLoading checks for Preloading", t => {
  let state = NavigationState.initial()
  t->expect(NavigationState.isLoading(state))->Expect.toBe(false)

  let loading = {...state, navigationFsm: Preloading({targetSceneId: "1", attempt: 1, isAnticipatory: false})}
  t->expect(NavigationState.isLoading(loading))->Expect.toBe(true)

  let transitioning = {...state, navigationFsm: Transitioning({fromSceneId: None, toSceneId: "2", progress: 0.0, isPreview: false})}
  t->expect(NavigationState.isLoading(transitioning))->Expect.toBe(false)
})

test("NavigationState: isTransitioning checks for Transitioning", t => {
  let state = NavigationState.initial()
  t->expect(NavigationState.isTransitioning(state))->Expect.toBe(false)

  let transitioning = {...state, navigationFsm: Transitioning({fromSceneId: None, toSceneId: "2", progress: 0.0, isPreview: false})}
  t->expect(NavigationState.isTransitioning(transitioning))->Expect.toBe(true)
})

test("NavigationState: reduce SetNavigationStatus", t => {
  let state = NavigationState.initial()
  let journey = createJourney(1)
  let next = NavigationState.reduce(state, SetNavigationStatus(Navigating(journey)))

  switch next {
  | Some(s) => {
      switch s.navigation {
      | Navigating(j) => t->expect(j.journeyId)->Expect.toBe(1)
      | _ => t->expect(false)->Expect.toBe(true)
      }
    }
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("NavigationState: reduce IncrementJourneyId", t => {
  let state = NavigationState.initial() // id starts at 0
  let next = NavigationState.reduce(state, IncrementJourneyId)

  switch next {
  | Some(s) => t->expect(s.currentJourneyId)->Expect.toBe(1)
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("NavigationState: reduce AddToAutoForwardChain", t => {
  let state = NavigationState.initial()
  let next = NavigationState.reduce(state, AddToAutoForwardChain(5))

  switch next {
  | Some(s) => t->expect(s.autoForwardChain)->Expect.toEqual([5])
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("NavigationState: reduce NavigationCompleted resets state", t => {
  let state = {
    ...NavigationState.initial(),
    navigation: Navigating(createJourney(10)),
    currentJourneyId: 10,
    autoForwardChain: [1, 2],
    incomingLink: Some({sceneIndex: 0, hotspotIndex: 0})
  }

  let next = NavigationState.reduce(state, NavigationCompleted(createJourney(10)))

  switch next {
  | Some(s) => {
      t->expect(s.navigation)->Expect.toEqual(Idle)
      t->expect(s.currentJourneyId)->Expect.toBe(11)
      t->expect(Array.length(s.autoForwardChain))->Expect.toBe(0)
      t->expect(s.incomingLink)->Expect.toBe(None)
    }
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("NavigationState: reduce unrelated action returns None", t => {
  let state = NavigationState.initial()
  let next = NavigationState.reduce(state, SetTourName("Test")) // Unrelated action
  t->expect(next)->Expect.toBe(None)
})
