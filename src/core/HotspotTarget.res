open Types

let normalizeRef = (value: string): string =>
  value
  ->String.trim
  ->String.replaceRegExp(/\\/g, "/")
  ->String.replaceRegExp(/^\.\//, "")
  ->String.replaceRegExp(/^\//, "")
  ->String.replaceRegExp(/^assets\/images\//, "")

let canonicalRef = (value: string): string =>
  value->normalizeRef->UrlUtils.stripExtension->String.toLowerCase

let sceneMatchesRef = (scene: scene, refValue: string): bool => {
  let normalized = canonicalRef(refValue)
  if normalized == "" {
    false
  } else {
    canonicalRef(scene.id) == normalized || canonicalRef(scene.name) == normalized
  }
}

let resolveScene = (scenes: array<scene>, hotspot: hotspot): option<scene> => {
  let byId = switch hotspot.targetSceneId {
  | Some(targetSceneId) => scenes->Belt.Array.getBy(scene => sceneMatchesRef(scene, targetSceneId))
  | None => None
  }
  switch byId {
  | Some(scene) => Some(scene)
  | None => scenes->Belt.Array.getBy(scene => sceneMatchesRef(scene, hotspot.target))
  }
}

let resolveSceneId = (scenes: array<scene>, hotspot: hotspot): option<string> =>
  resolveScene(scenes, hotspot)->Option.map(scene => scene.id)

let resolveSceneIndex = (scenes: array<scene>, hotspot: hotspot): option<int> =>
  resolveSceneId(scenes, hotspot)->Option.flatMap(sceneId =>
    scenes->Belt.Array.getIndexBy(scene => scene.id == sceneId)
  )

let pointsToScene = (hotspot: hotspot, scene: scene): bool => {
  let byId = switch hotspot.targetSceneId {
  | Some(targetSceneId) => sceneMatchesRef(scene, targetSceneId)
  | None => false
  }
  byId || sceneMatchesRef(scene, hotspot.target)
}

let withCanonicalTargetId = (scenes: array<scene>, hotspot: hotspot): hotspot =>
  switch resolveSceneId(scenes, hotspot) {
  | Some(targetSceneId) => {...hotspot, targetSceneId: Some(targetSceneId)}
  | None => hotspot
  }

let hydrateSceneHotspots = (allScenes: array<scene>, current: scene): scene => {
  let hotspots = current.hotspots->Belt.Array.map(h => withCanonicalTargetId(allScenes, h))
  {...current, hotspots}
}

let hydrateScenesHotspots = (scenes: array<scene>): array<scene> =>
  scenes->Belt.Array.map(scene => hydrateSceneHotspots(scenes, scene))
