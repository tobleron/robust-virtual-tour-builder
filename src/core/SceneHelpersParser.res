open Types

let sanitizeScene = (s: scene): scene => {
  if s.id == "" {
    {...s, id: "legacy_" ++ s.name}
  } else {
    s
  }
}

let parseScene = (dataJson: JSON.t): scene => {
  switch Schemas.parse(dataJson, Schemas.Domain.scene) {
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

let parseProject = (projectDataJson: JSON.t): state => {
  switch Schemas.parse(projectDataJson, Schemas.Domain.project) {
  | Ok(pd) => {
      let scenes = pd.scenes->Belt.Array.map(sanitizeScene)
      {
        ...State.initialState,
        tourName: pd.tourName,
        scenes,
        activeIndex: if Array.length(scenes) > 0 {
          0
        } else {
          -1
        },
        lastUsedCategory: pd.lastUsedCategory,
        exifReport: pd.exifReport,
        sessionId: pd.sessionId,
        deletedSceneIds: pd.deletedSceneIds,
        timeline: pd.timeline,
      }
    }
  | Error(msg) =>
    Logger.error(
      ~module_="SceneHelpersParser",
      ~message="SCHEMA_PARSE_ERROR_PROJECT",
      ~data=Logger.castToJson({"error": msg}),
      (),
    )
    State.initialState
  }
}
