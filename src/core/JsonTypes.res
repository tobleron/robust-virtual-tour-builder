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
  lastUsedCategory: Nullable.t<string>,
  exifReport: Nullable.t<JSON.t>,
  sessionId: Nullable.t<string>,
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

type transitionTargetJson = {
  yaw: float,
  pitch: float,
  targetName: string,
  timelineItemId: Nullable.t<string>,
}

type arrivalViewJson = {
  yaw: float,
  pitch: float,
}

type stepJson = {
  idx: int,
  transitionTarget: Nullable.t<transitionTargetJson>,
  arrivalView: arrivalViewJson,
}

/* --- DECODERS (Middle ground: Type-checked casts) --- */

/* --- DECODERS (Middle ground: Type-checked casts) --- */

let castToHotspots = (json: JSON.t): array<hotspotJson> => Obj.magic(json)
let castToProject = (json: JSON.t): projectJson => Obj.magic(json)
let castToProjectScene = (json: JSON.t): projectSceneJson => Obj.magic(json)
let castToImportScene = (json: JSON.t): importSceneJson => Obj.magic(json)
let castToTimelineItem = (json: JSON.t): timelineItemJson => Obj.magic(json)
let castToUpdateMetadata = (json: JSON.t): updateMetadataJson => Obj.magic(json)
let castToTimelineUpdate = (json: JSON.t): timelineUpdateJson => Obj.magic(json)
let castToValidationReport = (json: JSON.t): SharedTypes.validationReport => Obj.magic(json)
let castToMetadataResponse = (json: JSON.t): SharedTypes.metadataResponse => Obj.magic(json)
let castToQualityAnalysis = (json: JSON.t): SharedTypes.qualityAnalysis => Obj.magic(json)
let castToSimilarityResponse = (json: JSON.t): SharedTypes.similarityResponse => Obj.magic(json)
let castToSteps = (json: JSON.t): array<stepJson> => Obj.magic(json)
let castToExifMetadata = (json: JSON.t): SharedTypes.exifMetadata => Obj.magic(json)

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

let decodeUpdateMetadata = (json: JSON.t): result<updateMetadataJson, string> => {
  switch json {
  | Object(_) => Ok(castToUpdateMetadata(json))
  | _ => Error("Invalid update metadata JSON")
  }
}

let decodeTimelineUpdate = (json: JSON.t): result<timelineUpdateJson, string> => {
  switch json {
  | Object(_) => Ok(castToTimelineUpdate(json))
  | _ => Error("Invalid timeline update JSON")
  }
}
