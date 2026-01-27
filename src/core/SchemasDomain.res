open RescriptSchema

open Types

let file = S.string->S.transform(_ => {
  parser: s => Url(s),
  serializer: f =>
    switch f {
    | Url(s) => s
    | Blob(_) | File(_) => "" // Should not happen for API responses
    },
})

let viewFrame = S.object(s => {
  {
    yaw: s.field("yaw", S.float),
    pitch: s.field("pitch", S.float),
    hfov: s.field("hfov", S.float),
  }
})

let hotspot = S.object(s => {
  {
    linkId: s.field("linkId", S.option(S.string)->S.Option.getOr("")),
    yaw: s.field("yaw", S.float),
    pitch: s.field("pitch", S.float),
    target: s.field("target", S.string),
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
      S.option(S.float)
      ->S.Option.getOr(0.0)
      ->S.transform(_ => {
        parser: d => Belt.Float.toInt(d),
        serializer: i => Belt.Int.toFloat(i),
      })
      ->S.option,
    ),
  }
})

let scene = S.object(s => {
  {
    id: s.field("id", S.option(S.string)->S.Option.getOr("")),
    name: s.field("name", S.string),
    file: s.field("file", file),
    tinyFile: s.field("tinyFile", S.option(file)),
    originalFile: s.field("originalFile", S.option(file)),
    hotspots: s.field("hotspots", S.option(S.array(hotspot))->S.Option.getOr([])),
    category: s.field("category", S.option(S.string)->S.Option.getOr("outdoor")),
    floor: s.field("floor", S.option(S.string)->S.Option.getOr("ground")),
    label: s.field("label", S.option(S.string)->S.Option.getOr("")),
    quality: s.field("quality", S.option(S.json(~validate=false))),
    colorGroup: s.field("colorGroup", S.option(S.string)),
    _metadataSource: s.field("_metadataSource", S.option(S.string)->S.Option.getOr("user")),
    categorySet: s.field("categorySet", S.option(S.bool)->S.Option.getOr(false)),
    labelSet: s.field("labelSet", S.option(S.bool)->S.Option.getOr(false)),
    isAutoForward: s.field("isAutoForward", S.option(S.bool)->S.Option.getOr(false)),
  }
})->S.transform(_ => {
  parser: s => {
    if s.id == "" {
      {...s, id: "legacy_" ++ s.name}
    } else {
      s
    }
  },
  serializer: s => s,
})

let project: S.t<Types.project> = S.object(s => {
  {
    tourName: s.field("tourName", S.option(S.string)->S.Option.getOr("Tour Name")),
    scenes: s.field("scenes", S.array(scene)),
    lastUsedCategory: s.field("lastUsedCategory", S.option(S.string)->S.Option.getOr("outdoor")),
    exifReport: s.field("exifReport", S.option(S.json(~validate=false))),
    sessionId: s.field("sessionId", S.option(S.string)),
  }
})

let importScene = S.object(s => {
  {
    id: s.field("id", S.string),
    name: s.field("name", S.string),
    file: s.field("preview", file),
    tinyFile: s.field("tiny", S.option(file)),
    originalFile: s.field("original", S.option(file)),
    hotspots: [],
    category: "outdoor",
    floor: "ground",
    label: "",
    quality: s.field("quality", S.option(S.json(~validate=false))),
    colorGroup: s.field("colorGroup", S.option(S.string)),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
  }
})

let timelineItem = S.object(s => {
  {
    id: s.field("id", S.string),
    linkId: s.field("linkId", S.string),
    sceneId: s.field("sceneId", S.string),
    targetScene: s.field("targetScene", S.string),
    transition: s.field("transition", S.string),
    duration: s.field("duration", S.int),
  }
})

let updateMetadata: S.t<Types.updateMetadata> = S.object(s => {
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
    duration: s.field("duration", S.option(S.option(S.int))),
  }
})

let transitionTarget = S.object(s => {
  {
    yaw: s.field("yaw", S.float),
    pitch: s.field("pitch", S.float),
    targetName: s.field("targetName", S.string),
    timelineItemId: s.field("timelineItemId", S.option(S.string)),
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
    transitionTarget: s.field("transitionTarget", S.option(transitionTarget)),
    arrivalView: s.field("arrivalView", arrivalView),
  }
})
