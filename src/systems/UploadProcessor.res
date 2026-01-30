/* src/systems/UploadProcessor.res - Consolidated Upload Processor System */

open ReBindings
open SharedTypes
open Actions

// --- UTILS ---

module NotificationHelpers = {
  let getNotificationType = (typeStr: string) => {
    switch typeStr {
    | "error" => #Error
    | "warning" => #Warning
    | "success" => #Success
    | _ => #Info
    }
  }
}

module Utils = {
  let notify = (msg, typeStr) => {
    EventBus.dispatch(ShowNotification(msg, NotificationHelpers.getNotificationType(typeStr)))
  }
}

// --- LOGIC ---

module Logic = {
  external castToJson: 'a => JSON.t = "%identity"

  let processItem = (i, item: UploadTypes.uploadItem, onStatus: string => unit) => {
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
      let newItem = switch processResult {
      | Ok(res) =>
        Logger.debug(
          ~module_="UploadLogic",
          ~message="QUALITY_ANALYSIS",
          ~data=Some({
            "filename": File.name(item.original),
            "avgLuminance": res.qualityData.stats.avgLuminance,
            "isBlurry": res.qualityData.isBlurry,
          }),
          (),
        )
        {
          ...item,
          preview: Some(res.preview),
          tiny: res.tiny,
          metadata: Some(castToJson(res.metadata)),
          quality: Some(castToJson(res.qualityData)),
        }
      | Error(msg) =>
        Logger.error(
          ~module_="UploadLogic",
          ~message="FILE_FAILED",
          ~data=Some({"filename": File.name(item.original), "error": msg}),
          (),
        )
        {...item, error: Some(msg)}
      }
      Promise.resolve(newItem)
    })
    ->Promise.catch(err => {
      let (msg, _) = Logger.getErrorDetails(err)
      Logger.error(
        ~module_="UploadLogic",
        ~message="FILE_FAILED_EXCEPTION",
        ~data=Some({"filename": File.name(item.original), "error": msg}),
        (),
      )
      Promise.resolve({...item, error: Some("Processing failed: " ++ msg)})
    })
  }

  let computeStatusAndProgress = (activeStatuses, completedCount, total) => {
    let counts = Dict.make()
    Dict.toArray(activeStatuses)->Belt.Array.forEach(((_k, status)) => {
      let current = Dict.get(counts, status)->Option.getOr(0)
      Dict.set(counts, status, current + 1)
    })
    let parts = []
    let getC = s => Dict.get(counts, s)->Option.getOr(0)
    if getC("Optimizing") > 0 {
      let _ = Array.push(parts, "Optimizing: " ++ Belt.Int.toString(getC("Optimizing")))
    }
    if getC("Uploading") > 0 {
      let _ = Array.push(parts, "Uploading: " ++ Belt.Int.toString(getC("Uploading")))
    }
    if getC("Extracting") > 0 {
      let _ = Array.push(parts, "Extracting: " ++ Belt.Int.toString(getC("Extracting")))
    }
    let queueStatus =
      "Processing " ++ Belt.Int.toString(completedCount) ++ "/" ++ Belt.Int.toString(total)
    let activityDetails = if Array.length(parts) > 0 {
      Array.join(parts, " \u2022 ")
    } else {
      ""
    }
    let statusMsg = if activityDetails != "" {
      queueStatus ++ "|" ++ activityDetails
    } else {
      queueStatus
    }
    let progress = 20.0 +. 75.0 *. (Float.fromInt(completedCount) /. Float.fromInt(total))
    (progress, statusMsg)
  }

  let processWithQueue = (
    items: array<UploadTypes.uploadItem>,
    maxConcurrency: int,
    updateProgress: (float, string, bool, string) => unit,
  ) => {
    let results = []
    let total = Array.length(items)
    let currentIndex = ref(0)
    let completedCount = ref(0)
    let activeStatuses = Dict.make()

    let updateStatusMessage = () => {
      let (progress, statusMsg) = computeStatusAndProgress(
        activeStatuses,
        completedCount.contents,
        total,
      )
      updateProgress(progress, statusMsg, true, "Processing")
    }

    let (resolve, reject) = (ref(ignore), ref(ignore))
    let promise = Promise.make((res, rej) => {
      resolve := res
      reject := rej
    })

    let rec next = () => {
      if currentIndex.contents >= total {
        if completedCount.contents == total {
          resolve.contents(results)
        }
      } else {
        let i = currentIndex.contents
        currentIndex := i + 1
        let item = items[i]->Option.getOrThrow
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
    validProcessed: array<UploadTypes.uploadItem>,
    startTime: float,
    updateProgress: (float, string, bool, string) => unit,
  ) => {
    let existingScenes = GlobalStateBridge.getState().scenes
    PanoramaClusterer.clusterScenes(
      validProcessed,
      ~existingScenes,
      ~updateProgress,
    )->Promise.then(processedWithClusters => {
      updateProgress(98.0, "Updating Sidebar...", true, "Finalizing")
      let jsonPayload = Belt.Array.map(processedWithClusters, item => {
        let preview = Option.getOr(item.preview, item.original)
        let tiny = Option.getOr(item.tiny, preview)
        let obj = Dict.make()
        Dict.set(obj, "id", Nullable.toOption(item.id)->Option.getOr("")->JSON.Encode.string)
        Dict.set(obj, "originalName", File.name(item.original)->JSON.Encode.string)
        Dict.set(obj, "name", File.name(preview)->JSON.Encode.string)
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

      let wasEmpty = GlobalStateBridge.getState().activeIndex == -1
      GlobalStateBridge.dispatch(AddScenes(jsonPayload))
      if wasEmpty {
        GlobalStateBridge.dispatch(SetPreloadingScene(-1))
      }

      let reportData = Belt.Array.map(processedWithClusters, i => {
        let item: ExifReportGenerator.sceneDataItem = {
          original: i.original,
          metadataJson: i.metadata,
          qualityJson: i.quality,
        }
        item
      })

      let successNames = Belt.Array.map(processedWithClusters, i => File.name(i.original))
      let report: Types.uploadReport = {success: successNames, skipped: []}

      ExifReportGenerator.generateExifReport(reportData)
      ->Promise.then(res => {
        GlobalStateBridge.dispatch(SetExifReport(JSON.Encode.string(res.report)))
        switch res.suggestedProjectName {
        | Some(name) if name != "" && !RegExp.test(/Unknown/i, name) =>
          let currentName = GlobalStateBridge.getState().tourName
          if currentName == "" || TourLogic.isUnknownName(currentName) {
            GlobalStateBridge.dispatch(SetTourName(name))
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
                processedWithClusters,
                i => {
                  let q =
                    i.quality
                    ->Option.map(Schemas.castToQualityAnalysis)
                    ->Option.getOr(defaultQuality("No quality data"))
                  ({quality: q, newName: File.name(i.original)}: UploadReport.qualityItem)
                },
              ),
              duration: durationStr,
              report,
            }: UploadTypes.processResult
          ),
        )
      })
    })
  }
}

// --- MAIN ---

let processUploads = (
  files: array<UploadTypes.file>,
  progressCallback: option<(float, string, bool, string) => unit>,
): Promise.t<UploadTypes.processResult> => {
  let updateProgress = (pct, msg, isProc, phase) => {
    switch progressCallback {
    | Some(cb) => cb(pct, msg, isProc, phase)
    | None => ()
    }
  }
  updateProgress(0.0, "Checking backend...", true, "Health Check")

  Resizer.checkBackendHealth()->Promise.then(isUp => {
    if !isUp {
      updateProgress(100.0, "Error: Backend Offline", false, "Error")
      Utils.notify("Backend Server Not Connected! Port 8080 is not running.", "error")
      Promise.resolve(
        (
          {
            qualityResults: [],
            duration: "0.0",
            report: ({success: [], skipped: []}: Types.uploadReport),
          }: UploadTypes.processResult
        ),
      )
    } else {
      let startTime = Date.now()
      if Belt.Array.length(files) == 0 {
        Promise.resolve(
          (
            {
              qualityResults: [],
              duration: "0.0",
              report: ({success: [], skipped: []}: Types.uploadReport),
            }: UploadTypes.processResult
          ),
        )
      } else {
        let validFiles = ImageValidator.validateFiles(files, msg => Utils.notify(msg, "warning"))
        if Belt.Array.length(validFiles) == 0 {
          Utils.notify("No valid image files selected!", "error")
          Promise.resolve(
            (
              {
                qualityResults: [],
                duration: "0.0",
                report: ({success: [], skipped: []}: Types.uploadReport),
              }: UploadTypes.processResult
            ),
          )
        } else {
          updateProgress(0.0, "Scanning files...", true, "Fingerprinting")
          FingerprintService.fingerprintFiles(validFiles)->Promise.then(results => {
            updateProgress(18.0, "Cleaning up scanning...", true, "Fingerprinting")
            let currentState = GlobalStateBridge.getState()
            let uniqueItems = FingerprintService.filterDuplicates(
              results,
              ~existingScenes=currentState.scenes,
              ~deletedIds=currentState.deletedSceneIds,
              ~onDuplicate=c =>
                Utils.notify("Skipped " ++ Belt.Int.toString(c) ++ " duplicates.", "info"),
              ~onRestore=id => GlobalStateBridge.dispatch(RemoveDeletedSceneId(id)),
            )

            updateProgress(20.0, "Processing images...", true, "Processing")
            Logic.processWithQueue(uniqueItems, 6, updateProgress)->Promise.then(
              processedItems => {
                let validProcessed = Belt.Array.keep(processedItems, i => i.error == None)
                if Belt.Array.length(validProcessed) == 0 && Belt.Array.length(uniqueItems) > 0 {
                  Utils.notify("All uploads failed.", "error")
                  Promise.resolve(
                    (
                      {
                        qualityResults: [],
                        duration: "0.0",
                        report: ({success: [], skipped: []}: Types.uploadReport),
                      }: UploadTypes.processResult
                    ),
                  )
                } else {
                  Logic.finalizeUploads(validProcessed, startTime, updateProgress)
                }
              },
            )
          })
        }
      }
    }
  })
}
