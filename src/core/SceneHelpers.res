/* src/core/SceneHelpers.res */

open Types

// --- Parser ---

let sanitizeScene = (s: scene): scene => {
  if s.id == "" {
    {...s, id: "legacy_" ++ s.name}
  } else {
    s
  }
}

let parseScene = (dataJson: JSON.t): scene => {
  switch JsonCombinators.Json.decode(dataJson, JsonParsers.Domain.scene) {
  | Ok(data) => sanitizeScene(data)
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_SCENE",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    {
      id: "error_" ++ Float.toString(Date.now()),
      name: "invalid",
      file: Types.Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "default",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }
  }
}

let parseProject = (projectDataJson: JSON.t): result<project, string> => {
  switch JsonCombinators.Json.decode(projectDataJson, JsonParsers.Domain.project) {
  | Ok(pd) =>
    Ok({
      tourName: pd.tourName,
      scenes: pd.scenes->Belt.Array.map(sanitizeScene),
      inventory: pd.inventory,
      sceneOrder: pd.sceneOrder,
      lastUsedCategory: pd.lastUsedCategory,
      exifReport: pd.exifReport,
      sessionId: pd.sessionId,
      deletedSceneIds: pd.deletedSceneIds,
      timeline: pd.timeline,
    })
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_PROJECT",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    Error(msg)
  }
}
