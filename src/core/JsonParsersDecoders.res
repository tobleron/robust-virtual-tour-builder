/* src/core/JsonParsersDecoders.res */
/* @efficiency-role: data-model */

open JsonCombinators.Json

// Utility alias for the extracted shared parsers
module Shared = JsonParsersShared

type updateHotspotMetadata = {isAutoForward: option<bool>}

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

external unsafeCastToFile: JSON.t => ReBindings.File.t = "%identity"
external unsafeCastToBlob: JSON.t => ReBindings.Blob.t = "%identity"
external unsafeCastToString: JSON.t => string = "%identity"

let file = id->map(json => {
  if %raw("(t => typeof t === 'string')")(json) {
    Types.Url(unsafeCastToString(json))
  } else if %raw("(t => t instanceof File)")(json) {
    Types.File(unsafeCastToFile(json))
  } else if %raw("(t => t instanceof Blob)")(json) {
    Types.Blob(unsafeCastToBlob(json))
  } else {
    Console.warn2("File Decoder Fallback triggered for:", json)
    Types.Url("")
  }
})

let normalizeLogo = (logoOpt: option<Types.file>): option<Types.file> => {
  switch logoOpt {
  | Some(Types.Url(u)) if u == "" => None
  | _ => logoOpt
  }
}

let viewFrame = object(f => {
  {
    Types.yaw: f->opt("yaw", float, 0.0),
    pitch: f->opt("pitch", float, 0.0),
    hfov: f->opt("hfov", float, 0.0),
  }
})

let hotspot = object(f => {
  {
    Types.linkId: f->opt("linkId", string, ""),
    yaw: f->opt("yaw", float, 0.0),
    pitch: f->opt("pitch", float, 0.0),
    target: f->opt("target", string, ""),
    targetSceneId: f.optional("targetSceneId", option(string))->Option.flatMap(x => x),
    targetYaw: f.optional("targetYaw", option(float))->Option.flatMap(x => x),
    targetPitch: f.optional("targetPitch", option(float))->Option.flatMap(x => x),
    targetHfov: f.optional("targetHfov", option(float))->Option.flatMap(x => x),
    startYaw: f.optional("startYaw", option(float))->Option.flatMap(x => x),
    startPitch: f.optional("startPitch", option(float))->Option.flatMap(x => x),
    startHfov: f.optional("startHfov", option(float))->Option.flatMap(x => x),
    isReturnLink: f.optional("isReturnLink", option(bool))->Option.flatMap(x => x),
    viewFrame: f.optional("viewFrame", option(viewFrame))->Option.flatMap(x => x),
    returnViewFrame: f.optional("returnViewFrame", option(viewFrame))->Option.flatMap(x => x),
    waypoints: f.optional("waypoints", option(array(viewFrame)))->Option.flatMap(x => x),
    displayPitch: f.optional("displayPitch", option(float))->Option.flatMap(x => x),
    transition: f.optional("transition", option(string))->Option.flatMap(x => x),
    duration: f.optional("duration", option(float))
    ->Option.flatMap(x => x)
    ->Option.map(Belt.Float.toInt),
    isAutoForward: f.optional("isAutoForward", option(bool))->Option.flatMap(x => x),
  }
})

let scene = object(f => {
  let cat = f.optional("category", string)
  let lbl = f.optional("label", string)
  {
    Types.id: f->opt("id", string, ""),
    name: f.required("name", string),
    file: f->opt("file", file, Types.Url("")),
    tinyFile: f.optional("tinyFile", option(file))->Option.flatMap(x => x),
    originalFile: f.optional("originalFile", option(file))->Option.flatMap(x => x),
    hotspots: f->opt("hotspots", array(hotspot), []),
    category: cat->Option.getOr("outdoor"),
    floor: f->opt("floor", string, "ground"),
    label: lbl->Option.getOr(""),
    quality: f.optional("quality", id),
    colorGroup: f.optional("colorGroup", option(string))->Option.flatMap(x => x),
    _metadataSource: f->opt("_metadataSource", string, "user"),
    categorySet: f.optional("categorySet", bool)->Option.getOr(cat->Option.isSome),
    labelSet: f.optional("labelSet", bool)->Option.getOr(lbl->Option.isSome),
    isAutoForward: f->opt("isAutoForward", bool, false),
  }
})

let timelineItem = object(f => {
  {
    Types.id: f->opt("id", string, ""),
    linkId: f->opt("linkId", string, ""),
    sceneId: f->opt("sceneId", string, ""),
    targetScene: f->opt("targetScene", string, ""),
    transition: f->opt("transition", string, ""),
    duration: f.optional("duration", option(float))
    ->Option.flatMap(x => x)
    ->Option.map(Belt.Float.toInt)
    ->Option.getOr(0),
  }
})

