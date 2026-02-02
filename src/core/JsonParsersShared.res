/* src/core/JsonParsersShared.res */

open JsonCombinators.Json

// Utility aliases
let object = Decode.object
let field = Decode.field
let array = Decode.array
let int = Decode.int
let float = Decode.float
let string = Decode.string
let bool = Decode.bool
let option = Decode.option
let map = Decode.map
let id = Decode.id

// Custom helper to reduce boilerplate in optional fields
let opt = (field: Decode.fieldDecoders, key, decoder, default) => {
  field.optional(key, option(decoder))->Option.flatMap(x => x)->Option.getOr(default)
}

// Custom nullable decoder: maps option(decoder) to Nullable.t
let toNullable = decoder => {
  map(option(decoder), Nullable.fromOption)
}

let nullableOpt = (field: Decode.fieldDecoders, key, decoder) => {
  field.optional(key, option(decoder))->Option.flatMap(x => x)->Nullable.fromOption
}

let gpsData = object(field => {
  {
    SharedTypes.lat: field->opt("lat", float, 0.0),
    lon: field->opt("lon", float, 0.0),
  }
})

let exifMetadata = object(field => {
  {
    SharedTypes.dateTime: field->nullableOpt("dateTime", string),
    gps: field->nullableOpt("gps", gpsData),
    make: field->nullableOpt("make", string),
    model: field->nullableOpt("model", string),
    width: field->opt("width", int, 0),
    height: field->opt("height", int, 0),
    focalLength: field->nullableOpt("focalLength", float),
    aperture: field->nullableOpt("aperture", float),
    iso: field->nullableOpt("iso", int),
  }
})

let colorHist = object(field => {
  let res: SharedTypes.colorHist = {
    r: field->opt("r", array(int), []),
    g: field->opt("g", array(int), []),
    b: field->opt("b", array(int), []),
  }
  res
})

let qualityStats = object(field => {
  {
    SharedTypes.avgLuminance: field->opt("avgLuminance", int, 0),
    blackClipping: field->opt("blackClipping", float, 0.0),
    whiteClipping: field->opt("whiteClipping", float, 0.0),
    sharpnessVariance: field->opt("sharpnessVariance", int, 0),
  }
})

let qualityAnalysis = object(field => {
  {
    SharedTypes.score: field->opt("score", float, 0.0),
    histogram: field->opt("histogram", array(int), []),
    colorHist: field->opt("colorHist", colorHist, {r: [], g: [], b: []}),
    stats: field->opt(
      "stats",
      qualityStats,
      {
        avgLuminance: 0,
        blackClipping: 0.0,
        whiteClipping: 0.0,
        sharpnessVariance: 0,
      },
    ),
    isBlurry: field->opt("isBlurry", bool, false),
    isSoft: field->opt("isSoft", bool, false),
    isSeverelyDark: field->opt("isSeverelyDark", bool, false),
    isSeverelyBright: field->opt("isSeverelyBright", bool, false),
    isDim: field->opt("isDim", bool, false),
    hasBlackClipping: field->opt("hasBlackClipping", bool, false),
    hasWhiteClipping: field->opt("hasWhiteClipping", bool, false),
    issues: field->opt("issues", int, 0),
    warnings: field->opt("warnings", int, 0),
    analysis: field->nullableOpt("analysis", string),
  }
})

let metadataResponse = object(field => {
  {
    SharedTypes.exif: field.required("exif", exifMetadata),
    quality: field.required("quality", qualityAnalysis),
    isOptimized: field.optional("isOptimized", bool)->Option.getOr(false),
    checksum: field.optional("checksum", string)->Option.getOr(""),
    suggestedName: field->nullableOpt("suggestedName", string),
  }
})

let similarityResult = object(field => {
  {
    SharedTypes.idA: field.required("idA", string),
    idB: field.required("idB", string),
    similarity: field.required("similarity", float),
  }
})

let similarityResponse = object(field => {
  {
    SharedTypes.results: field.required("results", array(similarityResult)),
    durationMs: field.required("durationMs", float),
  }
})

let validationReport = object(field => {
  {
    SharedTypes.brokenLinksRemoved: field.required("brokenLinksRemoved", int),
    orphanedScenes: field.required("orphanedScenes", array(string)),
    unusedFiles: field.required("unusedFiles", array(string)),
    warnings: field.required("warnings", array(string)),
    errors: field.required("errors", array(string)),
  }
})

let geocodeResponse = object(field => {
  {
    SharedTypes.address: field.required("address", string),
  }
})

let importResponse = object(field => {
  {
    SharedTypes.sessionId: field.required("sessionId", string),
    projectData: field.required("projectData", id),
  }
})
