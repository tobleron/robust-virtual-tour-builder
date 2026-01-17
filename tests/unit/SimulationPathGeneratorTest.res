/* tests/unit/SimulationPathGeneratorTest.res */
open Types
open SimulationPathGenerator

let run = () => {
  Console.log("Running SimulationPathGenerator tests...")

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
      preCalculatedSnapshot: None,
    }
  }

  let createHotspot = (target, ~isReturn=false, ()) => {
    {
      linkId: "test-link",
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
  }

  // 1. Empty state
  GlobalStateBridge.setState({
    ...State.initialState,
    scenes: [],
  })

  let path1 = getSimulationPath(false)
  assert(Array.length(path1) == 0)
  Console.log("✓ Handles empty state correctly")

  // 2. Simple transition
  let scene0 = {
    ...createScene("0", "scene0", false),
    hotspots: [createHotspot("scene1", ())],
  }
  let scene1 = createScene("1", "scene1", false)

  GlobalStateBridge.setState({
    ...State.initialState,
    scenes: [scene0, scene1],
  })

  let path2 = getSimulationPath(false)
  assert(Array.length(path2) == 2)
  assert(Belt.Array.getExn(path2, 0).idx == 0)
  assert(Belt.Array.getExn(path2, 1).idx == 1)

  switch Belt.Array.getExn(path2, 0).transitionTarget {
  | Some(t) => assert(t.targetName == "scene1")
  | None => assert(false)
  }
  Console.log("✓ Generates simple path")

  // 3. Auto-forward skip logic
  let scene0_auto = {
    ...createScene("0", "scene0", false),
    hotspots: [createHotspot("scene1_auto", ())],
  }
  let scene1_auto = {
    ...createScene("1", "scene1_auto", true),
    hotspots: [createHotspot("scene2", ())],
  }
  let scene2 = createScene("2", "scene2", false)

  GlobalStateBridge.setState({
    ...State.initialState,
    scenes: [scene0_auto, scene1_auto, scene2],
  })

  // Skip disabled
  let path3_no_skip = getSimulationPath(false)
  assert(Array.length(path3_no_skip) == 3)
  assert(Belt.Array.getExn(path3_no_skip, 1).idx == 1)

  // Skip enabled
  let path3_skip = getSimulationPath(true)
  assert(Array.length(path3_skip) == 2)
  assert(Belt.Array.getExn(path3_skip, 0).idx == 0)
  assert(Belt.Array.getExn(path3_skip, 1).idx == 2)

  switch Belt.Array.getExn(path3_skip, 0).transitionTarget {
  | Some(t) => assert(t.targetName == "scene2") // Target should be updated to scene2
  | None => assert(false)
  }
  Console.log("✓ Handles auto-forward skip logic")

  // 4. Loop detection
  let loopScene0 = {
    ...createScene("0", "scene0", false),
    hotspots: [createHotspot("scene1", ())],
  }
  let loopScene1 = {
    ...createScene("1", "scene1", false),
    hotspots: [createHotspot("scene0", ())],
  }

  GlobalStateBridge.setState({
    ...State.initialState,
    scenes: [loopScene0, loopScene1],
  })

  let path4 = getSimulationPath(false)
  // Should stop when it detects scene0 is visited again in a way that creates a loop
  // The logic says if (targetIdx == 0 && Array.length(localVisited) > 2) stop.
  // Or INFINITE_LOOP_DETECTED via visitedStateSet.
  assert(Array.length(path4) <= 3) // scene0 -> scene1 -> scene0 (stop)
  Console.log("✓ Prevents infinite loops")

  Console.log("SimulationPathGenerator tests passed!")
}
