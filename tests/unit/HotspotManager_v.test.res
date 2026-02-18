open Vitest
open ReBindings

describe("HotspotManager", () => {
  let createScene = (name): Types.scene => {
    {
      id: "id_" ++ name,
      name,
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "test",
      floor: "1",
      label: "label",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  }

  let createHotspot = (target): Types.hotspot => {
    {
      linkId: "hs1",
      yaw: 10.0,
      pitch: 20.0,
      target,
      targetSceneId: Some(target),
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
      isAutoForward: None,
    }
  }

  let mockDispatch = _ => ()

  test("createHotspotConfig should return correct basic fields", t => {
    let hotspot = createHotspot("TargetScene")
    let scene = createScene("SourceScene")
    let state = State.initialState

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene,
      ~dispatch=mockDispatch,
    )

    t->expect(config["id"])->Expect.toBe("hs1")
    t->expect(config["pitch"])->Expect.toBe(20.0)
    t->expect(config["yaw"])->Expect.toBe(10.0)
    let cssClass: string = config["cssClass"]
    t->expect(String.includes(cssClass, "pnlm-hotspot"))->Expect.toBe(true)
  })

  test("createHotspotConfig should mark auto-forward class from hotspot metadata", t => {
    let hotspot = {...createHotspot("TargetScene"), isAutoForward: Some(true)}
    let sourceScene = createScene("SourceScene")
    let targetScene = {...createScene("TargetScene"), isAutoForward: false}

    let state = {
      ...State.initialState,
      scenes: [sourceScene, targetScene],
    }

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene=sourceScene,
      ~dispatch=mockDispatch,
    )

    let cssClass: string = config["cssClass"]
    t->expect(String.includes(cssClass, "auto-forward"))->Expect.toBe(true)
  })

  test("createHotspotConfig should not infer auto-forward from target scene", t => {
    let hotspot = createHotspot("TargetScene")
    let sourceScene = createScene("SourceScene")
    let targetScene = {...createScene("TargetScene"), isAutoForward: true}

    let state = {
      ...State.initialState,
      scenes: [sourceScene, targetScene],
    }

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene=sourceScene,
      ~dispatch=mockDispatch,
    )

    let cssClass: string = config["cssClass"]
    t->expect(String.includes(cssClass, "auto-forward"))->Expect.toBe(false)
  })

  test("createHotspotConfig should handle displayPitch", t => {
    let hotspot = {
      ...createHotspot("TargetScene"),
      displayPitch: Some(45.0),
    }
    let scene = createScene("SourceScene")
    let state = State.initialState

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene,
      ~dispatch=mockDispatch,
    )

    t->expect(config["pitch"])->Expect.toBe(45.0)
  })

  test("createHotspotConfig should mark simulation class", t => {
    let hotspot = createHotspot("TargetScene")
    let scene = createScene("SourceScene")
    let state = {
      ...State.initialState,
      simulation: {
        ...State.initialState.simulation,
        status: Running,
      },
    }

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene,
      ~dispatch=mockDispatch,
    )

    let cssClass: string = config["cssClass"]
    t->expect(String.includes(cssClass, "in-simulation"))->Expect.toBe(true)
    t->expect(String.includes(cssClass, "hidden-in-sim"))->Expect.toBe(false)
  })

  test("createHotspotConfig should mark active-sim-target class when navigating", t => {
    let hotspot = createHotspot("TargetScene")
    let scene = createScene("SourceScene")
    let state = {
      ...State.initialState,
      navigationState: {
        ...NavigationState.initial(),
        navigation: Navigating({
          journeyId: 1,
          targetIndex: 1,
          sourceIndex: 0,
          hotspotIndex: 0, // matches our index
          arrivalYaw: 0.0,
          arrivalPitch: 0.0,
          arrivalHfov: 0.0,
          previewOnly: false,
          pathData: None,
        }),
      },
    }

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene,
      ~dispatch=mockDispatch,
    )

    let cssClass: string = config["cssClass"]
    t->expect(String.includes(cssClass, "active-sim-target"))->Expect.toBe(true)
  })

  test("createHotspotConfig should mark return-link class", t => {
    let hotspot = createHotspot("Scene1")
    let scene1 = createScene("Scene1")
    let scene2 = createScene("Scene2")

    let state = {
      ...State.initialState,
      scenes: [scene1, scene2],
      activeIndex: 1, // At Scene2
      navigationState: {
        ...NavigationState.initial(),
        incomingLink: Some({sceneIndex: 0, hotspotIndex: 0}), // Came from Scene1
      },
    }

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene=scene2,
      ~dispatch=mockDispatch,
    )

    let cssClass: string = config["cssClass"]
    t->expect(String.includes(cssClass, "return-link"))->Expect.toBe(true)
  })

  test("createTooltipFunc should initialize container with base classes", t => {
    let hotspot = createHotspot("TargetScene")
    let sourceScene = createScene("SourceScene")
    let state = State.initialState

    let config = HotspotManager.createHotspotConfig(
      ~hotspot,
      ~index=0,
      ~state,
      ~scene=sourceScene,
      ~dispatch=mockDispatch,
    )

    let tooltipFunc: Dom.element => unit = config["createTooltipFunc"]
    let div = Dom.createElement("div")
    tooltipFunc(div)

    let classList = Dom.getClassName(div)
    t->expect(String.includes(classList, "pnlm-hotspot-base"))->Expect.toBe(true)
    t->expect(String.includes(classList, "group"))->Expect.toBe(true)
    t->expect(String.includes(classList, "relative"))->Expect.toBe(true)
  })
})
