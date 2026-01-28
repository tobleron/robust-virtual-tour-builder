open RescriptSchema
open SharedTypes

let toNullable = (schema: S.t<option<'a>>): S.t<Nullable.t<'a>> => {
  schema->S.transform(_ => {
    parser: (opt: option<'a>) => opt->Nullable.fromOption,
    serializer: (nul: Nullable.t<'a>) => nul->Nullable.toOption,
  })
}

let gpsData: S.t<gpsData> = S.object(s => {
  {
    lat: s.field("lat", S.float),
    lon: s.field("lon", S.float),
  }
})

let exifMetadata: S.t<exifMetadata> = S.object(s => {
  {
    dateTime: s.field("date", S.nullable(S.string)->toNullable),
    gps: s.field("gps", S.nullable(gpsData)->toNullable),
    make: s.field("cameraModel", S.nullable(S.string)->toNullable),
    model: s.field("lensModel", S.nullable(S.string)->toNullable),
    width: 0,
    height: 0,
    focalLength: s.field("focalLength", S.nullable(S.float)->toNullable),
    aperture: s.field("fNumber", S.nullable(S.float)->toNullable),
    iso: s.field("iso", S.nullable(S.int)->toNullable),
  }
})

let metadataResponse: S.t<metadataResponse> = S.object(s => {
  {
    exif: s.field("exif", exifMetadata),
    quality: s.field("quality", S.unknown->(Obj.magic: S.t<unknown> => S.t<qualityAnalysis>)),
    isOptimized: s.field("isOptimized", S.bool),
    checksum: s.field("checksum", S.string),
    suggestedName: s.field("suggestedName", S.nullable(S.string)->toNullable),
  }
})

let similarityResult: S.t<similarityResult> = S.object(s => {
  {
    idA: s.field("sceneId", S.string),
    idB: "",
    similarity: s.field("score", S.float),
  }
})

let similarityResponse: S.t<similarityResponse> = S.object(s => {
  {
    results: s.field("results", S.array(similarityResult)),
    durationMs: s.field("durationMs", S.float),
  }
})

let validationReport: S.t<validationReport> = S.object(s => {
  {
    brokenLinksRemoved: s.field("brokenLinksRemoved", S.int),
    orphanedScenes: s.field("orphanedScenes", S.array(S.string)),
    unusedFiles: s.field("unusedFiles", S.array(S.string)),
    warnings: s.field("warnings", S.array(S.string)),
    errors: s.field("errors", S.array(S.string)),
  }
})

// Return a tuple (sessionId, projectData)
let importResponse = S.object(s => {
  (
    s.field("sessionId", S.string),
    s.field("projectData", S.unknown->(Obj.magic: S.t<unknown> => S.t<JSON.t>)),
  )
})

let geocodeResponse = S.object(s => {
  s.field("address", S.string)
})
