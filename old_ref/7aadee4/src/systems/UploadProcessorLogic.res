/* src/systems/UploadProcessorLogic.res */
open ReBindings
open SharedTypes

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

let validateFiles = (files: array<ReBindings.File.t>) => {
  let allowedExtensions = ["jpg", "jpeg", "png", "webp", "heic", "heif"]
  Belt.Array.keep(files, f => {
    let name = File.name(f)
    let parts = String.split(name, ".")
    let len = Array.length(parts)
    let ext = if len > 1 {
      switch Belt.Array.get(parts, len - 1) {
      | Some(e) => String.toLowerCase(e)
      | None => ""
      }
    } else {
      ""
    }

    let type_ = String.toLowerCase(File.type_(f))
    let isImage = String.startsWith(type_, "image/") || Array.includes(allowedExtensions, ext)

    if !isImage {
      notify("Skipped invalid file: " ++ name, "warning")
    }
    isImage
  })
}

let fingerprintFiles = (validFiles: array<ReBindings.File.t>) => {
  let fingerprintPromises = Belt.Array.map(validFiles, f => {
    Resizer.getChecksum(f)
    ->Promise.then(id =>
      Promise.resolve(
        (
          {
            id: Nullable.make(id),
            original: f,
            error: None,
            preview: None,
            tiny: None,
            quality: None,
            metadata: None,
            colorGroup: None,
          }: UploadProcessorTypes.uploadItem
        ),
      )
    )
    ->Promise.catch(_err => {
      Logger.error(
        ~module_="Upload",
        ~message="FINGERPRINT_FAILED",
        ~data=Some({"filename": File.name(f)}),
        (),
      )
      Promise.resolve(
        (
          {
            id: Nullable.null,
            original: f,
            error: Some("Fingerprint failed"),
            preview: None,
            tiny: None,
            quality: None,
            metadata: None,
            colorGroup: None,
          }: UploadProcessorTypes.uploadItem
        ),
      )
    })
  })
  Promise.all(fingerprintPromises)
}

let filterDuplicates = (results: array<UploadProcessorTypes.uploadItem>) => {
  let storeState = GlobalStateBridge.getState()
  let existingScenes = storeState.scenes
  let existingIds = Belt.Set.String.fromArray(Belt.Array.map(existingScenes, s => s.id))
  let deletedIds = Belt.Set.String.fromArray(storeState.deletedSceneIds)

  let uniqueItems = []
  let skippedCount = ref(0)

  Belt.Array.forEach(results, item => {
    switch Nullable.toOption(item.id) {
    | Some(id) =>
      if Belt.Set.String.has(existingIds, id) {
        skippedCount := skippedCount.contents + 1
      } else {
        if Belt.Set.String.has(deletedIds, id) {
          GlobalStateBridge.dispatch(RemoveDeletedSceneId(id))
        }
        let _ = Array.push(uniqueItems, item)
      }
    | None => () /* Failed item */
    }
  })

  if skippedCount.contents > 0 {
    notify("Skipped " ++ Belt.Int.toString(skippedCount.contents) ++ " duplicates.", "info")
  }
  uniqueItems
}

