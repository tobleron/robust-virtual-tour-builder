/* tests/unit/Reducer_v.test.res */
open Vitest
open Actions
open Types

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
      sequenceId: 0,
    }
    sc
  }

  let mockState = (~scenes: array<Types.scene>=[], ~activeIndex=-1, ~appMode=Initializing, ()) => {
    let inventory = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) => {
      acc->Belt.Map.String.set(s.id, ({scene: s, status: Active}: Types.sceneEntry))
    })
    let sceneOrder = scenes->Belt.Array.map(s => s.id)
    {
      ...State.initialState,
      inventory,
      sceneOrder,
      activeIndex,
      appMode,
    }
  }

  test("SetActiveScene within bounds", t => {
    let stateWithScenes = mockState(~scenes=[createScene("scene1.webp")], ~activeIndex=-1, ())
    let action1 = SetActiveScene(0, 45.0, 10.0, None)
    let state1 = Reducer.reducer(stateWithScenes, action1)
    t->expect(state1.activeIndex)->Expect.toEqual(0)
    t->expect(state1.activeYaw)->Expect.toEqual(45.0)
    t->expect(state1.activePitch)->Expect.toEqual(10.0)
  })

  test("SetActiveScene out of bounds", t => {
    let stateWithScenes = mockState(~scenes=[createScene("scene1.webp")], ~activeIndex=0, ())

    // Test negative index
    let actionNegative = SetActiveScene(-1, 0.0, 0.0, None)
    let stateNegative = Reducer.reducer(stateWithScenes, actionNegative)
    t->expect(stateNegative.activeIndex)->Expect.toEqual(0)

    // Test index too large
    let actionTooLarge = SetActiveScene(1, 0.0, 0.0, None)
    let stateTooLarge = Reducer.reducer(stateWithScenes, actionTooLarge)
    t->expect(stateTooLarge.activeIndex)->Expect.toEqual(0)
  })

  test("SetTourName", t => {
    let action3 = SetTourName("My awesome tour")
    let state3 = Reducer.reducer(initialState, action3)
    t->expect(state3.tourName)->Expect.toEqual("My_awesome_tour") // SanitizeName is called
  })

  test("AddHotspot", t => {
    let stateWithScenes = mockState(
      ~scenes=[createScene("scene1.webp")],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let hotspot: Types.hotspot = {
      linkId: "A01",
      yaw: 100.0,
      pitch: 0.0,
      target: "scene2.webp",
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
    }
    let action4 = AddHotspot(0, hotspot)
    let state4 = Reducer.reducer(stateWithScenes, action4)
    let state4Scenes = SceneInventory.getActiveScenes(state4.inventory, state4.sceneOrder)
    let firstScene = Array.getUnsafe(state4Scenes, 0)
    t->expect(Array.length(firstScene.hotspots))->Expect.toEqual(1)
    t->expect(Array.getUnsafe(firstScene.hotspots, 0).linkId)->Expect.toEqual("A01")
  })

  test("DeleteScene", t => {
    let scene1 = createScene("scene1.webp")
    let scene2 = {...createScene("scene2.webp"), id: "2"}
    let stateBeforeDelete = mockState(
      ~scenes=[scene1, scene2],
      ~activeIndex=1,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let action6 = DeleteScene(1)
    let state6 = Reducer.reducer(stateBeforeDelete, action6)
    let state6Scenes = SceneInventory.getActiveScenes(state6.inventory, state6.sceneOrder)
    t->expect(Array.length(state6Scenes))->Expect.toEqual(1)
    t->expect(state6.activeIndex)->Expect.toEqual(0)
    t
    ->expect(Array.getUnsafe(SceneInventory.getDeletedIds(state6.inventory), 0))
    ->Expect.toEqual("2")
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
    let state7Scenes = SceneInventory.getActiveScenes(state7.inventory, state7.sceneOrder)
    t->expect(Array.length(state7Scenes))->Expect.toEqual(1)
    t->expect(Array.getUnsafe(state7Scenes, 0).id)->Expect.toEqual("p1")
  })

  test("SyncSceneNames", t => {
    let stateWithLabel = mockState(
      ~scenes=[{...createScene("scene1.webp"), label: "Living Room"}],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let action8 = SyncSceneNames
    let state8 = Reducer.reducer(stateWithLabel, action8)
    let state8Scenes = SceneInventory.getActiveScenes(state8.inventory, state8.sceneOrder)
    let updatedScene = Array.getUnsafe(state8Scenes, 0)
    t->expect(updatedScene.name)->Expect.toEqual("001_Living_Room.webp")
  })
})
