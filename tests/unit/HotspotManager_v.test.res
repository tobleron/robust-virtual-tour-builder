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
      preCalculatedSnapshot: None,
    }
  }

  let createHotspot = (target): Types.hotspot => {
    {
      linkId: "hs1",
      yaw: 10.0,
      pitch: 20.0,
      target,
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

  test("createHotspotConfig should mark auto-forward class", t => {
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
    t->expect(String.includes(cssClass, "auto-forward"))->Expect.toBe(true)
  })

  test("createTooltipFunc should create expected elements", t => {
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

    let tooltipFunc: Dom.element => unit = config["createTooltipFunc"]
    let div = Dom.createElement("div")
    tooltipFunc(div)

    let navBtn = Dom.querySelector(div, ".hotspot-nav-btn")
    t->expect(Belt.Option.isSome(Nullable.toOption(navBtn)))->Expect.toBe(true)

    let actionBtn = Dom.querySelector(div, ".hotspot-action-trigger")
    t->expect(Belt.Option.isSome(Nullable.toOption(actionBtn)))->Expect.toBe(true)
  })
})
