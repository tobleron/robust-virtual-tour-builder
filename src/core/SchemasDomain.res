open RescriptSchema
open Types

let file = S.string->S.transform(_ => {
  parser: s => Url(s),
  serializer: f =>
    switch f {
    | Url(s) => s
    | Blob(_) | File(_) => ""
    },
})

let viewFrame = S.object(s => {
  {
    yaw: s.field("yaw", S.option(S.float)->S.Option.getOr(0.0)),
    pitch: s.field("pitch", S.option(S.float)->S.Option.getOr(0.0)),
    hfov: s.field("hfov", S.option(S.float)->S.Option.getOr(0.0)),
  }
})

let hotspot = S.object(s => {
  {
    linkId: s.field("linkId", S.option(S.string)->S.Option.getOr("")),
    yaw: s.field("yaw", S.option(S.float)->S.Option.getOr(0.0)),
    pitch: s.field("pitch", S.option(S.float)->S.Option.getOr(0.0)),
    target: s.field("target", S.option(S.string)->S.Option.getOr("")),
    targetYaw: s.field("targetYaw", S.option(S.float)),
    targetPitch: s.field("targetPitch", S.option(S.float)),
    targetHfov: s.field("targetHfov", S.option(S.float)),
    startYaw: s.field("startYaw", S.option(S.float)),
    startPitch: s.field("startPitch", S.option(S.float)),
    startHfov: s.field("startHfov", S.option(S.float)),
    isReturnLink: s.field("isReturnLink", S.option(S.bool)),
    viewFrame: s.field("viewFrame", S.option(viewFrame)),
    returnViewFrame: s.field("returnViewFrame", S.option(viewFrame)),
    waypoints: s.field("waypoints", S.option(S.array(viewFrame))),
    displayPitch: s.field("displayPitch", S.option(S.float)),
    transition: s.field("transition", S.option(S.string)),
    duration: s.field(
      "duration",
      S.option(S.float)->S.transform(_ => {
        parser: o => o->Option.map(Belt.Float.toInt),
        serializer: o => o->Option.map(Belt.Int.toFloat),
      }),
    ),
  }
})

let scene = S.object(s => {
  {
    id: s.field("id", S.option(S.string)->S.Option.getOr("")),
    name: s.field("name", S.option(S.string)->S.Option.getOr("unknown")),
    file: s.field("file", file),
    tinyFile: s.field("tinyFile", S.option(file)),
    originalFile: s.field("originalFile", S.option(file)),
    hotspots: s.field("hotspots", S.option(S.array(hotspot))->S.Option.getOr([])),
    category: s.field("category", S.option(S.string)->S.Option.getOr("outdoor")),
    floor: s.field("floor", S.option(S.string)->S.Option.getOr("ground")),
    label: s.field("label", S.option(S.string)->S.Option.getOr("")),
    quality: s.field("quality", S.option(S.unknown->(Obj.magic: S.t<unknown> => S.t<JSON.t>))),
    colorGroup: s.field("colorGroup", S.option(S.string)),
    _metadataSource: s.field("_metadataSource", S.option(S.string)->S.Option.getOr("user")),
    categorySet: s.field("categorySet", S.option(S.bool)->S.Option.getOr(false)),
    labelSet: s.field("labelSet", S.option(S.bool)->S.Option.getOr(false)),
    isAutoForward: s.field("isAutoForward", S.option(S.bool)->S.Option.getOr(false)),
  }
})

let timelineItem = S.object(s => {
  {
    id: s.field("id", S.option(S.string)->S.Option.getOr("")),
    linkId: s.field("linkId", S.option(S.string)->S.Option.getOr("")),
    sceneId: s.field("sceneId", S.option(S.string)->S.Option.getOr("")),
    targetScene: s.field("targetScene", S.option(S.string)->S.Option.getOr("")),
    transition: s.field("transition", S.option(S.string)->S.Option.getOr("")),
    duration: s.field(
      "duration",
      S.option(S.float)->S.transform(_ => {
        parser: o => o->Option.map(Belt.Float.toInt)->Option.getOr(0),
        serializer: i => Some(Belt.Int.toFloat(i)),
      }),
    ),
  }
})

let project: S.t<Types.project> = S.object(s => {
  {
    tourName: s.field("tourName", S.option(S.string)->S.Option.getOr("Tour Name")),
    scenes: s.field("scenes", S.option(S.array(scene))->S.Option.getOr([])),
    lastUsedCategory: s.field("lastUsedCategory", S.option(S.string)->S.Option.getOr("outdoor")),
    exifReport: s.field(
      "exifReport",
      S.option(S.unknown->(Obj.magic: S.t<unknown> => S.t<JSON.t>)),
    ),
    sessionId: s.field("sessionId", S.option(S.string)),
    deletedSceneIds: s.field("deletedSceneIds", S.option(S.array(S.string))->S.Option.getOr([])),
    timeline: s.field("timeline", S.option(S.array(timelineItem))->S.Option.getOr([])),
  }
})

let transitionTarget = S.object(s => {
  {
    Types.yaw: s.field("yaw", S.float),
    pitch: s.field("pitch", S.float),
    targetName: s.field("targetName", S.string),
    timelineItemId: s.field("timelineItemId", S.option(S.string)),
  }
})

let arrivalViewSchema = S.object(s => {
  {
    Types.yaw: s.field("yaw", S.float),
    pitch: s.field("pitch", S.float),
  }
})

let step: S.t<Types.step> = S.object(s => {
  {
    idx: s.field("idx", S.int),
    transitionTarget: s.field("transitionTarget", S.option(transitionTarget)),
    arrivalView: s.field("arrivalView", arrivalViewSchema),
  }
})

let importScene = S.object(s => {
  {
    id: s.field("id", S.option(S.string)->S.Option.getOr("")), // Default empty
    name: s.field("name", S.option(S.string)->S.Option.getOr("unknown")), // Default unknown
    file: s.field("file", S.option(file)->S.Option.getOr(Types.Url(""))), // Optional file, default empty Url
    tinyFile: s.field("tinyFile", S.option(file)),
    originalFile: s.field("originalFile", S.option(file)),
    hotspots: s.field("hotspots", S.option(S.array(hotspot))->S.Option.getOr([])),
    category: "outdoor",
    floor: "ground",
    label: "",
    quality: s.field("quality", S.option(S.unknown->(Obj.magic: S.t<unknown> => S.t<JSON.t>))),
    colorGroup: s.field("colorGroup", S.option(S.string)),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
  }
})

let updateMetadata = S.object(s => {
  {
    category: s.field("category", S.option(S.string)),
    floor: s.field("floor", S.option(S.string)),
    label: s.field("label", S.option(S.string)),
    isAutoForward: s.field("isAutoForward", S.option(S.bool)),
  }
})

let timelineUpdate: S.t<Types.timelineUpdate> = S.object(s => {
  {
    transition: s.field("transition", S.option(S.string)),
    duration: s.field("duration",
      S.option(S.null(S.float))->S.transform(_ => {
        parser: o => o->Option.map(innerOpt => innerOpt->Option.map(Belt.Float.toInt)),
        serializer: o => o->Option.map(innerOpt => innerOpt->Option.map(Belt.Int.toFloat))
      })
    ),
  }
})
