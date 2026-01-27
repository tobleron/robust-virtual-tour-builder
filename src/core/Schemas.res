open RescriptSchema

module Shared = SchemasShared
module Domain = SchemasDomain

let toNullable = SchemasShared.toNullable

/* --- API Response Cast Helpers --- */

let parse = (json: JSON.t, schema: S.t<'a>): result<'a, string> => {
  try {
    Ok(S.parseOrThrow(json, schema))
  } catch {
  | exn => Error(S.Error.message(Obj.magic(exn)))
  }
}

let castToValidationReport = (json: JSON.t): SharedTypes.validationReport =>
  try {
    S.parseOrThrow(json, Shared.validationReport)
  } catch {
  | _ => {
      brokenLinksRemoved: 0,
      orphanedScenes: [],
      unusedFiles: [],
      warnings: [],
      errors: [],
    }
  }

let castToMetadataResponse = (json: JSON.t): SharedTypes.metadataResponse =>
  try {
    S.parseOrThrow(json, Shared.metadataResponse)
  } catch {
  | _ => {
      exif: SharedTypes.defaultExif,
      quality: SharedTypes.defaultQuality("Parsing failed"),
      isOptimized: false,
      checksum: "",
      suggestedName: Nullable.null,
    }
  }

let castToQualityAnalysis = (json: JSON.t): SharedTypes.qualityAnalysis =>
  try {
    S.parseOrThrow(json, Shared.qualityAnalysis)
  } catch {
  | _ => SharedTypes.defaultQuality("Parsing failed")
  }

let castToSimilarityResponse = (json: JSON.t): SharedTypes.similarityResponse =>
  try {
    S.parseOrThrow(json, Shared.similarityResponse)
  } catch {
  | _ => {
      results: [],
      durationMs: 0.0,
    }
  }

let castToExifMetadata = (json: JSON.t): SharedTypes.exifMetadata =>
  try {
    S.parseOrThrow(json, Shared.exifMetadata)
  } catch {
  | _ => SharedTypes.defaultExif
  }

let castToProject = (json: JSON.t): Types.state => {
  try {
    let pd = S.parseOrThrow(json, Domain.project)
    {
      ...State.initialState,
      tourName: pd.tourName,
      scenes: pd.scenes,
      activeIndex: if Array.length(pd.scenes) > 0 {
        0
      } else {
        -1
      },
      lastUsedCategory: pd.lastUsedCategory,
      exifReport: pd.exifReport,
      sessionId: pd.sessionId,
    }
  } catch {
  | _ => State.initialState
  }
}

let castToSteps = (json: JSON.t): array<Types.step> =>
  try {
    S.parseOrThrow(json, S.array(Domain.step))
  } catch {
  | _ => []
  }

let castToImportScene = (json: JSON.t): Types.scene =>
  try {
    S.parseOrThrow(json, Domain.importScene)
  } catch {
  | _ => {
      id: "error",
      name: "invalid",
      file: Url(""),
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

let castToProjectScene = (json: JSON.t): Types.scene =>
  try {
    S.parseOrThrow(json, Domain.scene)
  } catch {
  | _ => {
      id: "error",
      name: "invalid",
      file: Url(""),
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