/* tests/unit/utils/TestUtils.res */
open Types

/* --- FACTORIES --- */

let createMockFile = (~name="test.jpg", ~size=1024.0, ()) => {
  // Use Obj.magic to create a mock object that satisfies the ReBindings.File.t interface
  // but doesn't require a real browser File object which might fail in Node
  {"name": name, "size": size, "type": "image/jpeg"}->Obj.magic
}

let createMockHotspot = (~id="h1", ~target="scene2", ()) => {
  {
    linkId: id,
    yaw: 0.0,
    pitch: 0.0,
    target,
    targetSceneId: Some(target),
    targetYaw: Some(0.0),
    targetPitch: Some(0.0),
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    isReturnLink: Some(false),
    viewFrame: None,
    returnViewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
    isAutoForward: None,
  }
}

let createMockScene = (
  ~id="scene1",
  ~name="Scene 1",
  ~hotspots=[],
  ~isAutoForward=false,
  ~category="room",
  ~categorySet=false,
  ~label="",
  (),
) => {
  {
    id,
    name,
    file: createMockFile(~name=id ++ ".jpg", ()),
    tinyFile: None,
    originalFile: None,
    hotspots,
    category,
    floor: "1",
    label: label == "" ? name : label,
    isAutoForward,
    quality: None,
    colorGroup: None,
    _metadataSource: "default",
    categorySet,
    labelSet: label != "",
  }
}

let createMockState = (
  ~scenes: array<Types.scene>=[],
  ~activeIndex=-1,
  ~tourName="Test Tour",
  ~lastUsedCategory="outdoor",
  ~appMode=Initializing,
  (),
) => {
  let inventory = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) => {
    acc->Belt.Map.String.set(s.id, {scene: s, status: Active})
  })
  let sceneOrder = scenes->Belt.Array.map(s => s.id)

  {
    ...State.initialState,
    inventory,
    sceneOrder,
    activeIndex,
    tourName,
    lastUsedCategory,
    appMode,
  }
}

/* --- ASSERTION HELPERS --- */

let hasSceneWithId = (state: state, id) => {
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.some(scenes, s => s.id == id)
}

let getSceneById = (state: state, id) => {
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.getBy(scenes, s => s.id == id)
}
