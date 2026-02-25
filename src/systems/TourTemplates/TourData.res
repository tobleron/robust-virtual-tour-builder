open Types

@scope("JSON") @val external stringify: 'a => string = "stringify"

external castToJSON: dict<'a> => JSON.t = "%identity"
external castToUnknown: 'a => unknown = "%identity"

type hotspotData = {
  "pitch": float,
  "yaw": float,
  "target": string,
  "targetSceneId": string,
  "targetIsAutoForward": bool,
  "startYaw": Nullable.t<float>,
  "startPitch": Nullable.t<float>,
  "waypoints": Nullable.t<array<viewFrame>>,
  "truePitch": float,
  "viewFrame": Nullable.t<viewFrame>,
  "targetYaw": Nullable.t<float>,
  "targetPitch": Nullable.t<float>,
}

type sceneData = {
  "name": string,
  "panorama": string,
  "autoLoad": bool,
  "floor": string,
  "category": string,
  "label": string,
  "isAutoForward": bool,
  "autoForwardHotspotIndex": int,
  "autoForwardTargetSceneId": string,
  "hotSpots": array<hotspotData>,
  "isHubScene": bool, // Hub scene = 2+ exit links (animates once, shows auto-forward as button)
}

let encodeHotspot = (h: hotspotData) => {
  JsonCombinators.Json.Encode.object([
    ("pitch", JsonCombinators.Json.Encode.float(h["pitch"])),
    ("yaw", JsonCombinators.Json.Encode.float(h["yaw"])),
    ("target", JsonCombinators.Json.Encode.string(h["target"])),
    ("targetSceneId", JsonCombinators.Json.Encode.string(h["targetSceneId"])),
    ("targetIsAutoForward", JsonCombinators.Json.Encode.bool(h["targetIsAutoForward"])),
    (
      "startYaw",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["startYaw"]),
      ),
    ),
    (
      "startPitch",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["startPitch"]),
      ),
    ),
    (
      "waypoints",
      JsonCombinators.Json.Encode.option(
        JsonCombinators.Json.Encode.array(JsonParsers.Encoders.viewFrame),
      )(Nullable.toOption(h["waypoints"])),
    ),
    ("truePitch", JsonCombinators.Json.Encode.float(h["truePitch"])),
    (
      "viewFrame",
      JsonCombinators.Json.Encode.option(JsonParsers.Encoders.viewFrame)(
        Nullable.toOption(h["viewFrame"]),
      ),
    ),
    (
      "targetYaw",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["targetYaw"]),
      ),
    ),
    (
      "targetPitch",
      JsonCombinators.Json.Encode.option(JsonCombinators.Json.Encode.float)(
        Nullable.toOption(h["targetPitch"]),
      ),
    ),
  ])
}

let encodeSceneData = (s: sceneData) => {
  JsonCombinators.Json.Encode.object([
    ("name", JsonCombinators.Json.Encode.string(s["name"])),
    ("panorama", JsonCombinators.Json.Encode.string(s["panorama"])),
    ("autoLoad", JsonCombinators.Json.Encode.bool(s["autoLoad"])),
    ("floor", JsonCombinators.Json.Encode.string(s["floor"])),
    ("category", JsonCombinators.Json.Encode.string(s["category"])),
    ("label", JsonCombinators.Json.Encode.string(s["label"])),
    ("isAutoForward", JsonCombinators.Json.Encode.bool(s["isAutoForward"])),
    ("autoForwardHotspotIndex", JsonCombinators.Json.Encode.int(s["autoForwardHotspotIndex"])),
    ("autoForwardTargetSceneId", JsonCombinators.Json.Encode.string(s["autoForwardTargetSceneId"])),
    ("hotSpots", JsonCombinators.Json.Encode.array(encodeHotspot)(s["hotSpots"])),
    ("isHubScene", JsonCombinators.Json.Encode.bool(s["isHubScene"])),
  ])
}

let normalizeSceneRefForExport = (value: string): string =>
  value
  ->String.trim
  ->String.replaceRegExp(/\\/g, "/")
  ->String.replaceRegExp(/^\.\//, "")
  ->String.replaceRegExp(/^\//, "")
  ->String.replaceRegExp(/^assets\/images\//, "")

let extractScenePrefix = (value: string): option<string> => {
  if String.length(value) >= 3 {
    let prefix = String.substring(value, ~start=0, ~end=3)
    if RegExp.test(/^\d{3}$/, prefix) {
      Some(prefix)
    } else {
      None
    }
  } else {
    None
  }
}

let resolveSceneIdFromTargetRef = (targetRef: string, scenes: array<scene>): option<string> => {
  let normalizedTarget = normalizeSceneRefForExport(targetRef)
  if normalizedTarget == "" {
    None
  } else {
    let targetNoExt = UrlUtils.stripExtension(normalizedTarget)
    let byId =
      scenes
      ->Belt.Array.getBy(s => normalizeSceneRefForExport(s.id) == normalizedTarget)
      ->Option.map(s => s.id)
    switch byId {
    | Some(id) => Some(id)
    | None =>
      let byName =
        scenes
        ->Belt.Array.getBy(s => {
          let sceneName = normalizeSceneRefForExport(s.name)
          let sceneNameNoExt = UrlUtils.stripExtension(sceneName)
          sceneName == normalizedTarget || sceneNameNoExt == targetNoExt
        })
        ->Option.map(s => s.id)
      switch byName {
      | Some(id) => Some(id)
      | None =>
        switch extractScenePrefix(targetNoExt) {
        | Some(prefix) =>
          scenes
          ->Belt.Array.getBy(s => {
            let sceneNoExt = normalizeSceneRefForExport(s.name)->UrlUtils.stripExtension
            sceneNoExt == prefix || String.startsWith(sceneNoExt, prefix ++ "_")
          })
          ->Option.map(s => s.id)
        | None => None
        }
      }
    }
  }
}
