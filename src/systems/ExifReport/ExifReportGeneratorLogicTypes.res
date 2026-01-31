/* src/systems/ExifReport/ExifReportGeneratorLogicTypes.res */

open ReBindings
open SharedTypes

type sceneDataItem = {
  original: File.t,
  metadataJson: option<JSON.t>,
  qualityJson: option<JSON.t>,
}

type exifResult = {
  filename: string,
  exifData: exifMetadata,
  qualityData: qualityAnalysis,
}

type reportResult = {
  report: string,
  suggestedProjectName: option<string>,
}

type localExifResult = {
  exif: exifMetadata,
  quality: qualityAnalysis,
  isOptimized: bool,
  checksum: string,
  suggestedName: Nullable.t<string>,
}

type locationAnalysis = {
  centroid: GeoUtils.point,
  outliers: array<GeoUtils.outlier>,
}
