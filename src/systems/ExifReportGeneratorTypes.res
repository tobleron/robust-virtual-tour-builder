/* src/systems/ExifReportGeneratorTypes.res */

open ReBindings

type sceneDataItem = {
  original: File.t,
  metadataJson: option<JSON.t>,
  qualityJson: option<JSON.t>,
}

type exifResult = {
  filename: string,
  exifData: SharedTypes.exifMetadata,
  qualityData: SharedTypes.qualityAnalysis,
}

type reportResult = {
  report: string,
  suggestedProjectName: option<string>,
}
