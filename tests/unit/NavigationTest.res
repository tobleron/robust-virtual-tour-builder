/* tests/unit/NavigationTest.res */
open Navigation
open Types

let run = () => {
  Console.log("Running Navigation tests...")

  let mockupScene = (id, name): Types.scene => {
    id,
    name,
    file: Obj.magic(name),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "indoor",
    floor: "ground",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "user",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  let scene1 = mockupScene("1", "scene1.webp")
  let scene2 = mockupScene("2", "scene2.webp")

  let hotspot: Types.hotspot = {
    linkId: "A01",
    yaw: 100.0,
    pitch: 0.0,
    target: "scene2.webp",
    startYaw: Some(10.0),
    startPitch: Some(20.0),
    startHfov: Some(110.0),
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    isReturnLink: Some(false),
    viewFrame: None,
    returnViewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
  }

  let scene1WithHotspot = {...scene1, hotspots: [hotspot]}
  let scenes: array<scene> = (Obj.magic([scene1WithHotspot, scene2]): array<scene>)

  let state = {
    ...State.initialState,
    scenes,
  }

  // Test findSceneByName
  let s1 = findSceneByName(state.scenes, "scene1.webp")
  assert(Belt.Option.isSome(s1))
  assert(Belt.Option.getExn(s1).id == "1")

  let sMissing = findSceneByName(state.scenes, "missing.webp")
  assert(Belt.Option.isNone(sMissing))
  Console.log("✓ findSceneByName")

  // Test getNextScene
  assert(getNextScene(state.scenes, 0) == Some(1))
  assert(getNextScene(state.scenes, 1) == Some(0)) // Circular
  Console.log("✓ getNextScene")

  // Test getPreviousScene
  assert(getPreviousScene(state.scenes, 0) == Some(1)) // Circular
  assert(getPreviousScene(state.scenes, 1) == Some(0))
  Console.log("✓ getPreviousScene")

  // Test calculatePathData
  let pathData = calculatePathData(state, 0, 0, 1, 45.0, 15.0, 90.0, (0.0, 0.0, 90.0)) // sourceSceneIndex // sourceHotspotIndex // targetIndex // targetYaw // targetPitch // targetHfov // currentView

  assert(Belt.Option.isSome(pathData))
  let pd = Belt.Option.getExn(pathData)
  assert(pd.startYaw == 10.0) // from hotspot.startYaw
  assert(pd.startPitch == 20.0) // from hotspot.startPitch
  assert(pd.arrivalYaw == 45.0)
  assert(pd.arrivalPitch == 15.0)
  Console.log("✓ calculatePathData")

  // Test calculateSmartArrivalTarget (used in simulation mode)
  let (arrYaw, arrPitch, arrHfov) = calculateSmartArrivalTarget(state.scenes, 0)
  assert(arrYaw == 10.0)
  assert(arrPitch == 20.0)
  assert(arrHfov == 110.0)
  Console.log("✓ calculateSmartArrivalTarget")

  // Test out-of-bounds navigateToScene check
  // Since navigateToScene is mostly orchestrating, and it calls getCurrentView
  // we might need to mock Viewer.instance if we want to test it meaningfully
  // but let's at least test that calculating without valid scenes returns None

  let emptyState = {...State.initialState, scenes: []}
  let invalidPathData = calculatePathData(emptyState, 0, 0, 1, 0.0, 0.0, 90.0, (0.0, 0.0, 90.0))
  assert(Belt.Option.isNone(invalidPathData))
  Console.log("✓ calculatePathData with empty state")

  Console.log("Navigation tests passed!")
}
