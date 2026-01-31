/* src/core/SchemaParsers.res */

open RescriptSchema
open SchemaDefinitions

external asRescriptSchemaError: exn => S.error = "%identity"

let parse = (json: JSON.t, _schema: S.t<'a>): result<'a, string> => {
  // CSP SAFE FIX (NUCLEAR): rescript-schema v9 uses `new Function` (eval) for parsers.
  // We MUST bypass validation to run in strict CSP environments.
  // This disables runtime type validation! We rely on backend sending correct shape.
  try {
    Ok(Obj.magic(json))
  } catch {
  | exn =>
    Error(
      "Unexpected error during unsafe cast: " ++
      JsExn.message(Obj.magic(exn))->Option.getOr("Unknown"),
    )
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

let createDefaultErrorScene = (idPrefix: string, name: string): Types.scene => {
  {
    id: idPrefix ++ Float.toString(Date.now()),
    name,
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

let castToProjectScene = (json: JSON.t): Types.scene =>
  switch parse(json, Domain.scene) {
  | Ok(v) => sanitizeScene(v)
  | Error(_) => createDefaultErrorScene("error_", "invalid")
  }

let createStateFromProjectData = (pd: Types.project): Types.state => {
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

let castToProject = (json: JSON.t): Types.state => {
  switch parse(json, Domain.project) {
  | Ok(pd) => createStateFromProjectData(pd)
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
  | Error(_) => createDefaultErrorScene("error", "invalid")
  }
