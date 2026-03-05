@@warning("-45")
open ReBindings
open UploadTypes
open Actions

let shouldAutoApplySuggestedName = (~currentName: string, ~suggestedName: string): bool =>
  suggestedName != "" &&
  !RegExp.test(/Unknown/i, suggestedName) &&
  (currentName == "" || TourLogic.isUnknownName(currentName))

let awaitWithTimeout = (~promise: Promise.t<'a>, ~timeoutMs: int): Promise.t<result<'a, string>> =>
  Promise.make((resolve, _reject) => {
    let settled = ref(false)
    let timeoutId = Window.setTimeout(() => {
      if !settled.contents {
        settled := true
        resolve(Error("TitleDiscoveryTimeout"))
      }
    }, timeoutMs)

    promise
    ->Promise.then(value => {
      if !settled.contents {
        settled := true
        Window.clearTimeout(timeoutId)
        resolve(Ok(value))
      }
      Promise.resolve()
    })
    ->Promise.catch(err => {
      if !settled.contents {
        settled := true
        Window.clearTimeout(timeoutId)
        let (msg, _) = Logger.getErrorDetails(err)
        resolve(Error(msg))
      }
      Promise.resolve()
    })
    ->ignore
  })

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

let runExifDiscoveryWithTimeout = (reportData: array<FeatureLoaders.exifSceneDataItem>): Promise.t<
  result<FeatureLoaders.exifReportResult, string>,
> =>
  awaitWithTimeout(
    ~promise=FeatureLoaders.generateExifReportLazy(reportData),
    ~timeoutMs=Constants.Media.backgroundTitleDiscoveryTimeoutMs,
  )

let triggerBackgroundTitleDiscovery = (
  validProcessed: array<UploadTypes.uploadItem>,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  Logger.info(~module_="UploadReporting", ~message="START_BACKGROUND_TITLE_DISCOVERY", ())
  dispatch(IncrementDiscoveringTitle)

  // 1. Prepare data from already extracted metadata (NO file re-reading)
  let reportData = Belt.Array.map(validProcessed, i => {
    let item: FeatureLoaders.exifSceneDataItem = {
      original: i.original,
      metadataJson: i.metadata,
      qualityJson: i.quality,
    }
    item
  })

  // 2. Fire and forget the report generation with a hard timeout guard
  runExifDiscoveryWithTimeout(reportData)
  ->Promise.then(result => {
    switch result {
    | Ok(res) =>
      dispatch(SetExifReport(JsonCombinators.Json.Encode.string(res.report)))
      switch res.suggestedProjectName {
      | Some(name)
        if shouldAutoApplySuggestedName(~currentName=getState().tourName, ~suggestedName=name) =>
        Logger.info(
          ~module_="UploadReporting",
          ~message="AUTO_TITLING_PROJECT",
          ~data=Some({"name": name}),
          (),
        )
        dispatch(SetTourName(name))
      | _ => ()
      }
    | Error("TitleDiscoveryTimeout") =>
      Logger.warn(
        ~module_="UploadReporting",
        ~message="BACKGROUND_TITLE_DISCOVERY_TIMEOUT",
        ~data=Some({"timeoutMs": Constants.Media.backgroundTitleDiscoveryTimeoutMs}),
        (),
      )
    | Error(msg) =>
      Logger.warn(
        ~module_="UploadReporting",
        ~message="BACKGROUND_TITLE_DISCOVERY_FAILED",
        ~data=Some({"error": msg}),
        (),
      )
    }
    dispatch(DecrementDiscoveringTitle)
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
      | Some(name)
        if shouldAutoApplySuggestedName(~currentName=getState().tourName, ~suggestedName=name) =>
        dispatch(SetTourName(name))
      | _ => ()
      }
      Promise.resolve(report)
    })
  }
}