let sceneStatus = map(id, json => {
  let isString = %raw("(t => typeof t === 'string')")(json)
  if isString {
    // Safe decoder for string type instead of Obj.magic
    switch JsonCombinators.Json.decode(json, string) {
    | Ok(s) =>
      if s == "Active" {
        Types.Active
      } else {
        Types.Deleted(0.0)
      }
    | Error(_) => Types.Active
    }
  } else {
    let raw = JsonCombinators.Json.decode(
      json,
      object(f => {
        let statusStr = f.required("status", string)
        let ts = f.optional("timestamp", float)->Option.getOr(0.0)
        (statusStr, ts)
      }),
    )
    switch raw {
    | Ok(("Deleted", ts)) => Types.Deleted(ts)
    | _ => Types.Active
    }
  }
})

let sceneEntry = object(field => {
  {
    Types.scene: field.required("scene", scene),
    status: field.required("status", sceneStatus),
  }
})

let inventoryEntry = object(field => {
  (field.required("id", string), field.required("entry", sceneEntry))
})

let inventory = array(id)->map(items => {
  items->Belt.Array.reduce(Belt.Map.String.empty, (acc, item) => {
    switch JsonCombinators.Json.decode(item, inventoryEntry) {
    | Ok((id, entry)) => acc->Belt.Map.String.set(id, entry)
    | Error(_) => acc
    }
  })
})

let project = object(f => {
  let robustScenes = map(array(id), items => {
    items->Belt.Array.keepMap(
      item => {
        switch JsonCombinators.Json.decode(item, scene) {
        | Ok(s) => Some(s)
        | Error(_) => None
        }
      },
    )
  })
  let scenes = f->opt("scenes", robustScenes, [])
  let inventoryOpt = f->opt("inventory", inventory, Belt.Map.String.empty)
  let sceneOrderOpt = f->opt("sceneOrder", array(string), [])

  let (finalInventory, finalOrder) = if (
    !Belt.Map.String.isEmpty(inventoryOpt) && Array.length(sceneOrderOpt) > 0
  ) {
    (inventoryOpt, sceneOrderOpt)
  } else {
    // Migrate from legacy scenes with robustness: ensure IDs are never empty
    let inv = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) => {
      let id = if s.id == "" {
        "legacy_" ++ s.name
      } else {
        s.id
      }
      acc->Belt.Map.String.set(id, {Types.scene: {...s, id}, status: Types.Active})
    })
    let order = scenes->Belt.Array.map(s => {
      if s.id == "" {
        "legacy_" ++ s.name
      } else {
        s.id
      }
    })
    (inv, order)
  }

  {
    Types.tourName: f
    ->opt("tourName", string, "Untitled Tour")
    ->(s => s == "" ? "Untitled Tour" : s),
    scenes,
    inventory: finalInventory,
    sceneOrder: finalOrder,
    lastUsedCategory: f->opt("lastUsedCategory", string, "outdoor"),
    exifReport: f.optional("exifReport", id),
    sessionId: f.optional("sessionId", option(string))->Option.flatMap(x => x),
    deletedSceneIds: f->opt("deletedSceneIds", array(string), []),
    timeline: f->opt("timeline", array(timelineItem), []),
    logo: f.optional("logo", option(file))->Option.flatMap(x => x)->normalizeLogo,
  }
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

let manifestStepTransition = object(f => {
  {
    SimulationManifest.targetSceneId: f.required("targetSceneId", string),
    targetIndex: f.required("targetIndex", int),
    hotspotIndex: f.required("hotspotIndex", int),
    targetYaw: f.required("targetYaw", float),
    targetPitch: f.required("targetPitch", float),
    targetHfov: f.required("targetHfov", float),
  }
})

let manifestStepAction = object(f => {
  let type_ = f.required("type", string)
  switch type_ {
  | "Wait" => SimulationManifest.Wait({duration: f.required("duration", int)})
  | "Pan" =>
    SimulationManifest.Pan({
      yaw: f.required("yaw", float),
      pitch: f.required("pitch", float),
      duration: f.required("duration", int),
    })
  | "Stop" => SimulationManifest.Stop
  | _ => SimulationManifest.Stop
  }
})

let manifestStep = object(f => {
  {
    SimulationManifest.sceneId: f.required("sceneId", string),
    sceneIndex: f.required("sceneIndex", int),
    action: f.required("action", manifestStepAction),
    transition: f.optional("transition", option(manifestStepTransition))->Option.flatMap(x => x),
  }
})

let manifest = object(f => {
  {
    SimulationManifest.version: f.required("version", int),
    steps: f.required("steps", array(manifestStep)),
  }
})
