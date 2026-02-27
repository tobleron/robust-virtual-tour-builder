@module("./FeatureLoaders.js")
external exportTourLazy: (
  array<Types.scene>,
  string,
  option<Types.file>,
  option<JSON.t>,
  BrowserBindings.AbortSignal.t,
  option<(float, float, string) => unit>,
  string,
) => Promise.t<result<unit, string>> = "exportTourLazy"

@module("./FeatureLoaders.js")
external startTeaserLazy: (
  string,
  option<string>,
  unit => Types.state,
  Actions.action => unit,
  option<BrowserBindings.AbortSignal.t>,
  option<unit => unit>,
) => Promise.t<unit> = "startTeaserLazy"

type exifReportResult = {
  report: string,
  suggestedProjectName: option<string>,
}

type exifSceneDataItem = {
  original: ReBindings.File.t,
  metadataJson: option<JSON.t>,
  qualityJson: option<JSON.t>,
}

@module("./FeatureLoaders.js")
external generateExifReportLazy: array<exifSceneDataItem> => Promise.t<exifReportResult> =
  "generateExifReportLazy"

@module("./FeatureLoaders.js")
external downloadExifReportLazy: string => Promise.t<unit> = "downloadExifReportLazy"
