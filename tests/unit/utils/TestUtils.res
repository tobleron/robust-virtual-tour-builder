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
  }
}

let createMockScene = (~id="scene1", ~name="Scene 1", ~hotspots=[], ~isAutoForward=false, ()) => {
  {
    id,
    name,
    file: createMockFile(~name=id ++ ".jpg", ()),
    tinyFile: None,
    originalFile: None,
    hotspots,
    category: "room",
    floor: "1",
    label: name,
    isAutoForward,
    quality: None,
    colorGroup: None,
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    preCalculatedSnapshot: None,
  }
}

let createMockState = (~scenes=[], ~activeIndex=-1, ~tourName="Test Tour", ()) => {
  {
    ...State.initialState,
    scenes,
    activeIndex,
    tourName,
  }
}

/* --- ASSERTION HELPERS --- */

let hasSceneWithId = (state: state, id) => {
  Belt.Array.some(state.scenes, s => s.id == id)
}

let getSceneById = (state: state, id) => {
  Belt.Array.getBy(state.scenes, s => s.id == id)
}
