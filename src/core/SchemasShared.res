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

let colorHist: S.t<SharedTypes.colorHist> = S.object((s): SharedTypes.colorHist => {
  {
    r: s.field("r", S.array(S.int)),
    g: s.field("g", S.array(S.int)),
    b: s.field("b", S.array(S.int)),
  }
})

let qualityStats: S.t<SharedTypes.qualityStats> = S.object(s => {
  {
    avgLuminance: s.field("avgLuminance", S.int),
    blackClipping: s.field("blackClipping", S.float),
    whiteClipping: s.field("whiteClipping", S.float),
    sharpnessVariance: s.field("sharpnessVariance", S.int),
  }
})

let qualityAnalysis: S.t<SharedTypes.qualityAnalysis> = S.object(s => {
  {
    score: s.field("score", S.float),
    histogram: s.field("histogram", S.array(S.int)),
    colorHist: s.field("colorHist", colorHist),
    stats: s.field("stats", qualityStats),
    isBlurry: s.field("isBlurry", S.bool),
    isSoft: s.field("isSoft", S.bool),
    isSeverelyDark: s.field("isSeverelyDark", S.bool),
    isSeverelyBright: s.field("isSeverelyBright", S.bool),
    isDim: s.field("isDim", S.bool),
    hasBlackClipping: s.field("hasBlackClipping", S.bool),
    hasWhiteClipping: s.field("hasWhiteClipping", S.bool),
    issues: s.field("issues", S.int),
    warnings: s.field("warnings", S.int),
    analysis: s.field("analysis", S.nullable(S.string)->toNullable),
  }
})

let metadataResponse: S.t<metadataResponse> = S.object(s => {
  {
    exif: s.field("exif", exifMetadata),
    quality: s.field("quality", qualityAnalysis),
    isOptimized: s.field("isOptimized", S.bool),
    checksum: s.field("checksum", S.string),
    suggestedName: s.field("suggestedName", S.nullable(S.string)->toNullable),
  }
})

let similarityResult: S.t<SharedTypes.similarityResult> = S.object(s => {
  {
    idA: s.field("sceneId", S.string),
    idB: "",
    similarity: s.field("score", S.float),
  }
})

let similarityResponse: S.t<SharedTypes.similarityResponse> = S.object(s => {
  {
    results: s.field("results", S.array(similarityResult)),
    durationMs: s.field("durationMs", S.float),
  }
})

let validationReport: S.t<SharedTypes.validationReport> = S.object(s => {
  {
    brokenLinksRemoved: s.field("brokenLinksRemoved", S.int),
    orphanedScenes: s.field("orphanedScenes", S.array(S.string)),
    unusedFiles: s.field("unusedFiles", S.array(S.string)),
    warnings: s.field("warnings", S.array(S.string)),
    errors: s.field("errors", S.array(S.string)),
  }
})

let geocodeResponse: S.t<string> = S.object(s => s.field("address", S.string))

let importResponse: S.t<(string, JSON.t)> = S.object(s => {
  (
    s.field("sessionId", S.string),
    s.field("projectData", S.unknown->(Obj.magic: S.t<unknown> => S.t<JSON.t>)),
  )
})
