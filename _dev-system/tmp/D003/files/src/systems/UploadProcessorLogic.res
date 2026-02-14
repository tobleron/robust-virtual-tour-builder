/* src/systems/UploadProcessorLogic.res */
// @efficiency-role: domain-logic
@@warning("-45")

open ReBindings
open SharedTypes
open UploadTypes
open Actions

type filenameItem = {item: uploadItem, name: string, index: int}

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
    let importance = switch typeStr {
    | "error" => NotificationTypes.Error
    | "warning" => NotificationTypes.Warning
    | "success" => NotificationTypes.Success
    | _ => NotificationTypes.Info
    }
    NotificationManager.dispatch({
      id: "",
      importance,
      context: Operation("upload_processor"),
      message: msg,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(importance),
      dismissible: true,
      createdAt: Date.now(),
    })
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
  Logger.info(
    ~module_="UploadLogic",
    ~message="PROCESS_ITEM_INVOKED",
    ~data=Some({"filename": File.name(item.original)}),
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
    // Use full name (with extension) for consistency with computeSceneFilename
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
    let item: ExifReportGenerator.sceneDataItem = {
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

  ExifReportGenerator.generateExifReport(reportData)->Promise.then(res => {
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

// From UploadProcessorFinalizer
let finalizeUploads = (
  validProcessed: array<uploadItem>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  skippedCount: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  // NOTE: Scenes are now added incrementally during processing.
  // We just need to cluster (maybe re-cluster?) and generate report.
  // For now, we assume incremental clustering was sufficient for persistence.

  let existingScenes = getState().scenes

  // We perform a final cluster pass just to be safe for the report data structure,
  // but we do NOT dispatch AddScenes again.
  PanoramaClusterer.clusterScenes(
    validProcessed,
    ~existingScenes,
    ~updateProgress,
  )->Promise.then(processedWithClusters => {
    updateProgress(98.0, "Updating Sidebar...", true, "Finalizing")

    // Check if we need to set preloading scene (first run)
    let wasEmpty = getState().activeIndex == -1
    if wasEmpty {
      let currentScenes = getState().scenes
      if Belt.Array.length(currentScenes) > 0 {
        dispatch(SetPreloadingScene(0))
      }
    }

    handleExifReport(
      processedWithClusters,
      skippedCount,
      ~getState,
      ~dispatch,
    )->Promise.then(report => {
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
                | Error(msg) => {
                    Logger.debug(
                      ~module_="UploadLogic",
                      ~message="DECODE_FALLBACK_TRIGGERED",
                      ~data=Some({"error": msg}),
                      (),
                    )
                    // Fallback: If decode fails but it looks like a record, try to recover
                    let score = %raw("(q => q && typeof q.score === 'number' ? q.score : -1)")(q)
                    if score >= 0.0 {
                      Some(Obj.magic(q))
                    } else {
                      None
                    }
                  }
                },
            )
            ->Option.getOr(SharedTypes.defaultQuality("No quality data"))
          let preview = Option.getOr(i.preview, i.original)
          let sanitizedName = UrlUtils.stripExtension(File.name(preview))
          ({quality: q, newName: sanitizedName}: Types.qualityItem)
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
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  Logger.info(~module_="UploadLogic", ~message="EXECUTE_PROCESSING_CHAIN_START", ())
  updateProgress(20.0, "Processing images...", true, "Processing")

  let processedCount = ref(0)
  // Accumulate ALL items to sort them later
  let allProcessedItems = ref([])
  let lastJournalUpdate = ref(Date.now())

  AsyncQueue.execute(
    uniqueItems,
    maxConcurrency,
    (i, item, updateStatus) => {
      updateStatus("Optimizing")
      processItem(i, item, updateStatus)->Promise.then(processedItem => {
        if processedItem.error == None {
          allProcessedItems := Belt.Array.concat(allProcessedItems.contents, [processedItem])
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
          journalPromise->Promise.then(() => Promise.resolve(processedItem))
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
  )->Promise.then(_ => {
    // All items processed. Now SORT and DISPATCH.
    let validProcessed = Belt.Array.keep(allProcessedItems.contents, i => i.error == None)

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
      let scored: array<filenameItem> = Belt.Array.mapWithIndex(validProcessed, (idx, item) => {
        {item, name: File.name(item.original), index: idx}
      })

      Belt.SortArray.stableSortInPlaceBy(scored, (a, b) => {
        let nameCmp = Float.toInt(String.localeCompare(a.name, b.name))
        if nameCmp == 0 {
          if a.index < b.index {
            -1
          } else if a.index > b.index {
            1
          } else {
            0
          }
        } else {
          nameCmp
        }
      })

      let sortedItems = Belt.Array.map(scored, scored => scored.item)

      // Assign Names 001, 002...
      let existingScenesCount = Belt.Array.length(getState().scenes)

      let finalItems = Belt.Array.mapWithIndex(sortedItems, (i, item) => {
        let newIndex = existingScenesCount + i
        // computeSceneFilename returns name with .webp extension e.g. "001.webp"
        let newName = TourLogic.computeSceneFilename(newIndex, "", "")

        {
          ...item,
          preview: item.preview->Option.map(
            f => {
              File.newFile([f], newName, {"type": File.type_(f)})
            },
          ),
        }
      })

      // Re-cluster and Dispatch
      let existingScenes = getState().scenes
      PanoramaClusterer.clusterScenes(finalItems, ~existingScenes, ~updateProgress=(_, _, _, _) =>
        ()
      )->Promise.then(clustered => {
        let jsonPayload = createScenePayload(clustered)
        dispatch(AddScenes(jsonPayload))
        PersistenceLayer.performSave(getState())

        finalizeUploads(clustered, startTime, updateProgress, skippedCount, ~getState, ~dispatch) // Use the re-named clustered items
      })
    }
  })
}

let handleFingerprinting = (
  validFiles: array<UploadTypes.file>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  journalId: string,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  Logger.info(~module_="UploadLogic", ~message="START_FINGERPRINTING", ())
  updateProgress(0.0, "Scanning files...", true, "Fingerprinting")
  FingerprintService.fingerprintFiles(validFiles)->Promise.then(results => {
    updateProgress(18.0, "Cleaning up scanning...", true, "Fingerprinting")
    let currentState = getState()
    let uniqueItems = FingerprintService.filterDuplicates(
      results,
      ~inventory=currentState.inventory,
      ~onDuplicate=c => Utils.notify("Skipped " ++ Belt.Int.toString(c) ++ " duplicates.", "info"),
      ~onRestore=id => dispatch(RemoveDeletedSceneId(id)),
    )
    let skippedFromFingerprint = Belt.Array.length(results) - Belt.Array.length(uniqueItems)
    executeProcessingChain(
      uniqueItems,
      6,
      startTime,
      updateProgress,
      skippedFromFingerprint,
      journalId,
      ~getState,
      ~dispatch,
    )
  })
}
