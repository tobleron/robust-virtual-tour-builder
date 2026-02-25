// @efficiency: infra-adapter
open Vitest
open Simulation.Navigation
open Types

describe("SimulationNavigation", () => {
  let createHotspot = (target, _isReturn) => {
    {
      linkId: "l-" ++ target,
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
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
      isAutoForward: None,
    }
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
    sequenceId: 0,
  }

  let scene1: scene = {
    ...baseScene,
    hotspots: [
      createHotspot("Scene 2", false), // P1: non-visited, non-return, non-bridge
      createHotspot("Scene 3", false), // P2: non-visited, non-return, bridge
      createHotspot("Scene 4", true), // P3: non-visited, return, non-bridge
      createHotspot("Scene 5", true), // P4: non-visited, return, bridge
    ],
  }

  let scene2: scene = {...baseScene, id: "s2", name: "Scene 2", hotspots: [], isAutoForward: false}
  let scene3: scene = {...baseScene, id: "s3", name: "Scene 3", hotspots: [], isAutoForward: true}
  let scene4: scene = {...baseScene, id: "s4", name: "Scene 4", hotspots: [], isAutoForward: false}
  let scene5: scene = {...baseScene, id: "s5", name: "Scene 5", hotspots: [], isAutoForward: true}

  let state = TestUtils.createMockState(~scenes=[scene1, scene2, scene3, scene4, scene5], ())

  test("Priority 1: Pick non-visited, non-bridge (Scene 2)", t => {
    switch findBestNextLink(scene1, state, []) {
    | Some(l) => t->expect(l.hotspot.target)->Expect.toBe("Scene 2")
    | None => {
        Console.log("Priority 1 failed: Expected Some link")
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("Priority 2: Pick non-visited, bridge (Scene 3)", t => {
    // Scene 2 (idx 1) is visited
    switch findBestNextLink(scene1, state, [1]) {
    | Some(l) => t->expect(l.hotspot.target)->Expect.toBe("Scene 3")
    | None => {
        Console.log("Priority 2 failed: Expected Some link")
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("Handle empty hotspots", t => {
    let sceneEmpty = {...scene1, hotspots: []}
    switch findBestNextLink(sceneEmpty, state, []) {
    | None => t->expect(true)->Expect.toBe(true) // Pass
    | Some(_) => {
        Console.log("Expected None for empty hotspots")
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
