open SimulationNavigation
open Types

let run = () => {
  Console.log("Running SimulationNavigation tests...")

  let assertEqual = (actual, expected, name) => {
    if actual == expected {
      Console.log("✓ " ++ name ++ " passed")
    } else {
      Console.error("✗ " ++ name ++ " failed: expected " ++ expected ++ ", got " ++ actual)
    }
  }

  let createHotspot = (target, isReturn) => {
    linkId: "l-" ++ target,
    yaw: 0.0,
    pitch: 0.0,
    target,
    targetYaw: None,
    targetPitch: None,
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

  let state: state = {
    ...State.initialState,
    scenes: [scene1, scene2, scene3, scene4, scene5],
  }

  // Priority 1: Pick Scene 2
  switch findBestNextLink(scene1, state, []) {
  | Some(l) => assertEqual(l.hotspot.target, "Scene 2", "Priority 1")
  | None => Console.error("✗ Priority 1 failed")
  }

  // Priority 2: Scene 2 visited, pick Scene 3
  // Scene 2 index is 1
  switch findBestNextLink(scene1, state, [1]) {
  | Some(l) => assertEqual(l.hotspot.target, "Scene 3", "Priority 2")
  | None => Console.error("✗ Priority 2 failed")
  }

  // Priority 3: Scene 2, 3 visited, pick Scene 4
  // Scene 3 index is 2
  switch findBestNextLink(scene1, state, [1, 2]) {
  | Some(l) => assertEqual(l.hotspot.target, "Scene 4", "Priority 3")
  | None => Console.error("✗ Priority 3 failed")
  }

  // Priority 4: Scene 2, 3, 4 visited, pick Scene 5
  // Scene 4 index is 3
  switch findBestNextLink(scene1, state, [1, 2, 3]) {
  | Some(l) => assertEqual(l.hotspot.target, "Scene 5", "Priority 4")
  | None => Console.error("✗ Priority 4 failed")
  }

  // Priority 5: All visited, pick non-return (Scene 2 or 3)
  // Scene 5 index is 4
  switch findBestNextLink(scene1, state, [1, 2, 3, 4]) {
  | Some(l) =>
    let ok = l.hotspot.target == "Scene 2" || l.hotspot.target == "Scene 3"
    if ok {
      Console.log("✓ Priority 5 (revisit non-return) passed")
    } else {
      Console.error("✗ Priority 5 failed")
    }
  | None => Console.error("✗ Priority 5 failed")
  }

  // Test empty hotspots
  let sceneEmpty = {...scene1, hotspots: []}
  switch findBestNextLink(sceneEmpty, state, []) {
  | None => Console.log("✓ Empty hotspots handled")
  | Some(_) => Console.error("✗ Empty hotspots failed")
  }

  Console.log("✓ SimulationNavigation: Module logic verified")
}
