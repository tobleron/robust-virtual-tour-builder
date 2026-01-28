open RescriptSchema

module Shared = SchemasShared
module Domain = SchemasDomain

/* --- API Response Cast Helpers --- */

let parse = (json: JSON.t, schema: S.t<'a>): result<'a, string> => {
  try {
    Ok(S.parseOrThrow(json, schema))
  } catch {
  | exn => {
      let msg = S.Error.message(Obj.magic(exn))
      Error(msg)
    }
  }
}

let castToValidationReport = (json: JSON.t): SharedTypes.validationReport => {
  switch parse(json, Shared.validationReport) {
  | Ok(v) => v
  | Error(_) => {
      brokenLinksRemoved: 0,
      orphanedScenes: [],
      unusedFiles: [],
      warnings: [],
      errors: [],
    }
  }
}

let castToMetadataResponse = (json: JSON.t): SharedTypes.metadataResponse =>
  switch parse(json, Shared.metadataResponse) {
  | Ok(v) => v
  | Error(_) => {
      exif: SharedTypes.defaultExif,
      quality: SharedTypes.defaultQuality("Parsing failed"),
      isOptimized: false,
      checksum: "",
      suggestedName: Nullable.null,
    }
  }

let castToQualityAnalysis = (json: JSON.t): SharedTypes.qualityAnalysis =>
  switch parse(json, Shared.qualityAnalysis) {
  | Ok(v) => v
  | Error(_) => SharedTypes.defaultQuality("Parsing failed")
  }

let castToSimilarityResponse = (json: JSON.t): SharedTypes.similarityResponse =>
  switch parse(json, Shared.similarityResponse) {
  | Ok(v) => v
  | Error(_) => {
      results: [],
      durationMs: 0.0,
    }
  }

let castToExifMetadata = (json: JSON.t): SharedTypes.exifMetadata =>
  switch parse(json, Shared.exifMetadata) {
  | Ok(v) => v
  | Error(_) => SharedTypes.defaultExif
  }

let sanitizeScene = (s: Types.scene): Types.scene => {
  if s.id == "" {
    {...s, id: "legacy_" ++ s.name}
  } else {
    s
  }
}

let castToProjectScene = (json: JSON.t): Types.scene =>
  switch parse(json, Domain.scene) {
  | Ok(v) => sanitizeScene(v)
  | Error(_) => {
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

let castToProject = (json: JSON.t): Types.state => {
  switch parse(json, Domain.project) {
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
  | Error(_) => State.initialState
  }
}

let castToSteps = (json: JSON.t): array<Types.step> =>
  switch parse(json, S.array(Domain.step)) {
  | Ok(v) => v
  | Error(_) => []
  }

let castToImportScene = (json: JSON.t): Types.scene =>
  switch parse(json, Domain.importScene) {
  | Ok(v) => sanitizeScene(v)
  | Error(_) => {
      id: "error",
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
