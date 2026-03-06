/* src/core/SharedTypes.res */
/* Unified Type Definitions mirroring Backend Structs */

/* --- XMP / GPano Types --- */
type gPanoMetadata = {
  usePanoramaViewer: bool,
  projectionType: string,
  poseHeadingDegrees: float,
  posePitchDegrees: float,
  poseRollDegrees: float,
  croppedAreaImageWidthPixels: int,
  croppedAreaImageHeightPixels: int,
  fullPanoWidthPixels: int,
  fullPanoHeightPixels: int,
  croppedAreaLeftPixels: int,
  croppedAreaTopPixels: int,
  initialViewHeadingDegrees: int,
}

/* --- Backend Metadata Types --- */

type geocodeRequest = {
  lat: float,
  lon: float,
}

type gpsData = {
  lat: float,
  lon: float,
}

type exifMetadata = {
  make: Nullable.t<string>,
  model: Nullable.t<string>,
  @as("dateTime") dateTime: Nullable.t<string>,
  gps: Nullable.t<gpsData>,
  width: int,
  height: int,
  @as("focalLength") focalLength: Nullable.t<float>,
  aperture: Nullable.t<float>,
  iso: Nullable.t<int>,
}

type qualityStats = {
  @as("avgLuminance") avgLuminance: int,
  @as("blackClipping") blackClipping: float,
  @as("whiteClipping") whiteClipping: float,
  @as("sharpnessVariance") sharpnessVariance: int,
}

type colorHist = {
  r: array<int>,
  g: array<int>,
  b: array<int>,
}

type qualityAnalysis = {
  score: float,
  histogram: array<int>,
  @as("colorHist") colorHist: colorHist,
  stats: qualityStats,
  @as("isBlurry") isBlurry: bool,
  @as("isSoft") isSoft: bool,
  @as("isSeverelyDark") isSeverelyDark: bool,
  @as("isSeverelyBright") isSeverelyBright: bool,
  @as("isDim") isDim: bool,
  @as("hasBlackClipping") hasBlackClipping: bool,
  @as("hasWhiteClipping") hasWhiteClipping: bool,
  issues: int,
  warnings: int,
  analysis: Nullable.t<string>,
}

type metadataResponse = {
  exif: exifMetadata,
  quality: qualityAnalysis,
  @as("isOptimized") isOptimized: bool,
  checksum: string,
  @as("suggestedName") suggestedName: Nullable.t<string>,
}

/* --- Similarity Types --- */

type colorHistogram = {
  r: array<float>,
  g: array<float>,
  b: array<float>,
}

type histogramData = {
  histogram: option<array<float>>,
  @as("colorHist") colorHist: option<colorHistogram>,
}

type similarityPair = {
  @as("idA") idA: string,
  @as("idB") idB: string,
  @as("histogramA") histogramA: JSON.t, // Keeping JSON.t to avoid complex mapping of HistogramData for now if not strictly needed, or map it.
  @as("histogramB") histogramB: JSON.t, // Actually, let's map it properly if possible, but UploadProcessor constructs it from JSON.
}

type similarityResult = {
  @as("idA") idA: string,
  @as("idB") idB: string,
  similarity: float,
}

type similarityResponse = {
  results: array<similarityResult>,
  @as("durationMs") durationMs: float,
}

/* --- Validation Types --- */

type validationReport = {
  @as("brokenLinksRemoved") brokenLinksRemoved: int,
  @as("orphanedScenes") orphanedScenes: array<string>,
  @as("unusedFiles") unusedFiles: array<string>,
  warnings: array<string>,
  errors: array<string>,
}

type geocodeResponse = {address: string}

type importResponse = {
  sessionId: string,
  projectData: JSON.t,
}

/* --- Structured Application Errors --- */

type appError =
  | NetworkError({message: string, code: option<string>})
  | ValidationError({message: string, field: option<string>})
  | TimeoutError({message: string, operation: option<string>})
  | PermissionError({message: string, code: option<string>})
  | InternalError({message: string, code: option<string>, retryable: bool})

type appResult<'a> = result<'a, appError>

