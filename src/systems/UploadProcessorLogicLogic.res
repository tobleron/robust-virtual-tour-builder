/* src/systems/UploadProcessorLogicLogic.res */

open ReBindings
open SharedTypes
open Actions

external castToJson: 'a => JSON.t = "%identity"

let notify = (msg, typeStr) => {
  let type_ = switch typeStr {
  | "error" => #Error
  | "warning" => #Warning
  | "success" => #Success
  | _ => #Info
  }
  EventBus.dispatch(ShowNotification(msg, type_))
}

let processItem = (i, item: UploadProcessorTypes.uploadItem, onStatus: string => unit) => {
  Logger.debug(
    ~module_="UploadLogic",
    ~message="FILE_START",
    ~data=Some({
      "filename": File.name(item.original),
      "index": i,
      "size": File.size(item.original),
    }),
    (),
  )

  Resizer.processAndAnalyzeImage(item.original, ~onStatus=Some(onStatus))
  ->Promise.then(processResult => {
    switch processResult {
    | Ok(res) => {
        item.preview = Some(res.preview)
        item.tiny = res.tiny
        item.metadata = Some(castToJson(res.metadata))
        item.quality = Some(castToJson(res.qualityData))

        let qObj = res.qualityData
        Logger.debug(
          ~module_="UploadLogic",
          ~message="QUALITY_ANALYSIS",
          ~data=Some({
            "filename": File.name(item.original),
            "avgLuminance": qObj.stats.avgLuminance,
            "sharpnessVariance": qObj.stats.sharpnessVariance,
            "isBlurry": qObj.isBlurry,
          }),
          (),
        )

        if qObj.isSeverelyDark || qObj.isDim {
          Logger.warn(
            ~module_="UploadLogic",
            ~message="LOW_BRIGHTNESS",
            ~data=Some({
              "filename": File.name(item.original),
              "avgLuminance": qObj.stats.avgLuminance,
            }),
            (),
          )
        }
      }
    | Error(msg) => {
        Logger.error(
          ~module_="UploadLogic",
          ~message="FILE_FAILED",
          ~data=Some({
            "filename": File.name(item.original),
            "error": msg,
          }),
          (),
        )
        item.error = Some(msg)
      }
    }
    Promise.resolve(item)
  })
  ->Promise.catch(err => {
    let (msg, _stack) = Logger.getErrorDetails(err)
    Logger.error(
      ~module_="UploadLogic",
      ~message="FILE_FAILED_EXCEPTION",
      ~data=Some({
        "filename": File.name(item.original),
        "error": msg,
      }),
      (),
    )
    item.error = Some("Processing failed: " ++ msg)
    Promise.resolve(item)
  })
}

let processWithQueue = (
  items: array<UploadProcessorTypes.uploadItem>,
  maxConcurrency: int,
  updateProgress: (float, string, bool, string) => unit,
) => {
  let results = []
  let total = Array.length(items)
  let currentIndex = ref(0)
  let completedCount = ref(0)

  // Status Tracking
  let activeStatuses = Dict.make() // Map<int, string>

  let updateStatusMessage = () => {
    let counts = Dict.make()
    Dict.toArray(activeStatuses)->Belt.Array.forEach(((_k, status)) => {
      let current = Dict.get(counts, status)->Option.getOr(0)
      Dict.set(counts, status, current + 1)
    })

    let parts = []
    let optimizing = Dict.get(counts, "Optimizing")->Option.getOr(0)
    let uploading = Dict.get(counts, "Uploading")->Option.getOr(0)
    let extracting = Dict.get(counts, "Extracting")->Option.getOr(0)

    if optimizing > 0 {
      let _ = Array.push(parts, "Optimizing: " ++ Belt.Int.toString(optimizing))
    }
    if uploading > 0 {
      let _ = Array.push(parts, "Uploading: " ++ Belt.Int.toString(uploading))
    }
    if extracting > 0 {
      let _ = Array.push(parts, "Extracting: " ++ Belt.Int.toString(extracting))
    }

    let queueStatus =
      "Processing " ++ Belt.Int.toString(completedCount.contents) ++ "/" ++ Belt.Int.toString(total)

    let activityDetails = if Array.length(parts) > 0 {
      Array.join(parts, " \u2022 ") // Bullet separator
    } else {
      ""
    }

    let statusMsg = if activityDetails != "" {
      queueStatus ++ "|" ++ activityDetails
    } else {
      queueStatus
    }

    let progress = 20.0 +. 75.0 *. (Float.fromInt(completedCount.contents) /. Float.fromInt(total))

    updateProgress(progress, statusMsg, true, "Processing")
  }

  let (resolve, _reject) = (ref(ignore), ref(ignore))
  let promise = Promise.make((res, rej) => {
    resolve := res
    _reject := rej
  })

  let rec next = () => {
    if currentIndex.contents >= total {
      if completedCount.contents == total {
        resolve.contents(results)
      }
      ()
    } else {
      let i = currentIndex.contents
      currentIndex := i + 1
      let item = items[i]->Option.getOrThrow

      // Initialize status
      Dict.set(activeStatuses, Belt.Int.toString(i), "Optimizing")
      updateStatusMessage()

      processItem(i, item, status => {
        Dict.set(activeStatuses, Belt.Int.toString(i), status)
        updateStatusMessage()
      })
      ->Promise.then(res => {
        let _ = Array.push(results, res)
        completedCount := completedCount.contents + 1

        Dict.set(activeStatuses, Belt.Int.toString(i), "__DONE__")

        updateStatusMessage()

        next()
        Promise.resolve(res)
      })
      ->ignore
    }
  }

  // Start initial workers
  let initialWorkers = Math.Int.min(maxConcurrency, total)

  if total == 0 {
    resolve.contents(results)
  } else {
    for _ in 1 to initialWorkers {
      next()
    }
  }

  promise
}

