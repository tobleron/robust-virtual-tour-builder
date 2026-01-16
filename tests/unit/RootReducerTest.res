open Types
open Actions

let run = () => {
  Console.log("Running RootReducer tests...")

  let initialState = State.initialState

  // Helper to create basic scene
  let createScene = name => {
    id: name,
    name,
    file: Obj.magic(name),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "indoor",
    floor: "ground",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  // Helper to create basic hotspot
  let createHotspot = linkId => {
    linkId,
    yaw: 0.0,
    pitch: 0.0,
    target: "s2",
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    isReturnLink: None,
    viewFrame: None,
    returnViewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
  }

  // --- Test 1: SceneReducer actions are handled ---
  Console.log("Test 1: SceneReducer actions")
  let scenes = [createScene("s1"), createScene("s2")]
  let state = {...initialState, scenes, activeIndex: 0}

  let action = SetActiveScene(1, 90.0, 0.0, None)
  let result = RootReducer.reducer(state, action)

  assert(result.activeIndex == 1)
  assert(result.activeYaw == 90.0)
  Console.log("✓ SceneReducer action handled correctly")

  // --- Test 2: HotspotReducer actions are handled ---
  Console.log("Test 2: HotspotReducer actions")
  let hotspot = createHotspot("h1")
  let actionAdd = AddHotspot(0, hotspot)
  let resultAdd = RootReducer.reducer(state, actionAdd)

  let sceneWithHotspot = Array.getUnsafe(resultAdd.scenes, 0)
  assert(Array.length(sceneWithHotspot.hotspots) == 1)
  Console.log("✓ HotspotReducer action handled correctly")

  // --- Test 3: UiReducer actions are handled ---
  Console.log("Test 3: UiReducer actions")
  let actionLinking = SetIsLinking(true)
  let resultLinking = RootReducer.reducer(state, actionLinking)

  assert(resultLinking.isLinking == true)
  Console.log("✓ UiReducer action handled correctly")

  // --- Test 4: NavigationReducer actions are handled ---
  Console.log("Test 4: NavigationReducer actions")
  let actionSimulation = SetSimulationMode(true)
  let resultSimulation = RootReducer.reducer(state, actionSimulation)

  assert(resultSimulation.isSimulationMode == true)
  Console.log("✓ NavigationReducer action handled correctly")

  // --- Test 5: TimelineReducer actions are handled ---
  Console.log("Test 5: TimelineReducer actions")
  let actionTimeline = SetActiveTimelineStep(Some("step1"))
  let resultTimeline = RootReducer.reducer(state, actionTimeline)

  assert(resultTimeline.activeTimelineStepId == Some("step1"))
  Console.log("✓ TimelineReducer action handled correctly")

  // --- Test 6: ProjectReducer actions are handled ---
  Console.log("Test 6: ProjectReducer actions")
  let actionTourName = SetTourName("My Tour")
  let resultTourName = RootReducer.reducer(state, actionTourName)

  // Note: TourLogic.sanitizeName replaces spaces with underscores
  assert(resultTourName.tourName == "My_Tour")
  Console.log("✓ ProjectReducer action handled correctly")

  // --- Test 7: Reducer composition order ---
  Console.log("Test 7: Reducer composition order")
  // Test that the first matching reducer handles the action
  // SetActiveScene should be handled by SceneReducer (first in chain)
  let actionScene = SetActiveScene(0, 45.0, 10.0, None)
  let resultScene = RootReducer.reducer(state, actionScene)

  assert(resultScene.activeIndex == 0)
  assert(resultScene.activeYaw == 45.0)
  assert(resultScene.activePitch == 10.0)
  Console.log("✓ Reducer composition order correct")

  // --- Test 8: Multiple reducer types in sequence ---
  Console.log("Test 8: Multiple reducer types in sequence")
  let state1 = RootReducer.reducer(initialState, SetTourName("Test Tour"))
  let state2 = RootReducer.reducer(state1, SetIsLinking(true))
  let state3 = RootReducer.reducer(state2, SetSimulationMode(true))

  assert(state3.tourName == "Test_Tour")
  assert(state3.isLinking == true)
  assert(state3.isSimulationMode == true)
  Console.log("✓ Multiple reducer types work in sequence")

  // --- Test 9: State immutability ---
  Console.log("Test 9: State immutability")
  let originalState = {...initialState, tourName: "Original"}
  let newState = RootReducer.reducer(originalState, SetTourName("Modified"))

  assert(originalState.tourName == "Original")
  assert(newState.tourName == "Modified")
  Console.log("✓ State immutability preserved")

  // --- Test 10: Navigation status changes ---
  Console.log("Test 10: Navigation status changes")
  let actionNav = SetNavigationStatus(Idle)
  let resultNav = RootReducer.reducer(state, actionNav)

  assert(resultNav.navigation == Idle)
  Console.log("✓ Navigation status changes handled")

  // --- Test 11: Journey ID increment ---
  Console.log("Test 11: Journey ID increment")
  let stateWithJourney = {...initialState, currentJourneyId: 5}
  let actionIncrement = IncrementJourneyId
  let resultIncrement = RootReducer.reducer(stateWithJourney, actionIncrement)

  assert(resultIncrement.currentJourneyId == 6)
  Console.log("✓ Journey ID increment handled")

  // --- Test 12: Reset action ---
  Console.log("Test 12: Reset action")
  let modifiedState = {
    ...initialState,
    tourName: "Modified",
    isLinking: true,
    activeIndex: 5,
  }
  let actionReset = Reset
  let resultReset = RootReducer.reducer(modifiedState, actionReset)

  assert(resultReset.tourName == "")
  assert(resultReset.isLinking == false)
  assert(resultReset.activeIndex == -1)
  Console.log("✓ Reset action handled")

  Console.log("RootReducer tests completed.")
}
