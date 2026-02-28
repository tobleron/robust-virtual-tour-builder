/* tests/unit/OptimisticAction_v.test.res */

open Vitest
open Types

let makeInitialState = (): Types.state => {
  {
    tourName: "Original Name",
    inventory: Belt.Map.String.empty,
    sceneOrder: [],
    activeIndex: 0,
    activeYaw: 0.0,
    activePitch: 0.0,
    isLinking: false,
    transition: {type_: Cut, targetHotspotIndex: -1, fromSceneName: None},
    appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    exifReport: None,
    linkDraft: None,
    movingHotspot: None,
    preloadingSceneIndex: -1,
    isTeasing: false,
    timeline: [],
    activeTimelineStepId: None,
    navigationState: {
      navigation: Idle,
      navigationFsm: IdleFsm,
      incomingLink: None,
      autoForwardChain: [],
      currentJourneyId: 0,
    },
    simulation: {
      status: Idle,
      visitedLinkIds: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
      lastAdvanceTime: 0.0,
      pendingAdvanceId: None,
      autoPilotJourneyId: 0,
    },
    lastUsedCategory: "outdoor",
    sessionId: None,
    logo: None,
    marketingComment: "",
    marketingPhone1: "",
    marketingPhone2: "",
    marketingForRent: false,
    marketingForSale: false,
    structuralRevision: 0,
    nextSceneSequenceId: 1,
    visitedScenes: [],
  }
}

module MockApi = {
  let success = _state => Promise.resolve(Ok("success"))
  let failure = _state => Promise.resolve(Error("Network Error"))
}

testAsync("OptimisticAction commits on success", async t => {
  StateSnapshot.clear()

  let initialState = makeInitialState()
  AppStateBridge.updateState(initialState)

  let action = Actions.SetTourName("New Name")

  let capturedState = ref(None)
  let apiCall = state => {
    capturedState := Some(state)
    MockApi.success(state)
  }

  let result = await OptimisticAction.execute(~action, ~apiCall)

  switch result {
  | Committed(_) => t->expect(true)->Expect.toBe(true)
  | RolledBack(_) => t->expect("RolledBack")->Expect.toBe("Committed")
  }

  // Verify apiCall received NEXT state
  switch capturedState.contents {
  | Some(s) => t->expect(s.tourName)->Expect.toBe("New Name")
  | None => t->expect(false)->Expect.toBe(true)
  }

  let latest = StateSnapshot.getLatest()
  t->expect(latest)->Expect.toBe(None)
})

testAsync("OptimisticAction rolls back on failure", async t => {
  StateSnapshot.clear()

  let initialState = makeInitialState()
  AppStateBridge.updateState(initialState)
  let expectedTourName = AppStateBridge.getState().tourName

  let action = Actions.SetTourName("Optimistic Name")

  let rolledBackState = ref(None)
  let onRollback = s => {
    rolledBackState := Some(s)
    AppStateBridge.updateState(s)
  }

  let result = await OptimisticAction.execute(
    ~action,
    ~apiCall=MockApi.failure,
    ~getState=AppStateBridge.getState,
    ~getDispatch=() => AppStateBridge.dispatch,
    ~onRollback,
  )

  switch result {
  | RolledBack(msg) => t->expect(msg)->Expect.toBe("Network Error")
  | Committed(_) => t->expect("Committed")->Expect.toBe("RolledBack")
  }

  switch rolledBackState.contents {
  | Some(s) => t->expect(s.tourName)->Expect.toBe(expectedTourName)
  | None => t->expect(false)->Expect.toBe(true)
  }

  let current = AppStateBridge.getState()
  t->expect(current.tourName)->Expect.toBe(expectedTourName)

  let latest = StateSnapshot.getLatest()
  t->expect(latest)->Expect.toBe(None)
})
