/* tests/unit/RootReducer_v.test.res */
open Vitest
open Actions

describe("Reducer", () => {
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
      sequenceId: 0,
    }
    sc
  }

  let createHotspot = linkId => {
    let hs: Types.hotspot = {
      linkId,
      yaw: 0.0,
      pitch: 0.0,
      target: "s2",
      targetSceneId: None,
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      startYaw: None,
      startPitch: None,
      startHfov: None,
      viewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
      isAutoForward: None,
      sequenceOrder: None,
    }
    hs
  }

  let mockState = (scenes: array<Types.scene>): Types.state => {
    let inventory = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) => {
      acc->Belt.Map.String.set(s.id, ({scene: s, status: Active}: Types.sceneEntry))
    })
    let sceneOrder = scenes->Belt.Array.map(s => s.id)
    {
      ...State.initialState,
      inventory,
      sceneOrder,
      activeIndex: 0,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      discoveringTitleCount: 0,
    }
  }

  test("SceneReducer actions are handled", t => {
    let scenes = [createScene("s1"), createScene("s2")]
    let state = mockState(scenes)

    let action = SetActiveScene(1, 90.0, 0.0, None)
    let result = Reducer.reducer(state, action)

    t->expect(result.activeIndex)->Expect.toEqual(1)
    t->expect(result.activeYaw)->Expect.toEqual(90.0)
  })

  test("HotspotReducer actions are handled", t => {
    let scenes = [createScene("s1"), createScene("s2")]
    let state = mockState(scenes)
    let hotspot = createHotspot("h1")
    let actionAdd = AddHotspot(0, hotspot)
    let resultAdd = Reducer.reducer(state, actionAdd)

    let resultAddScenes = SceneInventory.getActiveScenes(resultAdd.inventory, resultAdd.sceneOrder)
    let sceneWithHotspot = Array.getUnsafe(resultAddScenes, 0)
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
      retargetHotspot: None,
    }

    let actionLinking = StartLinking(Some(dummyDraft))
    let resultLinking = Reducer.reducer(State.initialState, actionLinking)

    t->expect(resultLinking.isLinking)->Expect.toEqual(true)
  })

  test("NavigationReducer actions are handled", t => {
    let actionStatus = SetNavigationStatus(Idle)
    let resultStatus = Reducer.reducer(State.initialState, actionStatus)

    t->expect(resultStatus.navigationState.navigation)->Expect.toEqual(Idle)
  })

  test("TimelineReducer actions are handled", t => {
    let actionTimeline = SetActiveTimelineStep(Some("step1"))
    let resultTimeline = Reducer.reducer(State.initialState, actionTimeline)

    t->expect(resultTimeline.activeTimelineStepId)->Expect.toEqual(Some("step1"))
  })

  test("ProjectReducer actions are handled", t => {
    let actionTourName = SetTourName("My Tour")
    let resultTourName = Reducer.reducer(State.initialState, actionTourName)

    t->expect(resultTourName.tourName)->Expect.toEqual("My_Tour")
  })

  test("Reducer composition order", t => {
    let scenes = [createScene("s1"), createScene("s2")]
    let state = mockState(scenes)
    // SetActiveScene should be handled by SceneReducer
    let actionScene = SetActiveScene(0, 45.0, 10.0, None)
    let resultScene = Reducer.reducer(state, actionScene)

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
      retargetHotspot: None,
    }

    let state1 = Reducer.reducer(State.initialState, SetTourName("Test Tour"))
    let state2 = Reducer.reducer(state1, StartLinking(Some(dummyDraft)))
    let state3 = Reducer.reducer(state2, SetNavigationStatus(Idle))

    t->expect(state3.tourName)->Expect.toEqual("Test_Tour")
    t->expect(state3.isLinking)->Expect.toEqual(true)
    t->expect(state3.navigationState.navigation)->Expect.toEqual(Idle)
  })

  test("State immutability", t => {
    let originalState = {...State.initialState, tourName: "Original"}
    let newState = Reducer.reducer(originalState, SetTourName("Modified"))

    t->expect(originalState.tourName)->Expect.toEqual("Original")
    t->expect(newState.tourName)->Expect.toEqual("Modified")
  })

  test("Journey ID increment", t => {
    let stateWithJourney = {
      ...State.initialState,
      navigationState: {...State.initialState.navigationState, currentJourneyId: 5},
    }
    let actionIncrement = IncrementJourneyId
    let resultIncrement = Reducer.reducer(stateWithJourney, actionIncrement)

    t->expect(resultIncrement.navigationState.currentJourneyId)->Expect.toEqual(6)
  })

  test("Reset action", t => {
    let modifiedState = {
      ...State.initialState,
      tourName: "Modified",
      isLinking: true,
      activeIndex: 5,
    }
    let actionReset = Actions.Reset
    let resultReset = Reducer.reducer(modifiedState, actionReset)

    t->expect(resultReset.tourName)->Expect.toEqual("Untitled Tour")
    t->expect(resultReset.isLinking)->Expect.toEqual(false)
    t->expect(resultReset.activeIndex)->Expect.toEqual(-1)
  })
})
