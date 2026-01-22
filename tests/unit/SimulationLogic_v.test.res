/* tests/unit/SimulationLogic_v.test.res */
open Vitest
open Types
open SimulationLogic

describe("SimulationLogic", () => {
  let createHotspot = (target, isReturn) => {
    linkId: "l-" ++ target,
    yaw: 0.0,
    pitch: 0.0,
    target,
    targetYaw: Some(10.0),
    targetPitch: Some(20.0),
    targetHfov: Some(90.0),
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
  }

  let baseScene = {
    id: "s1",
    name: "Scene 1",
    file: Url(""),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "",
    floor: "",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  test("getNextMove returns Move when a link is found", t => {
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [createHotspot("Scene 2", false)],
    }
    let scene2: scene = {...baseScene, id: "s2", name: "Scene 2", hotspots: []}

    let state: state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 0,
      simulation: {
        ...State.initialState.simulation,
        visitedScenes: [0],
      },
    }

    let move = getNextMove(state)
    switch move {
    | Move(m) => {
        t->expect(m.targetIndex)->Expect.toBe(1)
        t->expect(m.yaw)->Expect.toBe(10.0)
        t->expect(m.pitch)->Expect.toBe(20.0)
      }
    | _ => t->expect("Move")->Expect.toBe("Something else")
    }
  })

  test("getNextMove returns Complete when returned to start and no new paths", t => {
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [createHotspot("Scene 2", false)],
    }
    let scene2: scene = {
      ...baseScene,
      id: "s2",
      name: "Scene 2",
      hotspots: [createHotspot("Scene 1", true)],
    }

    let state: state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 1,
      simulation: {
        ...State.initialState.simulation,
        visitedScenes: [0, 1],
      },
    }

    let move = getNextMove(state)
    switch move {
    | Complete(c) => t->expect(c.reason)->Expect.toBe("returned_to_start")
    | _ => t->expect("Complete")->Expect.toBe("Something else")
    }
  })

  test("getNextMove returns Complete when no reachable scenes", t => {
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [],
    }

    let state: state = {
      ...State.initialState,
      scenes: [scene1],
      activeIndex: 0,
    }

    let move = getNextMove(state)
    switch move {
    | Complete(c) => t->expect(c.reason)->Expect.toBe("no_reachable_scenes")
    | _ => t->expect("Complete")->Expect.toBe("Something else")
    }
  })
})
