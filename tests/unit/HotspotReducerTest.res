open Types
open Actions

let run = () => {
  Console.log("Running HotspotReducer tests...")

  let initialState = State.initialState
  let scene = {
    id: "s1",
    name: "s1",
    file: Obj.magic("s1"),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "indoor",
    floor: "ground",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }
  let state = {...initialState, scenes: [scene], activeIndex: 0}

  // --- Test AddHotspot ---
  let hotspot = {
    linkId: "h1",
    yaw: 0.0,
    pitch: 0.0,
    target: "s2",
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

  let actionAdd = AddHotspot(0, hotspot)
  let resultAdd = HotspotReducer.reduce(state, actionAdd)

  let stateWithHotspot = switch resultAdd {
  | Some(ns) =>
    let s = Array.getUnsafe(ns.scenes, 0)
    assert(Array.length(s.hotspots) == 1)
    Console.log("✓ AddHotspot passed")
    ns
  | None =>
    Console.error("✗ AddHotspot failed: returned None")
    state
  }

  // --- Test RemoveHotspot ---
  let actionRemove = RemoveHotspot(0, 0)
  let resultRemove = HotspotReducer.reduce(stateWithHotspot, actionRemove)

  switch resultRemove {
  | Some(ns) =>
    let s = Array.getUnsafe(ns.scenes, 0)
    assert(Array.length(s.hotspots) == 0)
    Console.log("✓ RemoveHotspot passed")
  | None => Console.error("✗ RemoveHotspot failed: returned None")
  }

  Console.log("HotspotReducer tests completed.")
}