let processItem = (i, item: UploadProcessorTypes.uploadItem, onStatus: string => unit) => {
  Logger.debug(
    ~module_="Upload",
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
        item.quality = Some(castToJson(res.quality))

        let qObj = res.quality
        Logger.debug(
          ~module_="Upload",
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
            ~module_="Upload",
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
          ~module_="Upload",
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
      ~module_="Upload",
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

        // Remove from active statuses
        // We can't actually remove keys easily in ReScript Dict/Js.Dict without Obj.magic or treating as generic object
        // So we just set it to "Done" or ignore it.
        // Better: recreate dict or use Map?
        // For simplicity, let's just mark it 'Done' and filter it out in counts logic if we wanted,
        // but actually we just want active.

        // Actually, Dict doesn't have a remove. We'll set it to a special value that we ignore.
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
  updateProgress(95.0, "Syncing scene blocks...", true, "Clustering")
  Logger.debug(~module_="Upload", ~message="PHASE_CLUSTERING", ())

  let _ = Array.sort(validProcessed, (a, b) => {
    String.localeCompare(File.name(a.original), File.name(b.original))
  })

  let existingScenes = GlobalStateBridge.getState().scenes
  let existingCount = Belt.Array.length(existingScenes)
  let lastExistingScene = if existingCount > 0 {
    Belt.Array.get(existingScenes, existingCount - 1)
  } else {
    None
  }

  // Build pairs for batch similarity
  let pairs: array<similarityPair> = []
  Belt.Array.forEachWithIndex(validProcessed, (i, current) => {
    let currentId = Nullable.toOption(current.id)->Option.getOr(File.name(current.original))
    let currentQ = current.quality

    switch currentQ {
    | Some(q) =>
      // Compare with last 3 in batch
      for j in 1 to 3 {
        let prevIdx = i - j
        if prevIdx >= 0 {
          switch Belt.Array.get(validProcessed, prevIdx) {
          | Some(prev) =>
            switch prev.quality {
            | Some(pq) =>
              let prevId = Nullable.toOption(prev.id)->Option.getOr(File.name(prev.original))
              let _ = Array.push(
                pairs,
                {
                  idA: currentId,
                  idB: prevId,
                  histogramA: q,
                  histogramB: pq,
                },
              )
            | None => ()
            }
          | None => ()
          }
        }
      }

      // Compare with last existing
      switch lastExistingScene {
      | Some(lastS) =>
        switch lastS.quality {
        | Some(lq) =>
          let lastId = lastS.id
          let _ = Array.push(
            pairs,
            {
              idA: currentId,
              idB: lastId,
              histogramA: q,
              histogramB: lq,
            },
          )
        | None => ()
        }
      | None => ()
      }
    | None => ()
    }
  })

  let similarityPromise = if Belt.Array.length(pairs) > 0 {
    BackendApi.batchCalculateSimilarity(pairs)
  } else {
    Promise.resolve(Ok([]))
  }

  similarityPromise->Promise.then(result => {
    let similarities = switch result {
    | Ok(s) => s
    | Error(msg) =>
      notify("Grouping failed: " ++ msg, "warning")
      []
    }
    // Build lookup map
    let simMap = Dict.make()
    Belt.Array.forEach(similarities, (result: similarityResult) => {
      let key = result.idA ++ "_" ++ result.idB
      Dict.set(simMap, key, result.similarity)
    })

    let getSimilarity = (idA, idB) => {
      Dict.get(simMap, idA ++ "_" ++ idB)->Option.getOr(0.0)
    }

    let lastGroupRef = ref(0)
    if existingCount > 0 {
      switch lastExistingScene {
      | Some(lastS) =>
        switch lastS.colorGroup {
        | Some(gStr) =>
          switch Belt.Int.fromString(gStr) {
          | Some(g) => lastGroupRef := g
          | None => ()
          }
        | None => ()
        }
      | None => ()
      }
    }

    Belt.Array.forEachWithIndex(validProcessed, (i, current) => {
      let foundMatch = ref(None)
      let currentId = Nullable.toOption(current.id)->Option.getOr(File.name(current.original))

      for j in 1 to 3 {
        if foundMatch.contents == None {
          let prevIdx = i - j
          if prevIdx >= 0 {
            switch Belt.Array.get(validProcessed, prevIdx) {
            | Some(prev) =>
              let prevId = Nullable.toOption(prev.id)->Option.getOr(File.name(prev.original))
              let score = getSimilarity(currentId, prevId)
              if score > 0.65 {
                foundMatch := prev.colorGroup
              }
            | None => ()
            }
          }
        }
      }

      if foundMatch.contents == None && existingCount > 0 {
        /* Check match with last existing */
        switch lastExistingScene {
        | Some(lastS) =>
          let lastId = lastS.id
          let score = getSimilarity(currentId, lastId)
          if score > 0.65 {
            foundMatch := lastS.colorGroup
          }
        | None => ()
        }
      }

      switch foundMatch.contents {
      | Some(g) => current.colorGroup = Some(g)
      | None =>
        lastGroupRef := lastGroupRef.contents + 1
        current.colorGroup = Some(Belt.Int.toString(lastGroupRef.contents))
      }
    })

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
    GlobalStateBridge.dispatch(AddScenes(jsonPayload))

    if wasEmpty {
      // Reset preloading index to ensure clean start
      GlobalStateBridge.dispatch(SetPreloadingScene(-1))
    }

    let reportData = Belt.Array.map(validProcessed, i => {
      let item: ExifReportGenerator.sceneDataItem = {
        original: i.original,
        metadata: i.metadata,
        quality: i.quality,
      }
      item
    })

    // Report for Dialog (passed back via Promise)
    let successNames = Belt.Array.map(validProcessed, i => File.name(i.original))
    let report: Types.uploadReport = {
      success: successNames,
      skipped: [], // Skipped are handled earlier, focused on success here
    }

    ExifReportGenerator.generateExifReport(reportData)
    ->Promise.then(res => {
      GlobalStateBridge.dispatch(SetExifReport(JSON.Encode.string(res.report)))

      let suggestedNameResult = res.suggestedName

      Logger.info(
        ~module_="Upload",
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
              ~module_="Upload",
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
            "qualityResults": Belt.Array.map(
              validProcessed,
              i => {
                let qItem: UploadReport.qualityItem = {
                  quality: i.quality
                  ->Option.map((q): SharedTypes.qualityAnalysis => Obj.magic(q))
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
            "duration": durationStr,
            "report": report,
          }: UploadProcessorTypes.processResult
        ),
      )
    })
  })
}
