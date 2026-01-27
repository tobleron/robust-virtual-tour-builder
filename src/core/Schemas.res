open RescriptSchema

let toNullable = (schema: S.t<option<'a>>): S.t<Nullable.t<'a>> => {
  schema->S.transform(_ => {
    parser: (opt: option<'a>) => opt->Nullable.fromOption,
    serializer: (nul: Nullable.t<'a>) => nul->Nullable.toOption,
  })
}

module Shared = {
  let gpsData = S.object(s => {
    open SharedTypes
    {
      lat: s.field("lat", S.float),
      lon: s.field("lon", S.float),
    }
  })

  let exifMetadata = S.object(s => {
    open SharedTypes
    {
      make: s.field("make", S.nullable(S.string)->toNullable),
      model: s.field("model", S.nullable(S.string)->toNullable),
      dateTime: s.field("dateTime", S.nullable(S.string)->toNullable),
      gps: s.field("gps", S.nullable(gpsData)->toNullable),
      width: s.field("width", S.int),
      height: s.field("height", S.int),
      focalLength: s.field("focalLength", S.nullable(S.float)->toNullable),
      aperture: s.field("aperture", S.nullable(S.float)->toNullable),
      iso: s.field("iso", S.nullable(S.int)->toNullable),
    }
  })

  let colorHist: S.t<SharedTypes.colorHist> = S.object(s => {
    ({
      r: s.field("r", S.array(S.int)),
      g: s.field("g", S.array(S.int)),
      b: s.field("b", S.array(S.int)),
    }: SharedTypes.colorHist)
  })

  let qualityStats: S.t<SharedTypes.qualityStats> = S.object(s => {
    open SharedTypes
    {
      avgLuminance: s.field("avgLuminance", S.int),
      blackClipping: s.field("blackClipping", S.float),
      whiteClipping: s.field("whiteClipping", S.float),
      sharpnessVariance: s.field("sharpnessVariance", S.int),
    }
  })

  let qualityAnalysis = S.object(s => {
    open SharedTypes
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

  let metadataResponse = S.object(s => {
    open SharedTypes
    {
      exif: s.field("exif", exifMetadata),
      quality: s.field("quality", qualityAnalysis),
      isOptimized: s.field("isOptimized", S.bool),
      checksum: s.field("checksum", S.string),
      suggestedName: s.field("suggestedName", S.nullable(S.string)->toNullable),
    }
  })

  let similarityResult = S.object(s => {
    open SharedTypes
    {
      idA: s.field("idA", S.string),
      idB: s.field("idB", S.string),
      similarity: s.field("similarity", S.float),
    }
  })

  let similarityResponse = S.object(s => {
    open SharedTypes
    {
      results: s.field("results", S.array(similarityResult)),
      durationMs: s.field("durationMs", S.float),
    }
  })

  let validationReport = S.object(s => {
    open SharedTypes
    {
      brokenLinksRemoved: s.field("brokenLinksRemoved", S.int),
      orphanedScenes: s.field("orphanedScenes", S.array(S.string)),
      unusedFiles: s.field("unusedFiles", S.array(S.string)),
      warnings: s.field("warnings", S.array(S.string)),
      errors: s.field("errors", S.array(S.string)),
    }
  })

  let importResponse = S.object(s => {
    (
      s.field("sessionId", S.string),
      s.field("projectData", S.json(~validate=false)),
    )
  })->S.setName("import response")

  let geocodeResponse = S.object(s => {
    s.field("address", S.string)
  })->S.setName("geocode response")
}
