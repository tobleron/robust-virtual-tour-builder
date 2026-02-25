open Vitest
open SimulationMainLogic

describe("SimulationMainLogic", () => {
  let mockScene = (id, name, hotspots): Types.scene => {
    id,
    name,
    file: Url(""),
    tinyFile: None,
    originalFile: None,
    hotspots,
    category: "",
    floor: "",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "user",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    sequenceId: 0,
  }

  let mockHotspot = (target): Types.hotspot => {
    linkId: "link-" ++ target,
    yaw: 0.0,
    pitch: 0.0,
    target,
    targetSceneId: Some(target),
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    viewFrame: None,
    returnViewFrame: None,
    isReturnLink: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
    isAutoForward: None,
  }

  test("getNextMove should return Move when a path is found", t => {
    let s1 = mockScene("s1", "Scene 1", [mockHotspot("Scene 2")])
    let s2 = mockScene("s2", "Scene 2", [])

    let state = TestUtils.createMockState(
      ~scenes=[s1, s2],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let state = {
      ...state,
      simulation: {
        ...state.simulation,
        status: Running,
        visitedLinkIds: ["A01"],
      },
    }

    let nextMove = getNextMove(state)

    switch nextMove {
    | Move({targetIndex}) => t->expect(targetIndex)->Expect.toBe(1)
    | _ => t->expect("Move")->Expect.toBe("Complete/None")
    }
  })

  test("getNextMove should return Complete when no path is found", t => {
    let s1 = mockScene("s1", "Scene 1", [])
    let state = TestUtils.createMockState(
      ~scenes=[s1],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let state = {
      ...state,
      simulation: {
        ...state.simulation,
        status: Running,
        visitedLinkIds: ["A01"],
      },
    }

    let nextMove = getNextMove(state)

    switch nextMove {
    | Complete(_) => t->expect(true)->Expect.toBe(true)
    | _ => t->expect("Complete")->Expect.toBe("Move/None")
    }
  })
})
