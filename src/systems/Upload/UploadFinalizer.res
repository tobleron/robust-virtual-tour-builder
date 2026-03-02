@@warning("-45")
open ReBindings
open UploadTypes
open Actions

type filenameItem = {item: uploadItem, name: string, index: int}

external unsafeCastToQuality: JSON.t => SharedTypes.qualityAnalysis = "%identity"

let bytesToMb = (sizeBytes: float): float => sizeBytes /. 1024.0 /. 1024.0

let selectInFlightBudgetMb = (items: array<uploadItem>): float => {
  let totalMb =
    items
    ->Belt.Array.reduce(0.0, (acc, item) => acc +. BrowserBindings.File.size(item.original))
    ->bytesToMb
  if totalMb >= Constants.Media.uploadHeavyFolderThresholdMb {
    Constants.Media.uploadInFlightBudgetMbHeavy
  } else {
    Constants.Media.uploadInFlightBudgetMbDefault
  }
}

let finalizeUploads = (
  validProcessed: array<uploadItem>,
  startTime: float,
  updateProgress: (~eta: string=?, float, string, bool, string) => unit,
  skippedCount: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  updateProgress(98.0, "Wrapping up...", true, "Finalizing")

  let wasEmpty = getState().activeIndex == -1
  if wasEmpty {
    let currentScenes = SceneInventory.getActiveScenes(getState().inventory, getState().sceneOrder)
    if Belt.Array.length(currentScenes) > 0 {
      dispatch(SetPreloadingScene(0))
    }
  }

  UploadReporting.handleExifReport(
    validProcessed,
    skippedCount,
    ~bypassExifGeneration=true,
    ~getState,
    ~dispatch,
  )->Promise.then(report => {
    updateProgress(100.0, "Upload complete", false, "Done")
    let durationStr = ((Date.now() -. startTime) /. 1000.0)->Float.toFixed(~digits=1)

    let qualityResults = Belt.Array.map(validProcessed, i => {
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

                let score = switch JsonCombinators.Json.decode(
                  q,
                  JsonCombinators.Json.Decode.field("score", JsonCombinators.Json.Decode.float),
                ) {
                | Ok(s) => s
                | Error(_) => -1.0
                }

                if score >= 0.0 {
                  Some(unsafeCastToQuality(q))
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
    })

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
}

let executeProcessingChain = (
  uniqueItems: array<uploadItem>,
  maxConcurrency: int,
  startTime: float,
  updateProgress: (~eta: string=?, float, string, bool, string) => unit,
  skippedCount: int,
  journalId: string,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  Logger.info(~module_="UploadLogic", ~message="EXECUTE_PROCESSING_CHAIN_START", ())
  updateProgress(10.0, "Optimizing images...", true, "Analyzing")

  let processedCount = ref(0)
  let allProcessedItems = ref([])
  let lastJournalUpdate = ref(Date.now())
  let inFlightBudgetMb = selectInFlightBudgetMb(uniqueItems)

  Logger.info(
    ~module_="UploadLogic",
    ~message="UPLOAD_BYTE_BUDGET_SELECTED",
    ~data=Some({
      "fileCount": Belt.Array.length(uniqueItems),
      "budgetMb": inFlightBudgetMb,
      "maxConcurrency": maxConcurrency,
    }),
    (),
  )

  AsyncQueue.executeWeighted(
    uniqueItems,
    ~maxConcurrency,
    ~weightOf=item => bytesToMb(BrowserBindings.File.size(item.original)),
    ~maxInFlightWeight=inFlightBudgetMb,
    (i, item, updateStatus) => {
      updateStatus("Optimizing")
      UploadItemProcessor.processItem(i, item, updateStatus)->Promise.then(processedItem => {
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
      let scaledPct = 10.0 +. 88.0 *. pct
      updateProgress(scaledPct, msg, true, "Optimizing")
    },
  )->Promise.then(_ => {
    let validProcessed = Belt.Array.keep(allProcessedItems.contents, i => i.error == None)

    if Belt.Array.length(validProcessed) == 0 && Belt.Array.length(uniqueItems) > 0 {
      UploadUtils.notify("All uploads failed.", "error")
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

      let existingScenes = SceneInventory.getActiveScenes(
        getState().inventory,
        getState().sceneOrder,
      )
      let _existingScenesCount = Belt.Array.length(existingScenes)
      let seqStart = getState().nextSceneSequenceId

      let finalItems = Belt.Array.mapWithIndex(sortedItems, (i, item) => {
        let seq = seqStart + i
        let newName = TourLogic.computeSceneFilename(seq, "", "")

        // Simplified Clustering: Map avgLuminance to 1-5 Scale
        let colorGroup =
          item.quality
          ->Option.flatMap(
            q => {
              switch JsonCombinators.Json.decode(q, JsonParsers.Shared.qualityAnalysis) {
              | Ok(qa) =>
                let lum = qa.stats.avgLuminance
                // Map 0-255 luminance to 1-5 buckets
                // 1: Dark (0-50), 2: Dim (51-100), 3: Normal (101-150), 4: Bright (151-200), 5: Very Bright (201-255)
                let bucket = if lum <= 50 {
                  "1"
                } else if lum <= 100 {
                  "2"
                } else if lum <= 150 {
                  "3"
                } else if lum <= 200 {
                  "4"
                } else {
                  "5"
                }
                Some(bucket)
              | Error(_) => None
              }
            },
          )
          ->Option.getOr("3") // Default to normal if data missing

        {
          ...item,
          colorGroup: Some(colorGroup),
          preview: item.preview->Option.map(
            f => {
              File.newFile([f], newName, {"type": File.type_(f)})
            },
          ),
        }
      })

      let jsonPayload = UploadReporting.createScenePayload(finalItems)
      dispatch(AddScenes(jsonPayload))
      PersistenceLayer.performSave(getState())

      finalizeUploads(finalItems, startTime, updateProgress, skippedCount, ~getState, ~dispatch)
      ->Promise.then(res => {
        UploadReporting.triggerBackgroundTitleDiscovery(finalItems, ~getState, ~dispatch)
        Promise.resolve(res)
      })
    }
  })
}
