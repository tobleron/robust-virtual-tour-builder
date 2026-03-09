/* src/core/JsonParsersDecoders.res */
/* @efficiency-role: data-model */

open JsonCombinators.Json

// Utility alias for the extracted shared parsers
module Shared = JsonParsersShared

type updateHotspotMetadata = {
  isAutoForward: option<bool>,
  target: option<string>,
  targetSceneId: option<string>,
  sequenceOrder: option<int>,
}

// Aliases
let object = Decode.object
let field = Decode.field
let array = Decode.array
let int = Decode.int
let float = Decode.float
let string = Decode.string
let bool = Decode.bool
let option = Decode.option
let map = Decode.map
let id = Decode.id

type persistedSessionEnvelope = {
  version: int,
  timestamp: float,
  projectData: JSON.t,
}

// Helper for cleaner optional fields
// Helper for cleaner optional fields
let opt = (f: Decode.fieldDecoders, key, decoder, default) => {
  f.optional(key, option(decoder))->Option.flatMap(x => x)->Option.getOr(default)
}

let file = id->map(json => {
  JsonParsersProjectDecoders.decodeFile(json)
})

let normalizeLogo = (logoOpt: option<Types.file>): option<Types.file> => {
  JsonParsersProjectDecoders.normalizeLogo(logoOpt)
}

let viewFrame = object(f => {
  JsonParsersProjectDecoders.decodeViewFrame(f)
})

let hotspot = object(f => {
  JsonParsersProjectDecoders.decodeHotspot(f)
})

let scene = object(f => {
  JsonParsersProjectDecoders.decodeScene(f)
})

let timelineItem = object(f => {
  JsonParsersProjectDecoders.decodeTimelineItem(f)
})

let sceneStatus = map(id, json => {
  JsonParsersProjectDecoders.decodeSceneStatus(json)
})

let sceneEntry = object(field => {
  JsonParsersProjectDecoders.decodeSceneEntry(field)
})

let inventoryEntry = object(field => {
  JsonParsersProjectDecoders.decodeInventoryEntry(field)
})

let inventory = array(id)->map(items => {
  JsonParsersProjectDecoders.decodeInventory(items)
})

let project = object(f => {
  JsonParsersProjectDecoders.decodeProject(f)
})

let persistedSession = object((field): persistedSessionEnvelope => {
  {
    version: field.optional("version", int)->Option.getOr(1),
    timestamp: field.required("timestamp", float),
    projectData: field.required("projectData", id),
  }
})

let transitionTarget = object(field => {
  {
    Types.yaw: field.required("yaw", float),
    pitch: field.required("pitch", float),
    targetName: field.required("targetName", string),
    timelineItemId: field.optional("timelineItemId", option(string))->Option.flatMap(x => x),
  }
})

let arrivalView = object(field => {
  {
    Types.yaw: field.required("yaw", float),
    pitch: field.required("pitch", float),
  }
})

let step = object(field => {
  {
    Types.idx: field.required("idx", int),
    transitionTarget: field.optional(
      "transitionTarget",
      option(transitionTarget),
    )->Option.flatMap(x => x),
    arrivalView: field.required("arrivalView", arrivalView),
  }
})

let steps = array(step)

let importScene = object(field => {
  {
    Types.id: field->opt("id", string, ""),
    name: field->opt("name", string, "unknown"),
    file: field.optional("file", option(file))->Option.flatMap(x => x)->Option.getOr(Types.Url("")),
    tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
    originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
    hotspots: field->opt("hotspots", array(hotspot), []),
    category: "outdoor",
    floor: "ground",
    label: "",
    quality: field.optional("quality", id),
    colorGroup: field.optional("colorGroup", option(string))->Option.flatMap(x => x),
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    sequenceId: field.optional("sequenceId", int)->Option.getOr(0),
  }
})

let updateMetadata = object(field => {
  {
    Types.category: field.optional("category", option(string))->Option.flatMap(x => x),
    floor: field.optional("floor", option(string))->Option.flatMap(x => x),
    label: field.optional("label", option(string))->Option.flatMap(x => x),
    isAutoForward: field.optional("isAutoForward", option(bool))->Option.flatMap(x => x),
  }
})

let updateHotspotMetadata = object(field => {
  {
    isAutoForward: field.optional("isAutoForward", option(bool))->Option.flatMap(x => x),
    target: field.optional("target", option(string))->Option.flatMap(x => x),
    targetSceneId: field.optional("targetSceneId", option(string))->Option.flatMap(x => x),
    sequenceOrder: field.optional("sequenceOrder", option(int))->Option.flatMap(x => x),
  }
})

