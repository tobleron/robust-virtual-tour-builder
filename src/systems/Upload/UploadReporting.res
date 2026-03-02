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

let triggerBackgroundTitleDiscovery = (
  validProcessed: array<UploadTypes.uploadItem>,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  Logger.info(~module_="UploadReporting", ~message="START_BACKGROUND_TITLE_DISCOVERY", ())
  dispatch(SetIsDiscoveringTitle(true))

  // 1. Prepare data from already extracted metadata (NO file re-reading)
  let reportData = Belt.Array.map(validProcessed, i => {
    let item: FeatureLoaders.exifSceneDataItem = {
      original: i.original,
      metadataJson: i.metadata,
      qualityJson: i.quality,
    }
    item
  })

  // 2. Fire and forget the report generation
  FeatureLoaders.generateExifReportLazy(reportData)
  ->Promise.then(res => {
    // 3. Store the report string for download later
    dispatch(SetExifReport(JsonCombinators.Json.Encode.string(res.report)))

    // 4. Update project title IF it's still empty/generic
    switch res.suggestedProjectName {
    | Some(name) if name != "" && !RegExp.test(/Unknown/i, name) =>
      let currentName = getState().tourName
      if currentName == "" || TourLogic.isUnknownName(currentName) {
        Logger.info(
          ~module_="UploadReporting",
          ~message="AUTO_TITLING_PROJECT",
          ~data=Some({"name": name}),
          (),
        )
        dispatch(SetTourName(name))
      }
    | _ => ()
    }
    dispatch(SetIsDiscoveringTitle(false))
    Promise.resolve()
  })
  ->Promise.catch(_ => {
    Logger.warn(~module_="UploadReporting", ~message="BACKGROUND_TITLE_DISCOVERY_FAILED", ())
    dispatch(SetIsDiscoveringTitle(false))
    Promise.resolve()
  })
  ->ignore
}

let handleExifReport = (
  processedWithClusters: array<UploadTypes.uploadItem>,
  skippedCount: int,
  ~bypassExifGeneration: bool=false,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let successNames = Belt.Array.map(processedWithClusters, i => {
    let preview = Option.getOr(i.preview, i.original)
    UrlUtils.stripExtension(File.name(preview))
  })
  let skippedNames = Belt.Array.makeBy(skippedCount, i => "Duplicate " ++ Belt.Int.toString(i + 1))
  let report: Types.uploadReport = {success: successNames, skipped: skippedNames}

  if bypassExifGeneration {
    Promise.resolve(report)
  } else {
    let reportData = Belt.Array.map(processedWithClusters, i => {
      let item: FeatureLoaders.exifSceneDataItem = {
        original: i.original,
        metadataJson: i.metadata,
        qualityJson: i.quality,
      }
      item
    })

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
}
