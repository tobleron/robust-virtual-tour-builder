/* @efficiency-role: data-model */

open JsonCombinators.Json

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

let opt = (f: Decode.fieldDecoders, key, decoder, default) => {
  f.optional(key, option(decoder))->Option.flatMap(x => x)->Option.getOr(default)
}

external unsafeCastToFile: JSON.t => ReBindings.File.t = "%identity"
external unsafeCastToBlob: JSON.t => ReBindings.Blob.t = "%identity"

let decodeFile = json => {
  switch JsonCombinators.Json.decode(json, string) {
  | Ok(s) => Types.Url(s)
  | Error(_) =>
    if %raw("(t => t instanceof File)")(json) {
      Types.File(unsafeCastToFile(json))
    } else if %raw("(t => t instanceof Blob)")(json) {
      Types.Blob(unsafeCastToBlob(json))
    } else {
      Console.warn2("File Decoder Fallback triggered for:", json)
      Types.Url("")
    }
  }
}

let file = id->map(json => decodeFile(json))

let normalizeLogo = (logoOpt: option<Types.file>): option<Types.file> => {
  switch logoOpt {
  | Some(Types.Url(u)) if u == "" => None
  | _ => logoOpt
  }
}

let decodeViewFrame = (f: Decode.fieldDecoders) => {
  {
    Types.yaw: f->opt("yaw", float, 0.0),
    pitch: f->opt("pitch", float, 0.0),
    hfov: f->opt("hfov", float, 0.0),
  }
}

let viewFrame = object(f => decodeViewFrame(f))

let decodeHotspot = (f: Decode.fieldDecoders) => {
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
    viewFrame: f.optional("viewFrame", option(viewFrame))->Option.flatMap(x => x),
    waypoints: f.optional("waypoints", option(array(viewFrame)))->Option.flatMap(x => x),
    displayPitch: f.optional("displayPitch", option(float))->Option.flatMap(x => x),
    transition: f.optional("transition", option(string))->Option.flatMap(x => x),
    duration: f.optional("duration", option(float))
    ->Option.flatMap(x => x)
    ->Option.map(Belt.Float.toInt),
    isAutoForward: f.optional("isAutoForward", option(bool))->Option.flatMap(x => x),
    sequenceOrder: f.optional("sequenceOrder", option(int))->Option.flatMap(x => x),
  }
}

let hotspot = object(f => decodeHotspot(f))

let decodeScene = (f: Decode.fieldDecoders) => {
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
    sequenceId: f.optional("sequenceId", int)->Option.getOr(0),
  }
}

let scene = object(f => decodeScene(f))

let decodeTimelineItem = (f: Decode.fieldDecoders) => {
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
}

let timelineItem = object(f => decodeTimelineItem(f))

let decodeSceneStatus = json => {
  switch JsonCombinators.Json.decode(json, string) {
  | Ok(s) =>
    if s == "Active" {
      Types.Active
    } else {
      Types.Deleted(0.0)
    }
  | Error(_) =>
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
}

let sceneStatus = map(id, json => decodeSceneStatus(json))

let decodeSceneEntry = (field: Decode.fieldDecoders) => {
  {
    Types.scene: field.required("scene", scene),
    status: field.required("status", sceneStatus),
  }
}

let sceneEntry = object(field => decodeSceneEntry(field))

let decodeInventoryEntry = (field: Decode.fieldDecoders) => {
  (field.required("id", string), field.required("entry", sceneEntry))
}

let inventoryEntry = object(field => decodeInventoryEntry(field))

let decodeInventory = items => {
  items->Belt.Array.reduce(Belt.Map.String.empty, (acc, item) => {
    switch JsonCombinators.Json.decode(item, inventoryEntry) {
    | Ok((id, entry)) => acc->Belt.Map.String.set(id, entry)
    | Error(_) => acc
    }
  })
}

let inventory = array(id)->map(items => decodeInventory(items))

let decodeProject = (f: Decode.fieldDecoders) => {
  let robustScenes = map(array(id), items => {
    items->Belt.Array.keepMap(item => {
      switch JsonCombinators.Json.decode(item, scene) {
      | Ok(sceneValue) => Some(sceneValue)
      | Error(_) => None
      }
    })
  })
  let scenes = f->opt("scenes", robustScenes, [])
  let inventoryOpt = f->opt("inventory", inventory, Belt.Map.String.empty)
  let sceneOrderOpt = f->opt("sceneOrder", array(string), [])

  let (finalInventory, finalOrder) = if (
    !Belt.Map.String.isEmpty(inventoryOpt) && Array.length(sceneOrderOpt) > 0
  ) {
    (inventoryOpt, sceneOrderOpt)
  } else {
    let inv = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, sceneValue) => {
      let id = if sceneValue.id == "" {
        "legacy_" ++ sceneValue.name
      } else {
        sceneValue.id
      }
      acc->Belt.Map.String.set(id, {Types.scene: {...sceneValue, id}, status: Types.Active})
    })
    let order = scenes->Belt.Array.map(sceneValue => {
      if sceneValue.id == "" {
        "legacy_" ++ sceneValue.name
      } else {
        sceneValue.id
      }
    })
    (inv, order)
  }

  {
    Types.tourName: f
    ->opt("tourName", string, "Untitled Tour")
    ->(value => value == "" ? "Untitled Tour" : value),
    inventory: finalInventory,
    sceneOrder: finalOrder,
    lastUsedCategory: f->opt("lastUsedCategory", string, "outdoor"),
    exifReport: f.optional("exifReport", id),
    sessionId: f.optional("sessionId", option(string))->Option.flatMap(x => x),
    timeline: f->opt("timeline", array(timelineItem), []),
    logo: f.optional("logo", option(file))->Option.flatMap(x => x)->normalizeLogo,
    marketingComment: f->opt("marketingComment", string, ""),
    marketingPhone1: f->opt("marketingPhone1", string, ""),
    marketingPhone2: f->opt("marketingPhone2", string, ""),
    marketingForRent: f->opt("marketingForRent", bool, false),
    marketingForSale: f->opt("marketingForSale", bool, false),
    nextSceneSequenceId: f.optional("nextSceneSequenceId", int)->Option.getOr(1),
  }
}

let project = object(f => decodeProject(f))
