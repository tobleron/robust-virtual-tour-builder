/* src/core/SharedTypes.res */
/* Unified Type Definitions mirroring Backend Structs */

open ReBindings

/* --- XMP / GPano Types --- */
type gPanoMetadata = {
  mutable usePanoramaViewer: bool,
  mutable projectionType: string,
  mutable poseHeadingDegrees: float,
  mutable posePitchDegrees: float,
  mutable poseRollDegrees: float,
  mutable croppedAreaImageWidthPixels: int,
  mutable croppedAreaImageHeightPixels: int,
  mutable fullPanoWidthPixels: int,
  mutable fullPanoHeightPixels: int,
  mutable croppedAreaLeftPixels: int,
  mutable croppedAreaTopPixels: int,
  mutable initialViewHeadingDegrees: int,
}

/* --- Backend Metadata Types --- */

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