let finalizeUploads = (
  validProcessed: array<UploadProcessorTypes.uploadItem>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
) => {
  let existingScenes = GlobalStateBridge.getState().scenes

  PanoramaClusterer.clusterScenes(
    validProcessed,
    ~existingScenes,
    ~updateProgress,
  )->Promise.then(validProcessed => {
    updateProgress(98.0, "Updating Sidebar...", true, "Finalizing")

    let jsonPayload = Belt.Array.map(validProcessed, item => {
      let preview = Option.getOr(item.preview, item.original)
      let tiny = Option.getOr(item.tiny, preview)

      let obj = Dict.make()
      Dict.set(obj, "id", Nullable.toOption(item.id)->Option.getOr("")->JSON.Encode.string)
      Dict.set(obj, "originalName", File.name(item.original)->JSON.Encode.string)
      Dict.set(obj, "name", File.name(preview)->JSON.Encode.string)

      // Encode file variant as JSON (Internal only)
      let encodeFile = (f: Types.file) => {
        switch f {
        | Url(s) => JSON.Encode.string(s)
        | File(file) => castToJson(file)
        | Blob(blob) => castToJson(blob)
        }
      }

      Dict.set(obj, "original", encodeFile(Types.File(item.original)))
      Dict.set(obj, "preview", encodeFile(Types.File(preview)))
      Dict.set(obj, "tiny", encodeFile(Types.File(tiny)))
      Dict.set(obj, "quality", Option.getOr(item.quality, JSON.Encode.null))
      Dict.set(obj, "metadata", Option.getOr(item.metadata, JSON.Encode.null))
      Dict.set(obj, "colorGroup", JSON.Encode.string(Option.getOr(item.colorGroup, "0")))

      castToJson(obj)
    })

    // Auto-load first scene if this is the first batch
    let wasEmpty = GlobalStateBridge.getState().activeIndex == -1
    Logger.info(
      ~module_="UploadLogic",
      ~message="DISPATCHING_ADD_SCENES",
      ~data=Some({"count": Array.length(jsonPayload), "wasEmpty": wasEmpty}),
      (),
    )
    GlobalStateBridge.dispatch(AddScenes(jsonPayload))

    if wasEmpty {
      // Reset preloading index to ensure clean start
      GlobalStateBridge.dispatch(SetPreloadingScene(-1))
    }

    let reportData = Belt.Array.map(validProcessed, i => {
      let item: ExifReportGenerator.sceneDataItem = {
        original: i.original,
        metadataJson: i.metadata,
        qualityJson: i.quality,
      }
      item
    })

    // Report for Dialog (passed back via Promise)
    let successNames = Belt.Array.map(validProcessed, i => File.name(i.original))
    let report: Types.uploadReport = {
      success: successNames,
      skipped: [],
    }

    ExifReportGenerator.generateExifReport(reportData)
    ->Promise.then(res => {
      GlobalStateBridge.dispatch(SetExifReport(JSON.Encode.string(res.report)))

      let suggestedNameResult = res.suggestedProjectName

      Logger.info(
        ~module_="UploadLogic",
        ~message="PROJECT_NAME_GENERATED",
        ~data=Some({
          "suggestedName": suggestedNameResult->Option.getOr("None"),
          "currentName": GlobalStateBridge.getState().tourName,
        }),
        (),
      )

      // Only set project name if it's meaningful
      switch suggestedNameResult {
      | Some(name) if name != "" && !RegExp.test(/Unknown/i, name) => {
          let currentName = GlobalStateBridge.getState().tourName

          if currentName == "" || TourLogic.isUnknownName(currentName) {
            Logger.info(
              ~module_="UploadLogic",
              ~message="SETTING_PROJECT_NAME",
              ~data=Some({"name": name}),
              (),
            )
            GlobalStateBridge.dispatch(SetTourName(name))
          }
        }
      | _ => ()
      }
      Promise.resolve()
    })
    ->Promise.then(() => {
      updateProgress(100.0, "Completed", false, "Done")

      let durationStr = ((Date.now() -. startTime) /. 1000.0)->Float.toFixed(~digits=1)

      Promise.resolve(
        (
          {
            qualityResults: Belt.Array.map(
              validProcessed,
              i => {
                let qItem: UploadReport.qualityItem = {
                  quality: i.quality
                  ->Option.map(Schemas.castToQualityAnalysis)
                  ->Option.getOr({
                    score: 0.0,
                    isBlurry: false,
                    isDim: false,
                    isSeverelyDark: false,
                    stats: {
                      avgLuminance: 0,
                      sharpnessVariance: 0,
                      blackClipping: 0.0,
                      whiteClipping: 0.0,
                    },
                    analysis: Nullable.null,
                    histogram: [],
                    colorHist: {r: [], g: [], b: []},
                    isSoft: false,
                    isSeverelyBright: false,
                    hasBlackClipping: false,
                    hasWhiteClipping: false,
                    issues: 0,
                    warnings: 0,
                  }),
                  newName: File.name(i.original),
                }
                qItem
              },
            ),
            duration: durationStr,
            report,
          }: UploadProcessorTypes.processResult
        ),
      )
    })
  })
}
