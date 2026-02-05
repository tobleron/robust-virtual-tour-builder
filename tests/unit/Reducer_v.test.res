/* tests/unit/Reducer_v.test.res */
open Vitest
open Actions

describe("Reducer (Root Re-export)", () => {
  let initialState = State.initialState

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
      _metadataSource: "user",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
    sc
  }

  test("SetActiveScene within bounds", t => {
    let stateWithScenes = {
      ...initialState,
      scenes: [createScene("scene1.webp")],
    }
    let action1 = SetActiveScene(0, 45.0, 10.0, None)
    let state1 = Reducer.reducer(stateWithScenes, action1)
    t->expect(state1.activeIndex)->Expect.toEqual(0)
    t->expect(state1.activeYaw)->Expect.toEqual(45.0)
    t->expect(state1.activePitch)->Expect.toEqual(10.0)
  })

  test("SetActiveScene out of bounds", t => {
    let stateWithScenes = {
      ...initialState,
      scenes: [createScene("scene1.webp")],
    }
    let action2 = SetActiveScene(1, 0.0, 0.0, None)
    let state2 = Reducer.reducer(stateWithScenes, action2)
    t->expect(state2.activeIndex)->Expect.toEqual(initialState.activeIndex)
  })

  test("SetTourName", t => {
    let action3 = SetTourName("My awesome tour")
    let state3 = Reducer.reducer(initialState, action3)
    t->expect(state3.tourName)->Expect.toEqual("My_awesome_tour") // SanitizeName is called
  })

  test("AddHotspot", t => {
    let stateWithScenes = {
      ...initialState,
      scenes: [createScene("scene1.webp")],
      appMode: InteractiveAuthoring(Idle),
    }
    let hotspot: Types.hotspot = {
      linkId: "A01",
      yaw: 100.0,
      pitch: 0.0,
      target: "scene2.webp",
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
    let action4 = AddHotspot(0, hotspot)
    let state4 = Reducer.reducer(stateWithScenes, action4)
    let firstScene = Array.getUnsafe(state4.scenes, 0)
    t->expect(Array.length(firstScene.hotspots))->Expect.toEqual(1)
    t->expect(Array.getUnsafe(firstScene.hotspots, 0).linkId)->Expect.toEqual("A01")
  })

  test("DeleteScene", t => {
    let scene1 = createScene("scene1.webp")
    let scene2 = {...createScene("scene2.webp"), id: "2"}
    let stateBeforeDelete = {
      ...initialState,
      scenes: [scene1, scene2],
      activeIndex: 1,
      appMode: InteractiveAuthoring(Idle),
    }
    let action6 = DeleteScene(1)
    let state6 = Reducer.reducer(stateBeforeDelete, action6)
    t->expect(Array.length(state6.scenes))->Expect.toEqual(1)
    t->expect(state6.activeIndex)->Expect.toEqual(0)
    t->expect(Array.getUnsafe(state6.deletedSceneIds, 0))->Expect.toEqual("2")
  })

  test("LoadProject", t => {
    let projectJson = JSON.parseOrThrow(`{
      "tourName": "New Project",
      "scenes": [
        {
          "id": "p1",
          "name": "living.webp",
          "file": "living.webp",
          "hotspots": []
        }
      ]
    }`)
    let action7 = LoadProject(projectJson)
    let state7 = Reducer.reducer(initialState, action7)
    t->expect(state7.tourName)->Expect.toEqual("New Project")
    t->expect(Array.length(state7.scenes))->Expect.toEqual(1)
    t->expect(Array.getUnsafe(state7.scenes, 0).id)->Expect.toEqual("p1")
  })

  test("SyncSceneNames", t => {
    let sceneWithLabel = {
      ...initialState,
      scenes: [{...createScene("scene1.webp"), label: "Living Room"}],
    }
    let action8 = SyncSceneNames
    let state8 = Reducer.reducer(sceneWithLabel, action8)
    let updatedScene = Array.getUnsafe(state8.scenes, 0)
    t->expect(updatedScene.name)->Expect.toEqual("01_living_room.webp")
  })
})