let appErrorType = (err: appError): string =>
  switch err {
  | NetworkError(_) => "network"
  | ValidationError(_) => "validation"
  | TimeoutError(_) => "timeout"
  | PermissionError(_) => "permission"
  | InternalError(_) => "internal"
  }

let appErrorMessage = (err: appError): string =>
  switch err {
  | NetworkError({message})
  | ValidationError({message})
  | TimeoutError({message})
  | PermissionError({message})
  | InternalError({message}) => message
  }

let appErrorRetryable = (err: appError): bool =>
  switch err {
  | NetworkError(_) | TimeoutError(_) => true
  | ValidationError(_) | PermissionError(_) => false
  | InternalError({retryable}) => retryable
  }

let appErrorCode = (err: appError): option<string> =>
  switch err {
  | NetworkError({code}) => code
  | PermissionError({code}) => code
  | InternalError({code}) => code
  | ValidationError(_) | TimeoutError(_) => None
  }

let appErrorToTelemetryJson = (err: appError, ~operationContext: option<string>=?): JSON.t => {
  let encodeOptString = (value: option<string>): JSON.t =>
    switch value {
    | Some(v) => JsonCombinators.Json.Encode.string(v)
    | None => JsonCombinators.Json.Encode.null
    }

  let detailsField = switch err {
  | ValidationError({field}) => ("field", encodeOptString(field))
  | TimeoutError({operation}) => ("operation", encodeOptString(operation))
  | _ => ("detail", JsonCombinators.Json.Encode.null)
  }

  JsonCombinators.Json.Encode.object([
    ("error_type", JsonCombinators.Json.Encode.string(appErrorType(err))),
    ("message", JsonCombinators.Json.Encode.string(appErrorMessage(err))),
    ("retryable", JsonCombinators.Json.Encode.bool(appErrorRetryable(err))),
    ("code", encodeOptString(appErrorCode(err))),
    ("operation_context", encodeOptString(operationContext)),
    detailsField,
  ])
}

let appErrorFromHttpStatus = (
  ~status: int,
  ~message: string,
  ~operationContext: option<string>=?,
): appError =>
  switch status {
  | 400 => ValidationError({message, field: operationContext})
  | 401 | 403 => PermissionError({message, code: Some(Belt.Int.toString(status))})
  | 408 | 504 => TimeoutError({message, operation: operationContext})
  | 429 => NetworkError({message, code: Some("RATE_LIMITED")})
  | _ if status >= 500 =>
    InternalError({message, code: Some(Belt.Int.toString(status)), retryable: true})
  | _ => InternalError({message, code: Some(Belt.Int.toString(status)), retryable: false})
  }

let appErrorFromMessage = (~message: string, ~operationContext: option<string>=?): appError => {
  let lower = message->String.toLowerCase
  if String.includes(lower, "timeout") {
    TimeoutError({message, operation: operationContext})
  } else if String.includes(lower, "network") || String.includes(lower, "offline") {
    NetworkError({message, code: None})
  } else if String.includes(lower, "unauthorized") || String.includes(lower, "forbidden") {
    PermissionError({message, code: None})
  } else if String.includes(lower, "invalid") || String.includes(lower, "decode") {
    ValidationError({message, field: operationContext})
  } else {
    InternalError({message, code: None, retryable: false})
  }
}

let defaultQuality = (msg: string): qualityAnalysis => {
  score: 0.0,
  histogram: [],
  colorHist: {r: [], g: [], b: []},
  stats: {
    avgLuminance: 0,
    blackClipping: 0.0,
    whiteClipping: 0.0,
    sharpnessVariance: 0,
  },
  isBlurry: false,
  isSoft: false,
  isSeverelyDark: false,
  isSeverelyBright: false,
  isDim: false,
  hasBlackClipping: false,
  hasWhiteClipping: false,
  issues: 0,
  warnings: 0,
  analysis: Nullable.make(msg),
}

let defaultExif: exifMetadata = {
  make: Nullable.null,
  model: Nullable.null,
  dateTime: Nullable.null,
  gps: Nullable.null,
  width: 0,
  height: 0,
  focalLength: Nullable.null,
  aperture: Nullable.null,
  iso: Nullable.null,
}
