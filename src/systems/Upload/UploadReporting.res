@@warning("-45")
open ReBindings
open UploadTypes
open Actions

let createScenePayload = (items: array<UploadTypes.uploadItem>) => {
  Belt.Array.map(items, item => {
    let preview = Option.getOr(item.preview, item.original)
    let tiny = Option.getOr(item.tiny, preview)
    let sanitizedName = File.name(preview)

    JsonEncoders.Upload.sceneItem(
      ~id=Nullable.toOption(item.id)->Option.getOr(""),
      ~originalName=File.name(item.original),
      ~name=sanitizedName,
      ~original=Types.File(item.original),
      ~preview=Types.File(preview),
      ~tiny=Types.File(tiny),
      ~quality=item.quality,
      ~metadata=item.metadata,
      ~colorGroup=Option.getOr(item.colorGroup, "0"),
    )
  })
}

let handleExifReport = (
  processedWithClusters: array<UploadTypes.uploadItem>,
  skippedCount: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let reportData = Belt.Array.map(processedWithClusters, i => {
    let item: FeatureLoaders.exifSceneDataItem = {
      original: i.original,
      metadataJson: i.metadata,
      qualityJson: i.quality,
    }
    item
  })

  let successNames = Belt.Array.map(processedWithClusters, i => {
    let preview = Option.getOr(i.preview, i.original)
    UrlUtils.stripExtension(File.name(preview))
  })
  let skippedNames = Belt.Array.makeBy(skippedCount, i => "Duplicate " ++ Belt.Int.toString(i + 1))
  let report: Types.uploadReport = {success: successNames, skipped: skippedNames}

  FeatureLoaders.generateExifReportLazy(reportData)->Promise.then(res => {
    dispatch(SetExifReport(JsonCombinators.Json.Encode.string(res.report)))
    switch res.suggestedProjectName {
    | Some(name) if name != "" && !RegExp.test(/Unknown/i, name) =>
      let currentName = getState().tourName
      if currentName == "" || TourLogic.isUnknownName(currentName) {
        dispatch(SetTourName(name))
      }
    | _ => ()
    }
    Promise.resolve(report)
  })
}