module SessionState = {
  let decode = object(f => {
    {
      Types.tourName: f.required("tourName", string),
      activeIndex: f.required("activeIndex", int),
      activeYaw: f.required("activeYaw", float),
      activePitch: f.required("activePitch", float),
      isLinking: f.required("isLinking", bool),
      isTeasing: f.required("isTeasing", bool),
      timeline: f->opt("timeline", array(timelineItem), [])->Some,
      activeTimelineStepId: f.optional("activeTimelineStepId", option(string))->Option.flatMap(x =>
        x
      ),
    }
  })

  let encode = (state: Types.sessionState) => {
    Encode.object([
      ("tourName", Encode.string(state.tourName)),
      ("activeIndex", Encode.int(state.activeIndex)),
      ("activeYaw", Encode.float(state.activeYaw)),
      ("activePitch", Encode.float(state.activePitch)),
      ("isLinking", Encode.bool(state.isLinking)),
      ("isTeasing", Encode.bool(state.isTeasing)),
    ])
  }
}

let motionAnimationSegment = object(f => {
  {
    Types.startYaw: f->opt("startYaw", float, 0.0),
    endYaw: f->opt("endYaw", float, 0.0),
    startPitch: f->opt("startPitch", float, 0.0),
    endPitch: f->opt("endPitch", float, 0.0),
    startHfov: f->opt("startHfov", float, 0.0),
    endHfov: f->opt("endHfov", float, 0.0),
    easing: f->opt("easing", string, "linear"),
    durationMs: f->opt("durationMs", int, 0),
  }
})

let motionTransitionOut = object(f => {
  {
    Types.type_: f->opt("type", string, "crossfade"),
    durationMs: f->opt("durationMs", int, 0),
  }
})

let motionShot = object(f => {
  let motionPathPoint = object(pp => {
    {
      Types.yaw: pp->opt("yaw", float, 0.0),
      pitch: pp->opt("pitch", float, 0.0),
    }
  })

  let motionPathSegment = object(ps => {
    {
      Types.dist: ps->opt("dist", float, 0.0),
      yawDiff: ps->opt("yawDiff", float, 0.0),
      pitchDiff: ps->opt("pitchDiff", float, 0.0),
      p1: ps->opt("p1", motionPathPoint, {yaw: 0.0, pitch: 0.0}),
      p2: ps->opt("p2", motionPathPoint, {yaw: 0.0, pitch: 0.0}),
    }
  })

  let motionPathData = object(pd => {
    {
      Types.startPitch: pd->opt("startPitch", float, 0.0),
      startYaw: pd->opt("startYaw", float, 0.0),
      startHfov: pd->opt("startHfov", float, 0.0),
      targetPitchForPan: pd->opt("targetPitchForPan", float, 0.0),
      targetYawForPan: pd->opt("targetYawForPan", float, 0.0),
      targetHfovForPan: pd->opt("targetHfovForPan", float, 0.0),
      totalPathDistance: pd->opt("totalPathDistance", float, 0.0),
      segments: pd->opt("segments", array(motionPathSegment), []),
      waypoints: pd->opt("waypoints", array(motionPathPoint), []),
      panDuration: pd->opt("panDuration", float, 0.0),
      arrivalYaw: pd->opt("arrivalYaw", float, 0.0),
      arrivalPitch: pd->opt("arrivalPitch", float, 0.0),
      arrivalHfov: pd->opt("arrivalHfov", float, 0.0),
    }
  })

  {
    Types.sceneId: f->opt("sceneId", string, ""),
    arrivalPose: f->opt("arrivalPose", viewFrame, {yaw: 0.0, pitch: 0.0, hfov: 0.0}),
    animationSegments: f->opt("animationSegments", array(motionAnimationSegment), []),
    transitionOut: f.optional("transitionOut", option(motionTransitionOut))->Option.flatMap(x => x),
    pathData: f.optional("pathData", option(motionPathData))->Option.flatMap(x => x),
    waitBeforePanMs: f->opt("waitBeforePanMs", int, 0),
    blinkAfterPanMs: f->opt("blinkAfterPanMs", int, 0),
  }
})

let motionManifest = object(f => {
  {
    Types.version: f->opt("version", string, "motion-spec-v1"),
    fps: f->opt("fps", int, 60),
    canvasWidth: f->opt("canvasWidth", int, 1920),
    canvasHeight: f->opt("canvasHeight", int, 1080),
    includeIntroPan: f->opt("includeIntroPan", bool, false),
    shots: f->opt("shots", array(motionShot), []),
  }
})
