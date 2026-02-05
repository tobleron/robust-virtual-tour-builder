/* src/core/JsonParsersDecoders.res */
/* @efficiency-role: data-model */

open JsonCombinators.Json

// Utility alias for the extracted shared parsers
module Shared = JsonParsersShared

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

// Helper for cleaner optional fields
let opt = (field: Decode.fieldDecoders, key, decoder, default) => {
  field.optional(key, option(decoder))->Option.flatMap(x => x)->Option.getOr(default)
}

let file = id->map(json => {
  if %raw("(t => typeof t === 'string')")(json) {
    Types.Url(Obj.magic(json))
  } else if %raw("(t => t instanceof File)")(json) {
    Types.File(Obj.magic(json))
  } else if %raw("(t => t instanceof Blob)")(json) {
    Types.Blob(Obj.magic(json))
  } else {
    Types.Url("")
  }
})

let viewFrame = object(field => {
  {
    Types.yaw: field->opt("yaw", float, 0.0),
    pitch: field->opt("pitch", float, 0.0),
    hfov: field->opt("hfov", float, 0.0),
  }
})

let hotspot = object(field => {
  {
    Types.linkId: field->opt("linkId", string, ""),
    yaw: field->opt("yaw", float, 0.0),
    pitch: field->opt("pitch", float, 0.0),
    target: field->opt("target", string, ""),
    targetYaw: field.optional("targetYaw", option(float))->Option.flatMap(x => x),
    targetPitch: field.optional("targetPitch", option(float))->Option.flatMap(x => x),
    targetHfov: field.optional("targetHfov", option(float))->Option.flatMap(x => x),
    startYaw: field.optional("startYaw", option(float))->Option.flatMap(x => x),
    startPitch: field.optional("startPitch", option(float))->Option.flatMap(x => x),
    startHfov: field.optional("startHfov", option(float))->Option.flatMap(x => x),
    isReturnLink: field.optional("isReturnLink", option(bool))->Option.flatMap(x => x),
    viewFrame: field.optional("viewFrame", option(viewFrame))->Option.flatMap(x => x),
    returnViewFrame: field.optional("returnViewFrame", option(viewFrame))->Option.flatMap(x => x),
    waypoints: field.optional("waypoints", option(array(viewFrame)))->Option.flatMap(x => x),
    displayPitch: field.optional("displayPitch", option(float))->Option.flatMap(x => x),
    transition: field.optional("transition", option(string))->Option.flatMap(x => x),
    duration: field.optional("duration", option(float))
    ->Option.flatMap(x => x)
    ->Option.map(Belt.Float.toInt),
  }
})

let scene = object(field => {
  {
    Types.id: field->opt("id", string, ""),
    name: field->opt("name", string, "unknown"),
    file: field.optional("file", option(file))
    ->Option.flatMap(x => x)
    ->Option.getOr(Types.Url("")),
    tinyFile: field.optional("tinyFile", option(file))->Option.flatMap(x => x),
    originalFile: field.optional("originalFile", option(file))->Option.flatMap(x => x),
    hotspots: field->opt("hotspots", array(hotspot), []),
    category: field->opt("category", string, "outdoor"),
    floor: field->opt("floor", string, "ground"),
    label: field->opt("label", string, ""),
    quality: field.optional("quality", id),
    colorGroup: field.optional("colorGroup", option(string))->Option.flatMap(x => x),
    _metadataSource: field->opt("_metadataSource", string, "user"),
    categorySet: field->opt("categorySet", bool, false),
    labelSet: field->opt("labelSet", bool, false),
    isAutoForward: field->opt("isAutoForward", bool, false),
  }
})

let timelineItem = object(field => {
  {
    Types.id: field->opt("id", string, ""),
    linkId: field->opt("linkId", string, ""),
    sceneId: field->opt("sceneId", string, ""),
    targetScene: field->opt("targetScene", string, ""),
    transition: field->opt("transition", string, ""),
    duration: field.optional("duration", option(float))
    ->Option.flatMap(x => x)
    ->Option.map(Belt.Float.toInt)
    ->Option.getOr(0),
  }
})

let project = object(field => {
  {
    Types.tourName: field->opt("tourName", string, "Tour Name"),
    scenes: field->opt("scenes", array(scene), []),
    lastUsedCategory: field->opt("lastUsedCategory", string, "outdoor"),
    exifReport: field.optional("exifReport", id),
    sessionId: field.optional("sessionId", option(string))->Option.flatMap(x => x),
    deletedSceneIds: field->opt("deletedSceneIds", array(string), []),
    timeline: field->opt("timeline", array(timelineItem), []),
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
    file: field.optional("file", option(file))
    ->Option.flatMap(x => x)
    ->Option.getOr(Types.Url("")),
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

module SessionState = {
  let decode = object(field => {
    {
      Types.tourName: field.required("tourName", string),
      activeIndex: field.required("activeIndex", int),
      activeYaw: field.required("activeYaw", float),
      activePitch: field.required("activePitch", float),
      isLinking: field.required("isLinking", bool),
      isTeasing: field.required("isTeasing", bool),
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
