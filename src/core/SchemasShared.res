open RescriptSchema
open SharedTypes

// Helper to cast unknown to JSON.t
let toJson: unknown => JSON.t = Obj.magic
// Helper to cast JSON.t to unknown
let toUnknown: JSON.t => unknown = Obj.magic

let isUndefinedOrNull = (v: unknown) => {
  v === %raw("undefined") || v->toJson === JSON.Encode.null
}

let nullableString = S.custom("nullableString", s => {
  parser: unknown => {
    if isUndefinedOrNull(unknown) {
      Nullable.null
    } else {
      let json = unknown->toJson
      switch JSON.Decode.string(json) {
      | Some(str) => Nullable.make(str)
      | None => s.fail("Expected string or null")
      }
    }
  },
  serializer: n => {
    switch Nullable.toOption(n) {
    | Some(str) => JSON.Encode.string(str)->toUnknown
    | None => JSON.Encode.null->toUnknown
    }
  }
})

let nullableFloat = S.custom("nullableFloat", s => {
  parser: unknown => {
    if isUndefinedOrNull(unknown) {
      Nullable.null
    } else {
      let json = unknown->toJson
      switch JSON.Decode.float(json) {
      | Some(f) => Nullable.make(f)
      | None => s.fail("Expected float or null")
      }
    }
  },
  serializer: n => {
    switch Nullable.toOption(n) {
    | Some(f) => JSON.Encode.float(f)->toUnknown
    | None => JSON.Encode.null->toUnknown
    }
  }
})

let nullableInt = S.custom("nullableInt", s => {
  parser: unknown => {
    if isUndefinedOrNull(unknown) {
      Nullable.null
    } else {
      let json = unknown->toJson
      switch JSON.Decode.float(json) { // Decode as float then to int
      | Some(f) => Nullable.make(Belt.Float.toInt(f))
      | None => s.fail("Expected int or null")
      }
    }
  },
  serializer: n => {
    switch Nullable.toOption(n) {
    | Some(i) => JSON.Encode.int(i)->toUnknown
    | None => JSON.Encode.null->toUnknown
    }
  }
})

let gpsData: S.t<gpsData> = S.object(s => {
  {
    lat: s.field("lat", S.float),
    lon: s.field("lon", S.float),
  }
})

let nullableGpsData = S.custom("nullableGpsData", _s => {
  parser: unknown => {
    if isUndefinedOrNull(unknown) {
      Nullable.null
    } else {
      let json = unknown->toJson
      // Use the gpsData schema to parse
      let res = S.parseOrThrow(json, gpsData)
      Nullable.make(res)
    }
  },
  serializer: n => {
    switch Nullable.toOption(n) {
    | Some(v) => S.reverseConvertOrThrow(v, gpsData)
    | None => JSON.Encode.null->toUnknown
    }
  }
})

let exifMetadata: S.t<exifMetadata> = S.object(s => {
  {
    dateTime: s.field("date", nullableString),
    gps: s.field("gps", nullableGpsData),
    make: s.field("cameraModel", nullableString),
    model: s.field("lensModel", nullableString),
    width: 0,
    height: 0,
    focalLength: s.field("focalLength", nullableFloat),
    aperture: s.field("fNumber", nullableFloat),
    iso: s.field("iso", nullableInt),
  }
})

let metadataResponse: S.t<metadataResponse> = S.object(s => {
  {
    exif: s.field("exif", exifMetadata),
    quality: s.field("quality", S.unknown->(Obj.magic: S.t<unknown> => S.t<qualityAnalysis>)),
    isOptimized: s.field("isOptimized", S.bool),
    checksum: s.field("checksum", S.string),
    suggestedName: s.field("suggestedName", nullableString),
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
