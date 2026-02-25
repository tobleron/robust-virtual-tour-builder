// @efficiency: infra-adapter
open Vitest
open Types

describe("NavigationGraph", () => {
  let createScene = (name, hotspots) => {
    let sc: scene = {
      id: name,
      name,
      file: Url(name),
      tinyFile: None,
      originalFile: None,
      hotspots,
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

  let createHotspot = (
    target,
    ~yaw=0.0,
    ~pitch=0.0,
    ~startYaw=None,
    ~startPitch=None,
    ~viewFrame=None,
    ~waypoints=None,
    (),
  ): hotspot => {
    {
      linkId: "h-" ++ target,
      yaw,
      pitch,
      target,
      targetSceneId: Some(target),
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      startYaw,
      startPitch,
      startHfov: None,
      viewFrame,
      waypoints,
      displayPitch: None,
      transition: None,
      duration: None,
      isAutoForward: None,
    }
  }

  let createMockState = (scenes: array<scene>): state => {
    let inventory = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) => {
      acc->Belt.Map.String.set(s.id, {scene: s, status: Active})
    })
    let sceneOrder = scenes->Belt.Array.map(s => s.id)
    {
      tourName: "Test Tour",
      inventory,
      sceneOrder,
      activeIndex: 0,
      activeYaw: 0.0,
      activePitch: 0.0,
      isLinking: false,
      transition: {type_: Cut, targetHotspotIndex: -1, fromSceneName: None},
      appMode: Initializing,
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
      lastUsedCategory: "indoor",
      sessionId: None,
      logo: None,
      structuralRevision: 0,
      nextSceneSequenceId: 1,
      visitedHubScenes: [],
    }
  }

  test("findSceneByName finds existing scene", t => {
    let s1 = createScene("s1", [])
    let s2 = createScene("s2", [])
    let scenes = [s1, s2]

    let found = NavigationGraph.findSceneByName(scenes, "s2")
    switch found {
    | Some(s) => t->expect(s.name)->Expect.toBe("s2")
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("calculateSmartArrivalTarget returns default if no hotspots", t => {
    let s1 = createScene("s1", [])
    let (yaw, pitch, hfov) = NavigationGraph.calculateSmartArrivalTarget([s1], 0)
    t->expect(yaw)->Expect.toBe(0.0)
    t->expect(pitch)->Expect.toBe(0.0)
    t->expect(hfov)->Expect.toBe(90.0)
  })

  test("getNextScene wraps correctly", t => {
    let s1 = createScene("s1", [])
    let s2 = createScene("s2", [])
    let s3 = createScene("s3", [])
    let scenes = [s1, s2, s3]

    t->expect(NavigationGraph.getNextScene(scenes, 0))->Expect.toEqual(Some(1))
    t->expect(NavigationGraph.getNextScene(scenes, 1))->Expect.toEqual(Some(2))
    t->expect(NavigationGraph.getNextScene(scenes, 2))->Expect.toEqual(Some(0))
  })

  test("getPreviousScene wraps correctly", t => {
    let s1 = createScene("s1", [])
    let s2 = createScene("s2", [])
    let s3 = createScene("s3", [])
    let scenes = [s1, s2, s3]

    t->expect(NavigationGraph.getPreviousScene(scenes, 0))->Expect.toEqual(Some(2))
    t->expect(NavigationGraph.getPreviousScene(scenes, 2))->Expect.toEqual(Some(1))
    t->expect(NavigationGraph.getPreviousScene(scenes, 1))->Expect.toEqual(Some(0))
  })

  test("calculatePathData generates valid path for simple link", t => {
    let h1 = createHotspot("s2", ~yaw=0.0, ~pitch=0.0, ())
    let s1 = createScene("s1", [h1])
    let s2 = createScene("s2", [])
    let scenes = [s1, s2]
    let state = createMockState(scenes)

    let currentView = (0.0, 0.0, 100.0)
    let pathDataOpt = NavigationGraph.calculatePathData(
      state,
      0, // sourceSceneIndex
      0, // sourceHotspotIndex
      1, // targetIndex
      90.0, // targetYaw
      10.0, // targetPitch
      90.0, // targetHfov
      currentView,
    )

    switch pathDataOpt {
    | Some(pd) =>
      t->expect(pd.startYaw)->Expect.toBe(0.0)
      t->expect(pd.targetYawForPan)->Expect.toBe(90.0)
      // For simple path (catmull rom with 2 points or floor projected), check distance > 0
      t->expect(pd.totalPathDistance > 0.0)->Expect.toBe(true)
      t->expect(Array.length(pd.segments) > 0)->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("calculatePathData respects viewFrame/startYaw/startPitch", t => {
    let h1 = createHotspot(
      "s2",
      ~yaw=0.0,
      ~pitch=0.0,
      ~startYaw=Some(45.0),
      ~startPitch=Some(5.0),
      ~viewFrame=Some({yaw: 180.0, pitch: 0.0, hfov: 90.0}),
      (),
    )
    let s1 = createScene("s1", [h1])
    let s2 = createScene("s2", [])
    let scenes = [s1, s2]
    let state = createMockState(scenes)

    let currentView = (0.0, 0.0, 100.0)
    let pathDataOpt = NavigationGraph.calculatePathData(
      state,
      0,
      0,
      1,
      90.0,
      10.0,
      90.0,
      currentView,
    )

    switch pathDataOpt {
    | Some(pd) =>
      t->expect(pd.startYaw)->Expect.toBe(45.0)
      t->expect(pd.startPitch)->Expect.toBe(5.0)
      t->expect(pd.targetYawForPan)->Expect.toBe(180.0)
      t->expect(pd.targetPitchForPan)->Expect.toBe(0.0)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("calculatePathData handles waypoints", t => {
    let waypoints: array<viewFrame> = [
      {yaw: 30.0, pitch: 0.0, hfov: 100.0},
      {yaw: 60.0, pitch: 0.0, hfov: 100.0},
    ]
    let h1 = createHotspot("s2", ~yaw=0.0, ~pitch=0.0, ~waypoints=Some(waypoints), ())
    let s1 = createScene("s1", [h1])
    let s2 = createScene("s2", [])
    let scenes = [s1, s2]
    let state = createMockState(scenes)

    let currentView = (0.0, 0.0, 100.0)
    let pathDataOpt = NavigationGraph.calculatePathData(
      state,
      0,
      0,
      1,
      90.0,
      10.0,
      90.0,
      currentView,
    )

    switch pathDataOpt {
    | Some(pd) =>
      t->expect(Array.length(pd.waypoints))->Expect.toBe(2)
      // Check that segments go through waypoints vaguely (complex to test exact path interpolation)
      // But we can check segment count. With 2 waypoints + start + end = 4 control points,
      // B-spline generation should produce many interpolated segments.
      t->expect(Array.length(pd.segments) > 10)->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })
})
