// @efficiency: infra-adapter
/* tests/unit/Simulation.PathGenerator_v.test.res */
open Vitest
open Types

describe("Simulation.PathGenerator", () => {
  let createScene = (id, name, isAutoForward) => {
  {
    id,
    name,
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "indoor",
      floor: "ground",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "test",
    categorySet: false,
    labelSet: false,
    isAutoForward,
    sequenceId: 0,
  }
  }

  let createHotspot = (target, ~isReturn=false, ()) => {
    {
      linkId: "test-link",
      yaw: 10.0,
      pitch: 20.0,
      target,
      targetSceneId: Some(target),
      targetYaw: Some(30.0),
      targetPitch: Some(40.0),
      targetHfov: None,
      startYaw: None,
      startPitch: None,
      startHfov: None,
      isReturnLink: Some(isReturn),
      viewFrame: None,
      returnViewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
      isAutoForward: None,
    }
  }

  beforeEach(() => {
    AppStateBridge.updateState(State.initialState)
  })

  test("getSimulationPath: handles empty state correctly", t => {
    let path = Simulation.PathGenerator.getSimulationPath(false, ~getState=AppStateBridge.getState)
    t->expect(Array.length(path))->Expect.toBe(0)
  })

  test("getSimulationPath: generates simple path with correct arrivals", t => {
    let scene0 = {
      ...createScene("0", "scene0", false),
      hotspots: [createHotspot("scene1", ())],
    }
    let scene1 = createScene("1", "scene1", false)

    AppStateBridge.updateState(TestUtils.createMockState(
      ~scenes=[scene0, scene1],
      (),
    ))

    let path = Simulation.PathGenerator.getSimulationPath(false, ~getState=AppStateBridge.getState)
    t->expect(Array.length(path))->Expect.toBe(2)
    t->expect(Belt.Array.getExn(path, 0).idx)->Expect.toBe(0)
    t->expect(Belt.Array.getExn(path, 1).idx)->Expect.toBe(1)

    // Check transition target in step 0
    switch Belt.Array.getExn(path, 0).transitionTarget {
    | Some(tt) =>
      t->expect(tt.targetName)->Expect.toBe("scene1")
      t->expect(tt.yaw)->Expect.toBe(10.0)
    | None => t->expect(true)->Expect.toBe(false)
    }

    // Check arrival view in step 1
    // For non-return, it uses viewFrame or targetYaw/targetPitch
    t->expect(Belt.Array.getExn(path, 1).arrivalView.yaw)->Expect.toBe(30.0)
    t->expect(Belt.Array.getExn(path, 1).arrivalView.pitch)->Expect.toBe(40.0)
  })

  test("getSimulationPath: handles isReturn link and returnViewFrame", t => {
    let hotspot = {
      ...createHotspot("scene1", ~isReturn=true, ()),
      returnViewFrame: Some({yaw: 111.0, pitch: 222.0, hfov: 90.0}),
    }
    let scene0 = {...createScene("0", "scene0", false), hotspots: [hotspot]}
    let scene1 = createScene("1", "scene1", false)

    AppStateBridge.updateState(TestUtils.createMockState(
      ~scenes=[scene0, scene1],
      (),
    ))

    let path = Simulation.PathGenerator.getSimulationPath(false, ~getState=AppStateBridge.getState)
    t->expect(Belt.Array.getExn(path, 1).arrivalView.yaw)->Expect.toBe(111.0)
    t->expect(Belt.Array.getExn(path, 1).arrivalView.pitch)->Expect.toBe(222.0)
  })

  test("getSimulationPath: handles auto-forward skip logic", t => {
    let scene0 = {
      ...createScene("0", "scene0", false),
      hotspots: [createHotspot("scene1_auto", ())],
    }
    let scene1_auto = {
      ...createScene("1", "scene1_auto", true),
      hotspots: [createHotspot("scene2", ())],
    }
    let scene2 = createScene("2", "scene2", false)

    AppStateBridge.updateState(TestUtils.createMockState(
      ~scenes=[scene0, scene1_auto, scene2],
      (),
    ))

    // Skip enabled
    let path = Simulation.PathGenerator.getSimulationPath(true, ~getState=AppStateBridge.getState)
    t->expect(Array.length(path))->Expect.toBe(2)
    t->expect(Belt.Array.getExn(path, 0).idx)->Expect.toBe(0)
    t->expect(Belt.Array.getExn(path, 1).idx)->Expect.toBe(2)

    switch Belt.Array.getExn(path, 0).transitionTarget {
    | Some(tt) => t->expect(tt.targetName)->Expect.toBe("scene2")
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("getSimulationPath: prevents infinite loops", t => {
    let scene0 = {
      ...createScene("0", "scene0", false),
      hotspots: [createHotspot("scene1", ())],
    }
    let scene1 = {
      ...createScene("1", "scene1", false),
      hotspots: [createHotspot("scene0", ())],
    }

    AppStateBridge.updateState(TestUtils.createMockState(
      ~scenes=[scene0, scene1],
      (),
    ))

    let path = Simulation.PathGenerator.getSimulationPath(false, ~getState=AppStateBridge.getState)
    // scene0 -> scene1 -> scene0
    // The loop detection should stop it.
    t->expect(Array.length(path) <= 3)->Expect.toBe(true)
  })
})
