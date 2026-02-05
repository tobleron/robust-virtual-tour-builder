/* src/systems/UploadProcessorLogic.res */
// @efficiency-role: domain-logic
@@warning("-45")

open ReBindings
open SharedTypes
open UploadTypes
open Actions

external castToJson: 'a => JSON.t = "%identity"

module Utils = {
  // We can duplicate or move Utils here, or pass callbacks.
  // Ideally pure logic shouldn't depend on UI utils too much, but for notification dispatch it's needed.
  // Let's rely on EventBus directly or keep Utils shared.
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

  let notify = (msg, typeStr) => {
    EventBus.dispatch(ShowNotification(msg, NotificationHelpers.getNotificationType(typeStr), None))
  }
}

// From UploadProcessorQueue
let handleProcessSuccess = (res: Resizer.processResult, item: uploadItem) => {
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
}

let handleProcessError = (msg, item: uploadItem) => {
  Logger.error(
    ~module_="UploadLogic",
    ~message="FILE_FAILED",
    ~data=Some({"filename": File.name(item.original), "error": msg}),
    (),
  )
  {...item, error: Some(msg)}
}

let processItem = (i, item: uploadItem, onStatus: string => unit) => {
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
    | Ok(res) => handleProcessSuccess(res, item)
    | Error(msg) => handleProcessError(msg, item)
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

// Helper for payload creation
let createScenePayload = (items: array<UploadTypes.uploadItem>) => {
  Belt.Array.map(items, item => {
    let preview = Option.getOr(item.preview, item.original)
    let tiny = Option.getOr(item.tiny, preview)

    JsonEncoders.Upload.sceneItem(
      ~id=Nullable.toOption(item.id)->Option.getOr(""),
      ~originalName=File.name(item.original),
      ~name=File.name(preview),
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
) => {
  let reportData = Belt.Array.map(processedWithClusters, i => {
    let item: ExifReportGenerator.sceneDataItem = {
      original: i.original,
      metadataJson: i.metadata,
      qualityJson: i.quality,
    }
    item
  })

  let successNames = Belt.Array.map(processedWithClusters, i => File.name(i.original))
  let skippedNames = Belt.Array.makeBy(skippedCount, i => "Duplicate " ++ Belt.Int.toString(i + 1))
  let report: Types.uploadReport = {success: successNames, skipped: skippedNames}

  ExifReportGenerator.generateExifReport(reportData)->Promise.then(res => {
    GlobalStateBridge.dispatch(SetExifReport(JsonCombinators.Json.Encode.string(res.report)))
    switch res.suggestedProjectName {
    | Some(name) if name != "" && !RegExp.test(/Unknown/i, name) =>
      let currentName = GlobalStateBridge.getState().tourName
      if currentName == "" || TourLogic.isUnknownName(currentName) {
        GlobalStateBridge.dispatch(SetTourName(name))
      }
    | _ => ()
    }
    Promise.resolve(report)
  })
}

// From UploadProcessorFinalizer
let finalizeUploads = (
  validProcessed: array<uploadItem>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  skippedCount: int,
) => {
  // NOTE: Scenes are now added incrementally during processing.
  // We just need to cluster (maybe re-cluster?) and generate report.
  // For now, we assume incremental clustering was sufficient for persistence.

  let existingScenes = GlobalStateBridge.getState().scenes

  // We perform a final cluster pass just to be safe for the report data structure,
  // but we do NOT dispatch AddScenes again.
  PanoramaClusterer.clusterScenes(
    validProcessed,
    ~existingScenes,
    ~updateProgress,
  )->Promise.then(processedWithClusters => {
    updateProgress(98.0, "Updating Sidebar...", true, "Finalizing")

    // Check if we need to set preloading scene (first run)
    let wasEmpty = GlobalStateBridge.getState().activeIndex == -1
    if wasEmpty {
      GlobalStateBridge.dispatch(SetPreloadingScene(-1))
    }

    handleExifReport(processedWithClusters, skippedCount)->Promise.then(report => {
      updateProgress(100.0, "Completed", false, "Done")
      let durationStr = ((Date.now() -. startTime) /. 1000.0)->Float.toFixed(~digits=1)

      let qualityResults = Belt.Array.map(
        processedWithClusters,
        i => {
          let q =
            i.quality
            ->Option.flatMap(
              q =>
                switch JsonCombinators.Json.decode(q, JsonParsers.Shared.qualityAnalysis) {
                | Ok(qa) => Some(qa)
                | Error(_) => None
                },
            )
            ->Option.getOr(SharedTypes.defaultQuality("No quality data"))
          ({quality: q, newName: File.name(i.original)}: UploadReport.qualityItem)
        },
      )

      Promise.resolve(
        (
          {
            qualityResults,
            duration: durationStr,
            report,
          }: UploadTypes.processResult
        ),
      )
    })
  })
}

let recoverUpload = (entry: OperationJournal.journalEntry) => {
  let count = switch JsonCombinators.Json.decode(
    entry.context,
    JsonCombinators.Json.Decode.object(field =>
      field.optional("processedCount", JsonCombinators.Json.Decode.int)
    ),
  ) {
  | Ok(Some(c)) => c
  | _ => 0
  }

  EventBus.dispatch(
    ShowModal({
      title: "Partial Upload Detected",
      description: Some(
        "Upload was interrupted. " ++
        Belt.Int.toString(
          count,
        ) ++ " files were processed. Please select the files again to continue.",
      ),
      content: None,
      buttons: [
        {
          label: "Finish Upload",
          class_: "btn-primary",
          onClick: () => EventBus.dispatch(TriggerUpload),
          autoClose: Some(true),
        },
      ],
      icon: Some("alert-circle"),
      allowClose: Some(true),
      onClose: None,
      className: None,
    }),
  )
  Promise.resolve(true)
}

// Refactored Helper for Finalization
let executeProcessingChain = (
  uniqueItems: array<uploadItem>,
  maxConcurrency: int,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  skippedCount: int,
  journalId: string,
) => {
  updateProgress(20.0, "Processing images...", true, "Processing")

  let processedCount = ref(0)
  let buffer = ref([])
  let lastJournalUpdate = ref(Date.now())

  let flushBuffer = () => {
    let itemsToFlush = buffer.contents
    if Belt.Array.length(itemsToFlush) > 0 {
      buffer := []
      let existingScenes = GlobalStateBridge.getState().scenes
      PanoramaClusterer.clusterScenes(itemsToFlush, ~existingScenes, ~updateProgress=(_, _, _, _) =>
        ()
      )->Promise.then(clustered => {
        let jsonPayload = createScenePayload(clustered)
        GlobalStateBridge.dispatch(AddScenes(jsonPayload))
        PersistenceLayer.performSave(GlobalStateBridge.getState())
        Promise.resolve()
      })
    } else {
      Promise.resolve()
    }
  }

  AsyncQueue.execute(
    uniqueItems,
    maxConcurrency,
    (i, item, updateStatus) => {
      updateStatus("Optimizing")
      processItem(i, item, updateStatus)->Promise.then(processedItem => {
        if processedItem.error == None {
          buffer := Belt.Array.concat(buffer.contents, [processedItem])
          processedCount := processedCount.contents + 1

          let now = Date.now()
          let shouldUpdateJournal = now -. lastJournalUpdate.contents > 1000.0

          let journalPromise = if shouldUpdateJournal {
            lastJournalUpdate := now
            OperationJournal.updateContext(
              journalId,
              JsonCombinators.Json.Encode.object([
                ("processedCount", JsonCombinators.Json.Encode.int(processedCount.contents)),
              ]),
            )
          } else {
            Promise.resolve()
          }

          if Belt.Array.length(buffer.contents) >= 5 {
            flushBuffer()
            ->Promise.then(() => journalPromise)
            ->Promise.then(() => Promise.resolve(processedItem))
          } else {
            journalPromise->Promise.then(() => Promise.resolve(processedItem))
          }
        } else {
          Promise.resolve(processedItem)
        }
      })
    },
    (pct, msg) => {
      // Map 0.0-1.0 to 20.0-95.0 range
      let scaledPct = 20.0 +. 75.0 *. pct
      updateProgress(scaledPct, msg, true, "Processing")
    },
  )->Promise.then(processedItems => {
    flushBuffer()->Promise.then(() => {
      let validProcessed = Belt.Array.keep(processedItems, i => i.error == None)
      if Belt.Array.length(validProcessed) == 0 && Belt.Array.length(uniqueItems) > 0 {
        Utils.notify("All uploads failed.", "error")
        Promise.resolve(
          (
            {
              qualityResults: [],
              duration: "0.0",
              report: {success: [], skipped: []},
            }: UploadTypes.processResult
          ),
        )
      } else {
        finalizeUploads(validProcessed, startTime, updateProgress, skippedCount)
      }
    })
  })
}

let handleFingerprinting = (
  validFiles: array<UploadTypes.file>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  journalId: string,
) => {
  updateProgress(0.0, "Scanning files...", true, "Fingerprinting")
  FingerprintService.fingerprintFiles(validFiles)->Promise.then(results => {
    updateProgress(18.0, "Cleaning up scanning...", true, "Fingerprinting")
    let currentState = GlobalStateBridge.getState()
    let uniqueItems = FingerprintService.filterDuplicates(
      results,
      ~existingScenes=currentState.scenes,
      ~deletedIds=currentState.deletedSceneIds,
      ~onDuplicate=c => Utils.notify("Skipped " ++ Belt.Int.toString(c) ++ " duplicates.", "info"),
      ~onRestore=id => GlobalStateBridge.dispatch(RemoveDeletedSceneId(id)),
    )
    let skippedFromFingerprint = Belt.Array.length(results) - Belt.Array.length(uniqueItems)
    executeProcessingChain(
      uniqueItems,
      6,
      startTime,
      updateProgress,
      skippedFromFingerprint,
      journalId,
    )
  })
}
