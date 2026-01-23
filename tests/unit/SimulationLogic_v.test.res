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

  test("getNextMove handles viewFrame when present", t => {
    let hotspot = {
      ...createHotspot("Scene 2", false),
      viewFrame: Some({yaw: 45.0, pitch: -10.0, hfov: 80.0}),
    }
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [hotspot],
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
        t->expect(m.yaw)->Expect.toBe(45.0)
        t->expect(m.pitch)->Expect.toBe(-10.0)
        t->expect(m.hfov)->Expect.toBe(80.0)
      }
    | _ => t->expect("Move")->Expect.toBe("Something else")
    }
  })

  test("getNextMove handles returnViewFrame for return links", t => {
    let hotspot = {
      ...createHotspot("Scene 1", true),
      returnViewFrame: Some({yaw: 180.0, pitch: 0.0, hfov: 100.0}),
    }
    // We need an unvisited path from Scene 1 so it doesn't complete the tour immediately
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [createHotspot("Scene 3", false)],
    }
    let scene2: scene = {
      ...baseScene,
      id: "s2",
      name: "Scene 2",
      hotspots: [hotspot],
    }
    let scene3: scene = {...baseScene, id: "s3", name: "Scene 3", hotspots: []}

    let state: state = {
      ...State.initialState,
      scenes: [scene1, scene2, scene3],
      activeIndex: 1,
      simulation: {
        ...State.initialState.simulation,
        visitedScenes: [0, 1], // Scene 3 remains unvisited
      },
    }

    let move = getNextMove(state)
    switch move {
    | Move(m) => {
        t->expect(m.yaw)->Expect.toBe(180.0)
        t->expect(m.hfov)->Expect.toBe(100.0)
      }
    | _ => t->expect("Move")->Expect.toBe("Something else")
    }
  })

  test("getNextMove handles chain skipping and gathers extra visited scenes", t => {
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [createHotspot("Scene 2", false)],
    }
    // Scene 2 is auto-forward (bridge)
    let scene2: scene = {
      ...baseScene,
      id: "s2",
      name: "Scene 2",
      isAutoForward: true,
      hotspots: [createHotspot("Scene 3", false)],
    }
    let scene3: scene = {...baseScene, id: "s3", name: "Scene 3", hotspots: []}

    let state: state = {
      ...State.initialState,
      scenes: [scene1, scene2, scene3],
      activeIndex: 0,
      simulation: {
        ...State.initialState.simulation,
        visitedScenes: [0],
        skipAutoForwardGlobal: true,
      },
    }

    let move = getNextMove(state)
    switch move {
    | Move(m) => {
        t->expect(m.targetIndex)->Expect.toBe(2) // Skipped scene 2, landed on 3
        t->expect(m.triggerActions)->Expect.toContainEqual(AddVisitedScene(1))
        t->expect(m.triggerActions)->Expect.toContainEqual(AddVisitedScene(2))
      }
    | _ => t->expect("Move")->Expect.toBe("Something else")
    }
  })

  test("getNextMove synchronizes activeTimelineStepId", t => {
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [createHotspot("Scene 2", false)],
    }
    let scene2: scene = {...baseScene, id: "s2", name: "Scene 2", hotspots: []}

    let timelineItem = {
      id: "t1",
      linkId: "l-Scene 2",
      sceneId: "s1",
      targetScene: "Scene 2",
      transition: "",
      duration: 0,
    }

    let state: state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 0,
      timeline: [timelineItem],
    }

    let move = getNextMove(state)
    switch move {
    | Move(m) =>
      t
      ->expect(m.triggerActions)
      ->Expect.toContainEqual(SetActiveTimelineStep(Some("t1")))
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

  test("getNextMove returns Move if returned to start but new paths exist", t => {
    let scene1: scene = {
      ...baseScene,
      id: "s1",
      name: "Scene 1",
      hotspots: [createHotspot("Scene 2", false), createHotspot("Scene 3", false)],
    }
    let scene2: scene = {
      ...baseScene,
      id: "s2",
      name: "Scene 2",
      hotspots: [createHotspot("Scene 1", true)],
    }
    let scene3: scene = {
      ...baseScene,
      id: "s3",
      name: "Scene 3",
      hotspots: [],
    }

    let state: state = {
      ...State.initialState,
      scenes: [scene1, scene2, scene3],
      activeIndex: 1,
      simulation: {
        ...State.initialState.simulation,
        visitedScenes: [0, 1], // Scene 3 is NOT visited
      },
    }

    let move = getNextMove(state)
    switch move {
    | Move(m) => t->expect(m.targetIndex)->Expect.toBe(0)
    | _ => t->expect("Move")->Expect.toBe("Something else")
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

  test("getNextMove returns Complete when invalid active index", t => {
    let state: state = {
      ...State.initialState,
      scenes: [],
      activeIndex: 0,
    }

    let move = getNextMove(state)
    switch move {
    | Complete(c) => t->expect(c.reason)->Expect.toBe("invalid_current_scene")
    | _ => t->expect("Complete")->Expect.toBe("Something else")
    }
  })
})
