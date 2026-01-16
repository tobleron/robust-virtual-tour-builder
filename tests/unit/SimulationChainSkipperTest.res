open SimulationChainSkipper
open Types

let run = () => {
  Console.log("Running SimulationChainSkipper tests...")

  let createMockScene = (id, name, isAutoForward): scene => {
    {
      id,
      name,
      file: JSON.Encode.null,
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
      isAutoForward,
      preCalculatedSnapshot: None,
    }
  }

  let createMockHotspot = (target): hotspot => {
    {
      linkId: "h_" ++ target,
      yaw: 0.0,
      pitch: 0.0,
      target,
      isReturnLink: Some(false),
      startYaw: None,
      startPitch: None,
      startHfov: None,
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      viewFrame: None,
      returnViewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
    }
  }

  let createMockEnrichedLink = (
    hotspot,
    targetIndex,
    isBridge,
  ): SimulationNavigation.enrichedLink => {
    {
      hotspot,
      hotspotIndex: 0,
      targetIndex,
      isVisited: false,
      isReturn: false,
      isBridge,
    }
  }

  {
    // Test 1: No auto-forward

    let scene1 = createMockScene("1", "scene1", false)
    let scene2 = createMockScene("2", "scene2", false)

    let hotspot = createMockHotspot("scene2")
    let initialLink = createMockEnrichedLink(hotspot, 1, false)

    let state = {
      ...State.initialState,
      scenes: [scene1, scene2],
    }

    let visitedCallbackCount = ref(0)
    let onVisit = _ => {
      visitedCallbackCount := visitedCallbackCount.contents + 1
    }

    let result = skipAutoForwardChain(initialLink, state, [], onVisit)

    assert(result.finalLink.targetIndex == 1)
    assert(result.skippedScenes == [])
    assert(visitedCallbackCount.contents == 0)
    Console.log("✓ Should return original link if target is not auto-forward")
  }

  {
    // Test 2: Skip one scene

    let scene0 = createMockScene("0", "scene0", false)
    let scene1 = createMockScene("1", "scene1", true)
    let scene2 = createMockScene("2", "scene2", false)

    let h0_to_1 = createMockHotspot("scene1")
    let h1_to_2 = createMockHotspot("scene2")
    let scene1 = {
      ...scene1,
      hotspots: [h1_to_2],
    }

    // Setup state needs correct names for findBestNextLink lookup
    // findBestNextLink uses s.name to find index.
    // scenes array index matches.

    let state = {
      ...State.initialState,
      scenes: [scene0, scene1, scene2],
    }

    let initialLink = createMockEnrichedLink(h0_to_1, 1, true)

    let visitedScenesRef = ref([])
    let onVisit = idx => {
      let _ = Js.Array.push(idx, visitedScenesRef.contents)
    }

    let result = skipAutoForwardChain(initialLink, state, [], onVisit)

    assert(result.finalLink.targetIndex == 2)
    assert(result.skippedScenes == [1])
    assert(visitedScenesRef.contents == [1])
    Console.log("✓ Should skip one auto-forward scene")
  }

  {
    // Test 3: Multiple skips

    let s0 = createMockScene("0", "s0", false)
    let s1 = createMockScene("1", "s1", true)
    let s2 = createMockScene("2", "s2", true)
    let s3 = createMockScene("3", "s3", false)

    let h1_to_2 = createMockHotspot("s2")
    let s1 = {...s1, hotspots: [h1_to_2]}

    let h2_to_3 = createMockHotspot("s3")
    let s2 = {...s2, hotspots: [h2_to_3]}

    let state = {
      ...State.initialState,
      scenes: [s0, s1, s2, s3],
    }

    let h0_to_1 = createMockHotspot("s1")
    let initialLink = createMockEnrichedLink(h0_to_1, 1, true)

    let visitedScenesRef = ref([])
    let onVisit = idx => {
      let _ = Js.Array.push(idx, visitedScenesRef.contents)
    }

    let result = skipAutoForwardChain(initialLink, state, [], onVisit)

    assert(result.finalLink.targetIndex == 3)
    assert(result.skippedScenes == [1, 2])
    Console.log("✓ Should skip multiple auto-forward scenes")
  }

  // Test 4: Dead end

  let s0 = createMockScene("0", "s0", false)
  let s1 = createMockScene("1", "s1", true)
  // s1 has no hotspots

  let state = {...State.initialState, scenes: [s0, s1]}
  let h0_to_1 = createMockHotspot("s1")
  let initialLink = createMockEnrichedLink(h0_to_1, 1, true)

  let visitedScenesRef = ref([])
  let onVisit = idx => {
    let _ = Js.Array.push(idx, visitedScenesRef.contents)
  }

  let result = skipAutoForwardChain(initialLink, state, [], onVisit)

  // Should stay at 1 because it can't go anywhere
  assert(result.finalLink.targetIndex == 1)
  Console.log("✓ Should stop at dead end")
}
