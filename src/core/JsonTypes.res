type viewFrameJson = {
  yaw: float,
  pitch: float,
  hfov: float,
}

type hotspotJson = {
  linkId: Nullable.t<string>,
  yaw: float,
  pitch: float,
  target: string,
  targetYaw: Nullable.t<float>,
  targetPitch: Nullable.t<float>,
  targetHfov: Nullable.t<float>,
  startYaw: Nullable.t<float>,
  startPitch: Nullable.t<float>,
  startHfov: Nullable.t<float>,
  isReturnLink: Nullable.t<bool>,
  viewFrame: Nullable.t<viewFrameJson>,
  returnViewFrame: Nullable.t<viewFrameJson>,
  waypoints: Nullable.t<array<viewFrameJson>>,
  displayPitch: Nullable.t<float>,
  transition: Nullable.t<string>,
  duration: Nullable.t<float>,
}

type projectSceneJson = {
  id: Nullable.t<string>,
  name: string,
  file: JSON.t,
  tinyFile: Nullable.t<JSON.t>,
  originalFile: Nullable.t<JSON.t>,
  hotspots: Nullable.t<array<hotspotJson>>,
  category: Nullable.t<string>,
  floor: Nullable.t<string>,
  label: Nullable.t<string>,
  quality: Nullable.t<JSON.t>,
  colorGroup: Nullable.t<string>,
  @as("_metadataSource") metadataSource: Nullable.t<string>,
  categorySet: Nullable.t<bool>,
  labelSet: Nullable.t<bool>,
  isAutoForward: Nullable.t<bool>,
}

type projectJson = {
  tourName: Nullable.t<string>,
  scenes: array<projectSceneJson>,
}

type importSceneJson = {
  id: string,
  name: string,
  preview: JSON.t,
  tiny: Nullable.t<JSON.t>,
  original: Nullable.t<JSON.t>,
  quality: Nullable.t<JSON.t>,
  colorGroup: Nullable.t<string>,
}

type timelineItemJson = {
  id: string,
  linkId: string,
  sceneId: string,
  targetScene: string,
  transition: string,
  duration: int,
}

type updateMetadataJson = {
  category: Nullable.t<string>,
  floor: Nullable.t<string>,
  label: Nullable.t<string>,
  isAutoForward: Nullable.t<bool>,
}

type timelineUpdateJson = {
  transition: Nullable.t<string>,
  duration: Nullable.t<int>,
}

/* --- DECODERS (Middle ground: Type-checked casts) --- */

external castToHotspots: JSON.t => array<hotspotJson> = "%identity"
external castToProject: JSON.t => projectJson = "%identity"
external castToProjectScene: JSON.t => projectSceneJson = "%identity"
external castToImportScene: JSON.t => importSceneJson = "%identity"
external castToTimelineItem: JSON.t => timelineItemJson = "%identity"
external castToUpdateMetadata: JSON.t => updateMetadataJson = "%identity"
external castToTimelineUpdate: JSON.t => timelineUpdateJson = "%identity"

let decodeProject = (json: JSON.t): result<projectJson, string> => {
  switch json {
  | Object(_) => Ok(castToProject(json))
  | _ => Error("Invalid project JSON")
  }
}

let decodeImportScene = (json: JSON.t): result<importSceneJson, string> => {
  switch json {
  | Object(_) => Ok(castToImportScene(json))
  | _ => Error("Invalid import scene JSON")
  }
}

let decodeTimelineItem = (json: JSON.t): result<timelineItemJson, string> => {
  switch json {
  | Object(_) => Ok(castToTimelineItem(json))
  | _ => Error("Invalid timeline item JSON")
  }
}
