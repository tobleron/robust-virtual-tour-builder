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

/* --- SCHEMAS (Exposed to avoid circularity with core Schemas module) --- */
open RescriptSchema

let toNullable = (schema: S.t<option<'a>>): S.t<Nullable.t<'a>> => {
  schema->S.transform(_ => {
    parser: (opt: option<'a>) => opt->Nullable.fromOption,
    serializer: (nul: Nullable.t<'a>) => nul->Nullable.toOption,
  })
}

module JsonSchemas = {
  let viewFrame = S.object(s => {
    {
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      hfov: s.field("hfov", S.float),
    }
  })

  let hotspot = S.object(s => {
    {
      linkId: s.field("linkId", S.nullable(S.string)->toNullable),
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      target: s.field("target", S.string),
      targetYaw: s.field("targetYaw", S.nullable(S.float)->toNullable),
      targetPitch: s.field("targetPitch", S.nullable(S.float)->toNullable),
      targetHfov: s.field("targetHfov", S.nullable(S.float)->toNullable),
      startYaw: s.field("startYaw", S.nullable(S.float)->toNullable),
      startPitch: s.field("startPitch", S.nullable(S.float)->toNullable),
      startHfov: s.field("startHfov", S.nullable(S.float)->toNullable),
      isReturnLink: s.field("isReturnLink", S.nullable(S.bool)->toNullable),
      viewFrame: s.field("viewFrame", S.nullable(viewFrame)->toNullable),
      returnViewFrame: s.field("returnViewFrame", S.nullable(viewFrame)->toNullable),
      waypoints: s.field("waypoints", S.nullable(S.array(viewFrame))->toNullable),
      displayPitch: s.field("displayPitch", S.nullable(S.float)->toNullable),
      transition: s.field("transition", S.nullable(S.string)->toNullable),
      duration: s.field("duration", S.nullable(S.float)->toNullable),
    }
  })

  let projectScene = S.object(s => {
    {
      id: s.field("id", S.nullable(S.string)->toNullable),
      name: s.field("name", S.string),
      file: s.field("file", S.json(~validate=false)),
      tinyFile: s.field("tinyFile", S.nullable(S.json(~validate=false))->toNullable),
      originalFile: s.field("originalFile", S.nullable(S.json(~validate=false))->toNullable),
      hotspots: s.field("hotspots", S.nullable(S.array(hotspot))->toNullable),
      category: s.field("category", S.nullable(S.string)->toNullable),
      floor: s.field("floor", S.nullable(S.string)->toNullable),
      label: s.field("label", S.nullable(S.string)->toNullable),
      quality: s.field("quality", S.nullable(S.json(~validate=false))->toNullable),
      colorGroup: s.field("colorGroup", S.nullable(S.string)->toNullable),
      metadataSource: s.field("_metadataSource", S.nullable(S.string)->toNullable),
      categorySet: s.field("categorySet", S.nullable(S.bool)->toNullable),
      labelSet: s.field("labelSet", S.nullable(S.bool)->toNullable),
      isAutoForward: s.field("isAutoForward", S.nullable(S.bool)->toNullable),
    }
  })

  let project = S.object(s => {
    {
      tourName: s.field("tourName", S.nullable(S.string)->toNullable),
      scenes: s.field("scenes", S.array(projectScene)),
      lastUsedCategory: s.field("lastUsedCategory", S.nullable(S.string)->toNullable),
      exifReport: s.field("exifReport", S.nullable(S.json(~validate=false))->toNullable),
      sessionId: s.field("sessionId", S.nullable(S.string)->toNullable),
    }
  })->S.setName("project")

  let importScene = S.object(s => {
    {
      id: s.field("id", S.string),
      name: s.field("name", S.string),
      preview: s.field("preview", S.json(~validate=false)),
      tiny: s.field("tiny", S.nullable(S.json(~validate=false))->toNullable),
      original: s.field("original", S.nullable(S.json(~validate=false))->toNullable),
      quality: s.field("quality", S.nullable(S.json(~validate=false))->toNullable),
      colorGroup: s.field("colorGroup", S.nullable(S.string)->toNullable),
    }
  })->S.setName("import scene")

  let timelineItem = S.object(s => {
    {
      id: s.field("id", S.string),
      linkId: s.field("linkId", S.string),
      sceneId: s.field("sceneId", S.string),
      targetScene: s.field("targetScene", S.string),
      transition: s.field("transition", S.string),
      duration: s.field("duration", S.int),
    }
  })->S.setName("timeline item")

  let updateMetadata = S.object(s => {
    {
      category: s.field("category", S.nullable(S.string)->toNullable),
      floor: s.field("floor", S.nullable(S.string)->toNullable),
      label: s.field("label", S.nullable(S.string)->toNullable),
      isAutoForward: s.field("isAutoForward", S.nullable(S.bool)->toNullable),
    }
  })

  let timelineUpdate = S.object(s => {
    {
      transition: s.field("transition", S.nullable(S.string)->toNullable),
      duration: s.field("duration", S.nullable(S.int)->toNullable),
    }
  })

  let transitionTarget = S.object(s => {
    {
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
      targetName: s.field("targetName", S.string),
      timelineItemId: s.field("timelineItemId", S.nullable(S.string)->toNullable),
    }
  })

  let arrivalView = S.object(s => {
    {
      yaw: s.field("yaw", S.float),
      pitch: s.field("pitch", S.float),
    }
  })

  let step = S.object(s => {
    {
      idx: s.field("idx", S.int),
      transitionTarget: s.field("transitionTarget", S.nullable(transitionTarget)->toNullable),
      arrivalView: s.field("arrivalView", arrivalView),
    }
  })
}

/* --- DECODERS (Safe: Schema-backed parsers) --- */

let parse = (json: 'any, schema: S.t<'a>): result<'a, string> => {
  try {
    Ok(S.parseOrThrow(json, schema))
  } catch {
  | exn => Error(S.Error.message(Obj.magic(exn)))
  }
}

let castToHotspots = (json: JSON.t): array<hotspotJson> => 
  parse(json, S.array(JsonSchemas.hotspot))->Result.getOr([])

let castToProject = (json: JSON.t): projectJson => 
  parse(json, JsonSchemas.project)->Result.getOr({
    tourName: Nullable.null,
    scenes: [],
    lastUsedCategory: Nullable.null,
    exifReport: Nullable.null,
    sessionId: Nullable.null,
  })

let castToProjectScene = (json: JSON.t): projectSceneJson => 
  parse(json, JsonSchemas.projectScene)->Result.getOr({
    id: Nullable.null,
    name: "Unknown",
    file: JSON.Encode.null,
    tinyFile: Nullable.null,
    originalFile: Nullable.null,
    hotspots: Nullable.null,
    category: Nullable.null,
    floor: Nullable.null,
    label: Nullable.null,
    quality: Nullable.null,
    colorGroup: Nullable.null,
    metadataSource: Nullable.null,
    categorySet: Nullable.null,
    labelSet: Nullable.null,
    isAutoForward: Nullable.null,
  })

let castToImportScene = (json: JSON.t): importSceneJson => 
  parse(json, JsonSchemas.importScene)->Result.getOr({
    id: "",
    name: "Unknown",
    preview: JSON.Encode.null,
    tiny: Nullable.null,
    original: Nullable.null,
    quality: Nullable.null,
    colorGroup: Nullable.null,
  })

let castToTimelineItem = (json: JSON.t): timelineItemJson => 
  parse(json, JsonSchemas.timelineItem)->Result.getOr({
    id: "",
    linkId: "",
    sceneId: "",
    targetScene: "",
    transition: "",
    duration: 0,
  })

let castToUpdateMetadata = (json: JSON.t): updateMetadataJson => 
  parse(json, JsonSchemas.updateMetadata)->Result.getOr({
    category: Nullable.null,
    floor: Nullable.null,
    label: Nullable.null,
    isAutoForward: Nullable.null,
  })

let castToTimelineUpdate = (json: JSON.t): timelineUpdateJson => 
  parse(json, JsonSchemas.timelineUpdate)->Result.getOr({
    transition: Nullable.null,
    duration: Nullable.null,
  })

let castToValidationReport = (json: JSON.t): SharedTypes.validationReport => 
  parse(json, Schemas.Shared.validationReport)->Result.getOr({
    brokenLinksRemoved: 0,
    orphanedScenes: [],
    unusedFiles: [],
    warnings: [],
    errors: [],
  })

let castToMetadataResponse = (json: JSON.t): SharedTypes.metadataResponse => 
  parse(json, Schemas.Shared.metadataResponse)->Result.getOr({
    exif: SharedTypes.defaultExif,
    quality: SharedTypes.defaultQuality("Parsing failed"),
    isOptimized: false,
    checksum: "",
    suggestedName: Nullable.null,
  })

let castToQualityAnalysis = (json: JSON.t): SharedTypes.qualityAnalysis => 
  parse(json, Schemas.Shared.qualityAnalysis)->Result.getOr(SharedTypes.defaultQuality("Parsing failed"))

let castToSimilarityResponse = (json: JSON.t): SharedTypes.similarityResponse => 
  parse(json, Schemas.Shared.similarityResponse)->Result.getOr({
    results: [],
    durationMs: 0.0,
  })

let castToSteps = (json: JSON.t): array<stepJson> => 
  parse(json, S.array(JsonSchemas.step))->Result.getOr([])

let castToExifMetadata = (json: JSON.t): SharedTypes.exifMetadata => 
  parse(json, Schemas.Shared.exifMetadata)->Result.getOr(SharedTypes.defaultExif)

let decodeProject = (json: JSON.t): result<projectJson, string> => 
  parse(json, JsonSchemas.project)

let decodeImportScene = (json: JSON.t): result<importSceneJson, string> => 
  parse(json, JsonSchemas.importScene)

let decodeTimelineItem = (json: JSON.t): result<timelineItemJson, string> => 
  parse(json, JsonSchemas.timelineItem)

let decodeUpdateMetadata = (json: JSON.t): result<updateMetadataJson, string> => 
  parse(json, JsonSchemas.updateMetadata)

let decodeTimelineUpdate = (json: JSON.t): result<timelineUpdateJson, string> => 
  parse(json, JsonSchemas.timelineUpdate)
