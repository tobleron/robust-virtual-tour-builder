/* tests/unit/RootReducer_v.test.res */
open Vitest
open Actions

describe("RootReducer", () => {
  let initialState = State.initialState

  // Helper to create basic scene
  let createScene = name => {
    let sc: Types.scene = {
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
    }
    sc
  }

  // Helper to create basic hotspot
  let createHotspot = linkId => {
    let hs: Types.hotspot = {
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
    hs
  }

  test("SceneReducer actions are handled", t => {
    let scenes = [createScene("s1"), createScene("s2")]
    let state = {...initialState, scenes, activeIndex: 0}

    let action = SetActiveScene(1, 90.0, 0.0, None)
    let result = RootReducer.reducer(state, action)

    t->expect(result.activeIndex)->Expect.toEqual(1)
    t->expect(result.activeYaw)->Expect.toEqual(90.0)
  })

  test("HotspotReducer actions are handled", t => {
    let scenes = [createScene("s1"), createScene("s2")]
    let state = {...initialState, scenes, activeIndex: 0}
    let hotspot = createHotspot("h1")
    let actionAdd = AddHotspot(0, hotspot)
    let resultAdd = RootReducer.reducer(state, actionAdd)

    let sceneWithHotspot = Array.getUnsafe(resultAdd.scenes, 0)
    t->expect(Array.length(sceneWithHotspot.hotspots))->Expect.toEqual(1)
  })

  test("UiReducer actions are handled", t => {
    let dummyDraft: Types.linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 0.0,
      intermediatePoints: None,
    }
    let actionLinking = StartLinking(Some(dummyDraft))
    let resultLinking = RootReducer.reducer(initialState, actionLinking)

    t->expect(resultLinking.isLinking)->Expect.toEqual(true)
  })

  test("NavigationReducer actions are handled", t => {
    let actionStatus = SetNavigationStatus(Idle)
    let resultStatus = RootReducer.reducer(initialState, actionStatus)

    t->expect(resultStatus.navigation)->Expect.toEqual(Idle)
  })

  test("TimelineReducer actions are handled", t => {
    let actionTimeline = SetActiveTimelineStep(Some("step1"))
    let resultTimeline = RootReducer.reducer(initialState, actionTimeline)

    t->expect(resultTimeline.activeTimelineStepId)->Expect.toEqual(Some("step1"))
  })

  test("ProjectReducer actions are handled", t => {
    let actionTourName = SetTourName("My Tour")
    let resultTourName = RootReducer.reducer(initialState, actionTourName)

    t->expect(resultTourName.tourName)->Expect.toEqual("My_Tour")
  })

  test("Reducer composition order", t => {
    let scenes = [createScene("s1"), createScene("s2")]
    let state = {...initialState, scenes, activeIndex: 0}
    // SetActiveScene should be handled by SceneReducer
    let actionScene = SetActiveScene(0, 45.0, 10.0, None)
    let resultScene = RootReducer.reducer(state, actionScene)

    t->expect(resultScene.activeIndex)->Expect.toEqual(0)
    t->expect(resultScene.activeYaw)->Expect.toEqual(45.0)
    t->expect(resultScene.activePitch)->Expect.toEqual(10.0)
  })

  test("Multiple reducer types in sequence", t => {
    let dummyDraft: Types.linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 0.0,
      intermediatePoints: None,
    }
    let state1 = RootReducer.reducer(initialState, SetTourName("Test Tour"))
    let state2 = RootReducer.reducer(state1, StartLinking(Some(dummyDraft)))
    let state3 = RootReducer.reducer(state2, SetNavigationStatus(Idle))

    t->expect(state3.tourName)->Expect.toEqual("Test_Tour")
    t->expect(state3.isLinking)->Expect.toEqual(true)
    t->expect(state3.navigation)->Expect.toEqual(Idle)
  })

  test("State immutability", t => {
    let originalState = {...initialState, tourName: "Original"}
    let newState = RootReducer.reducer(originalState, SetTourName("Modified"))

    t->expect(originalState.tourName)->Expect.toEqual("Original")
    t->expect(newState.tourName)->Expect.toEqual("Modified")
  })

  test("Journey ID increment", t => {
    let stateWithJourney = {...initialState, currentJourneyId: 5}
    let actionIncrement = IncrementJourneyId
    let resultIncrement = RootReducer.reducer(stateWithJourney, actionIncrement)

    t->expect(resultIncrement.currentJourneyId)->Expect.toEqual(6)
  })

  test("Reset action", t => {
    let modifiedState = {
      ...initialState,
      tourName: "Modified",
      isLinking: true,
      activeIndex: 5,
    }
    let actionReset = Reset
    let resultReset = RootReducer.reducer(modifiedState, actionReset)

    t->expect(resultReset.tourName)->Expect.toEqual("Tour Name")
    t->expect(resultReset.isLinking)->Expect.toEqual(false)
    t->expect(resultReset.activeIndex)->Expect.toEqual(-1)
  })
})
