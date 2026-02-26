/* src/systems/ProjectConnectivity.res */
open Types

let maxSceneNamesInMessage = 2

let truncateSceneList = (names: array<string>): string => {
  let count = Belt.Array.length(names)
  if count <= maxSceneNamesInMessage {
    names->Array.joinUnsafe(", ")
  } else {
    let shown =
      names->Belt.Array.slice(~offset=0, ~len=maxSceneNamesInMessage)->Array.joinUnsafe(", ")
    shown ++ " +" ++ Belt.Int.toString(count - maxSceneNamesInMessage) ++ " more"
  }
}

type validationError = {
  message: string,
  scenes: string,
  count: int,
}

/**
 * Returns a list of scenes that have no hotspots pointing to valid scenes within the same set.
 * These are "dead ends".
 */
let findScenesWithoutExits = (scenes: array<scene>) => {
  let sceneIds = scenes->Belt.Array.map(s => s.id)->Belt.Set.String.fromArray

  scenes->Belt.Array.keep(s => {
    let hasValidExit = s.hotspots->Belt.Array.some(h => {
      switch h.targetSceneId {
      | Some(tid) => Belt.Set.String.has(sceneIds, tid)
      | None => false
      }
    })
    !hasValidExit
  })
}

/**
 * Validates that all scenes have tags (labels).
 */
let validateTags = (scenes: array<scene>): result<unit, validationError> => {
  let untaggedScenes = scenes->Belt.Array.keep(s => {
    let label = s.label->String.trim
    label == "" || String.toLowerCase(label) == "untagged"
  })

  if Belt.Array.length(untaggedScenes) > 0 {
    let msg =
      "Untagged: " ++
      truncateSceneList(untaggedScenes->Belt.Array.map(s => s.label != "" ? s.label : s.name))
    let sceneNames = truncateSceneList(
      untaggedScenes->Belt.Array.map(s => s.label != "" ? s.label : s.name),
    )
    Error({
      message: msg,
      scenes: sceneNames,
      count: Belt.Array.length(untaggedScenes),
    })
  } else {
    Ok()
  }
}

/**
 * Validates that all scenes in a sequence have exits, except optionally the last one.
 */
let validateConnectivity = (scenes: array<scene>, ~allowLastDeadEnd=true): result<
  unit,
  validationError,
> => {
  let scenesWithoutExits = scenes->Belt.Array.keepWithIndex((s, idx) => {
    let isLastScene = idx == Belt.Array.length(scenes) - 1
    if isLastScene && allowLastDeadEnd {
      false
    } else {
      let hasValidExit = s.hotspots->Belt.Array.some(h => {
        switch h.targetSceneId {
        | Some(tid) => scenes->Belt.Array.some(es => es.id == tid)
        | None => false
        }
      })
      !hasValidExit
    }
  })

  if Belt.Array.length(scenesWithoutExits) > 0 {
    let sceneNames = truncateSceneList(
      scenesWithoutExits->Belt.Array.map(s => s.label != "" ? s.label : s.name),
    )

    let msg = "Missing link: " ++ sceneNames
    Error({
      message: msg,
      scenes: sceneNames,
      count: Belt.Array.length(scenesWithoutExits),
    })
  } else {
    Ok()
  }
}

/**
 * Combined validation for export and teaser generation.
 */
let validateProjectForGeneration = (scenes: array<scene>): result<unit, validationError> => {
  switch validateTags(scenes) {
  | Error(e) => Error(e)
  | Ok() => validateConnectivity(scenes, ~allowLastDeadEnd=true)
  }
}
