/* src/systems/ExifReportGeneratorLogicTypes.res */

open ReBindings
open SharedTypes
open ExifReportGeneratorTypes

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
