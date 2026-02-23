/* tests/unit/ReducerModules_v.test.res */
open Vitest
open Actions
open Types

describe("Reducer.Scene", () => {
  test("handleSetActiveScene sets active index and transition", t => {
    let s1 = TestUtils.createMockScene(~id="s1", ())
    let s2 = TestUtils.createMockScene(~id="s2", ())
    let state = TestUtils.createMockState(~scenes=[s1, s2], ~activeIndex=0, ())

    let transition: Types.transition = {
      type_: Fade,
      targetHotspotIndex: 0,
      fromSceneName: Some("s1"),
    }

    let action = SetActiveScene(1, 45.0, -10.0, Some(transition))
    let result = Reducer.reducer(state, action)

    t->expect(result.activeIndex)->Expect.toBe(1)
    t->expect(result.activeYaw)->Expect.toBe(45.0)
    t->expect(result.activePitch)->Expect.toBe(-10.0)
    t->expect(result.transition.type_)->Expect.toEqual(Fade)
  })

  test("ReorderScenes moves scene and updates activeIndex correctly", t => {
    let s0 = TestUtils.createMockScene(~id="0", ())
    let s1 = TestUtils.createMockScene(~id="1", ())
    let s2 = TestUtils.createMockScene(~id="2", ())
    let state = TestUtils.createMockState(
      ~scenes=[s0, s1, s2],
      ~activeIndex=1,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let action = ReorderScenes(1, 2)
    let result = Reducer.reducer(state, action)

    let resultScenes = SceneInventory.getActiveScenes(result.inventory, result.sceneOrder)
    let scene = resultScenes[2]->Option.getOrThrow
    t->expect(scene.id)->Expect.toBe("1")
    t->expect(result.activeIndex)->Expect.toBe(2)
  })

  test("DeleteScene removes scene and cleanup hotspots", t => {
    let h1 = TestUtils.createMockHotspot(~id="h1", ~target="scene2_name", ())
    let s1 = TestUtils.createMockScene(~id="s1", ~name="scene1_name", ~hotspots=[h1], ())
    let s2 = TestUtils.createMockScene(~id="s2", ~name="scene2_name", ())
    let state = TestUtils.createMockState(
      ~scenes=[s1, s2],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let action = DeleteScene(1)
    let result = Reducer.reducer(state, action)

    let resultScenes = SceneInventory.getActiveScenes(result.inventory, result.sceneOrder)
    t->expect(resultScenes->Array.length)->Expect.toBe(1)
    let remainingScene = resultScenes[0]->Option.getOrThrow
    t->expect(remainingScene.hotspots->Array.length)->Expect.toBe(0)
  })
})

describe("Reducer.Hotspot", () => {
  test("AddHotspot appends hotspot to specific scene", t => {
    let s1 = TestUtils.createMockScene(~id="s1", ())
    let state = TestUtils.createMockState(
      ~scenes=[s1],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let hotspot = TestUtils.createMockHotspot(~id="h1", ())

    let action = AddHotspot(0, hotspot)
    let result = Reducer.reducer(state, action)

    let resultScenes = SceneInventory.getActiveScenes(result.inventory, result.sceneOrder)
    let scene = resultScenes[0]->Option.getOrThrow
    let hs = Belt.Array.get(scene.hotspots, 0)->Option.getOrThrow
    t->expect(hs.linkId)->Expect.toBe("h1")
  })

  test("UpdateHotspotTargetView updates view parameters", t => {
    let h1 = TestUtils.createMockHotspot(~id="h1", ())
    let s1 = TestUtils.createMockScene(~id="s1", ~hotspots=[h1], ())
    let state = TestUtils.createMockState(
      ~scenes=[s1],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let action = UpdateHotspotTargetView(0, 0, 120.0, -20.0, 60.0)
    let result = Reducer.reducer(state, action)

    let resultScenes = SceneInventory.getActiveScenes(result.inventory, result.sceneOrder)
    let scene = resultScenes[0]->Option.getOrThrow
    let hs = Belt.Array.get(scene.hotspots, 0)->Option.getOrThrow
    t->expect(hs.targetYaw)->Expect.toEqual(Some(120.0))
    t->expect(hs.targetPitch)->Expect.toEqual(Some(-20.0))
    t->expect(hs.targetHfov)->Expect.toEqual(Some(60.0))
  })
})

describe("Reducer.Ui", () => {
  let initialState = State.initialState

  test("SetPreloadingScene updates preloadingSceneIndex", t => {
    let action = SetPreloadingScene(5)
    let result = Reducer.Ui.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.preloadingSceneIndex)->Expect.toBe(5)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("StartLinking enables isLinking and sets draft", t => {
    let draft: linkDraft = {
      pitch: 10.0,
      yaw: 20.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 90.0,
      intermediatePoints: None,
    }
    let action = StartLinking(Some(draft))
    let result = Reducer.Ui.reduce(initialState, action)

    switch result {
    | Some(newState) => {
        t->expect(newState.isLinking)->Expect.toBe(true)
        t->expect(newState.linkDraft)->Expect.toBe(Some(draft))
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })
})

describe("Reducer.Simulation", () => {
  let initialState = State.initialState

  test("StartAutoPilot initializes simulation state", t => {
    let action = StartAutoPilot(42, true)
    let result = Reducer.Simulation.reduce(initialState, action)

    switch result {
    | Some(newState) => {
        let sim = newState.simulation
        t->expect(sim.status)->Expect.toBe(Running)
        t->expect(sim.autoPilotJourneyId)->Expect.toBe(42)
        t->expect(Array.length(sim.visitedScenes))->Expect.toBe(0)
        t->expect(sim.skipAutoForwardGlobal)->Expect.toBe(true)
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })
})

describe("Reducer.Timeline", () => {
  let initialState = State.initialState

  test("AddToTimeline", t => {
    let itemJson = JSON.parseOrThrow(`{
      "id": "step1",
      "linkId": "link1",
      "sceneId": "scene1",
      "targetScene": "scene2",
      "transition": "fade",
      "duration": 1000
    }`)

    let actionAdd = AddToTimeline(itemJson)
    let resultAdd = Reducer.Timeline.reduce(initialState, actionAdd)

    switch resultAdd {
    | Some(ns) =>
      t->expect(Array.length(ns.timeline))->Expect.toEqual(1)
      let item = Array.getUnsafe(ns.timeline, 0)
      t->expect(item.id)->Expect.toEqual("step1")
    | None => failwith("Expected Some(state)")
    }
  })
})

describe("Reducer.Project", () => {
  let initialState = State.initialState

  test("SetTourName sanitizes the name", t => {
    let action = SetTourName("My Tour Name")
    let result = Reducer.Project.reduce(initialState, action)

    switch result {
    | Some(state) => t->expect(state.tourName)->Expect.toEqual("My_Tour_Name")
    | None => failwith("Expected Some(state)")
    }
  })
})

describe("Reducer.Navigation", () => {
  test("SetSimulationMode resets chain and increments journeyId", t => {
    let state = TestUtils.createMockState(~activeIndex=0, ())
    let state = {
      ...state,
      navigationState: {...state.navigationState, autoForwardChain: [1, 2], currentJourneyId: 5},
    }

    let action = SetSimulationMode(true)
    let result = Reducer.reducer(state, action)

    t->expect(result.navigationState.autoForwardChain->Array.length)->Expect.toBe(0)
    t->expect(result.navigationState.currentJourneyId)->Expect.toBe(6)
  })
})
