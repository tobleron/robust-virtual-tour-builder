open Types
open Actions
open ReBindings

/* Bindings for File API */
/* Using ReBindings.File directly */
type file = ReBindings.File.t

/* Bindings for External Systems */
/* Bindings for External Systems */
/* Direct usage of Resizer module which is now native ReScript */
/* No more Resizer.js adapter bindings needed */

// Store bindings removed. Using GlobalStateBridge.

let notify = (msg, typeStr) => {
  let type_ = switch typeStr {
  | "error" => #Error
  | "warning" => #Warning
  | "success" => #Success
  | _ => #Info
  }
  EventBus.dispatch(ShowNotification(msg, type_))
}

// Debug module removed. Using Logger.res

/* Helper Types */
type uploadItem = {
  id: Nullable.t<string>,
  original: file,
  mutable error: option<string>,
  mutable preview: option<file>,
  mutable tiny: option<file>,
  mutable quality: option<JSON.t>,
  mutable metadata: option<JSON.t>,
  mutable colorGroup: option<string>,
}

/* Main Processor */

let processUploads = (
  files: array<file>,
  progressCallback: option<(float, string, bool, string) => unit>,
) => {
  let updateProgress = (pct, msg, isProc, phase) => {
    switch progressCallback {
    | Some(cb) => cb(pct, msg, isProc, phase)
    | None => ()
    }
  }

  /* Phase 0: Health Check */
  updateProgress(0.0, "Checking backend...", true, "Health Check")

  Resizer.checkBackendHealth()->Promise.then(isUp => {
    if !isUp {
      Logger.error(~module_="Upload", ~message="BACKEND_OFFLINE", ())
      updateProgress(100.0, "Error: Backend Offline", false, "Error")
      notify(
        "Backend Server Not Connected! Please ensure the Rust backend is running on port 8080.",
        "error",
      )
      Promise.resolve({"qualityResults": [], "duration": "0.0"})
    } else {
      let startTime = Date.now()
      let totalFilesValue = Belt.Array.length(files)
      
      let totalSize = Belt.Array.reduce(files, 0.0, (acc, f) => acc +. File.size(f))
      
      Logger.startOperation(
        ~module_="Upload",
        ~operation="BATCH",
        ~data=Some({"fileCount": totalFilesValue, "totalSize": totalSize}),
        (),
      )

      if totalFilesValue == 0 {
        Promise.resolve({"qualityResults": [], "duration": "0.0"})
      } else {
        /* Validate Files */
        let allowedExtensions = ["jpg", "jpeg", "png", "webp", "heic", "heif"]
        let validFiles = Belt.Array.keep(files, f => {
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

        if Belt.Array.length(validFiles) == 0 {
          notify("No valid image files selected!", "error")
          Promise.resolve({"qualityResults": [], "duration": "0.0"})
        } else {
          /* Phase 1: Fingerprinting */
          updateProgress(0.0, "Scanning files...", true, "Fingerprinting")
          Logger.debug(~module_="Upload", ~message="PHASE_FINGERPRINTING", ())

          let fingerprintPromises = Belt.Array.map(validFiles, f => {
            Resizer.getChecksum(f)
            ->Promise.then(
              id =>
                Promise.resolve({
                  id: Nullable.make(id),
                  original: f,
                  error: None,
                  preview: None,
                  tiny: None,
                  quality: None,
                  metadata: None,
                  colorGroup: None,
                }),
            )
            ->Promise.catch(
              _err => {
                Logger.error(~module_="Upload", ~message="FINGERPRINT_FAILED", ~data=Some({"filename": File.name(f)}), ())
                Promise.resolve({
                  id: Nullable.null,
                  original: f,
                  error: Some("Fingerprint failed"),
                  preview: None,
                  tiny: None,
                  quality: None,
                  metadata: None,
                  colorGroup: None,
                })
              },
            )
          })

          Promise.all(fingerprintPromises)->Promise.then(results => {
            updateProgress(18.0, "Cleaning up scanning...", true, "Fingerprinting")

            /* Filter duplicates */
            let storeState = GlobalStateBridge.getState()
            let existingScenes = storeState.scenes
            let existingIds = Belt.Set.String.fromArray(Belt.Array.map(existingScenes, s => s.id))
            let deletedIds = Belt.Set.String.fromArray(storeState.deletedSceneIds)

            let uniqueItems = []
            let skippedCount = ref(0)

            Belt.Array.forEach(
              results,
              item => {
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
              },
            )

            if skippedCount.contents > 0 {
              notify(
                "Skipped " ++ Belt.Int.toString(skippedCount.contents) ++ " duplicates.",
                "info",
              )
            }

            /* Phase 2: Optimization */
            updateProgress(20.0, "Processing images...", true, "Processing")
            Logger.debug(~module_="Upload", ~message="PHASE_PROCESSING", ())

            let processPromises = Belt.Array.mapWithIndex(
              uniqueItems,
              (i, item) => {
                Logger.debug(~module_="Upload", ~message="FILE_START", ~data=Some({
                  "filename": File.name(item.original),
                  "index": i,
                  "size": File.size(item.original)
                }), ())
                
                Resizer.processAndAnalyzeImage(item.original)
                ->Promise.then(
                  res => {
                    item.preview = Some(res.preview)
                    item.tiny = res.tiny
                    item.metadata = Some(Obj.magic(res.metadata))
                    item.quality = Some(Obj.magic(res.quality))
                    
                    let qObj = res.quality
                    Logger.debug(~module_="Upload", ~message="QUALITY_ANALYSIS", ~data=Some({
                      "filename": File.name(item.original),
                      "avgLuminance": qObj.stats.avgLuminance,
                      "sharpnessVariance": qObj.stats.sharpnessVariance,
                      "isBlurry": qObj.isBlurry
                    }), ())
                    
                    if qObj.isSeverelyDark || qObj.isDim {
                      Logger.warn(~module_="Upload", ~message="LOW_BRIGHTNESS", ~data=Some({
                        "filename": File.name(item.original),
                        "avgLuminance": qObj.stats.avgLuminance
                      }), ())
                    }

                    Promise.resolve(item)
                  },
                )
                ->Promise.catch(
                  err => {
                    Logger.error(~module_="Upload", ~message="FILE_FAILED", ~data=Some({
                      "filename": File.name(item.original),
                      "error": err
                    }), ())
                    item.error = Some("Processing failed")
                    Promise.resolve(item)
                  },
                )
              },
            )

            Promise.all(processPromises)->Promise.then(
              processedItems => {
                let validProcessed = Belt.Array.keep(processedItems, i => i.error == None)

                if Belt.Array.length(validProcessed) == 0 && Belt.Array.length(uniqueItems) > 0 {
                  notify("All uploads failed.", "error")
                  Promise.resolve({"qualityResults": [], "duration": "0.0"})
                } else {
                  /* Phase 3: Clustering */
                  updateProgress(95.0, "Syncing scene blocks...", true, "Clustering")
                  Logger.debug(~module_="Upload", ~message="PHASE_CLUSTERING", ())

                  let _ = Array.sort(
                    validProcessed,
                    (a, b) => {
                      String.localeCompare(File.name(a.original), File.name(b.original))
                    },
                  )

                  let existingScenes = GlobalStateBridge.getState().scenes
                  let existingCount = Belt.Array.length(existingScenes)

                  let lastGroupRef = ref(0)
                  if existingCount > 0 {
                    switch Belt.Array.get(existingScenes, existingCount - 1) {
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

                  Belt.Array.forEachWithIndex(
                    validProcessed,
                    (i, current) => {
                      let foundMatch = ref(None)
                      let currentQ = current.quality

                      switch currentQ {
                      | Some(q) =>
                        for j in 1 to 3 {
                          if foundMatch.contents == None {
                            let prevIdx = i - j
                            if prevIdx >= 0 {
                              switch Belt.Array.get(validProcessed, prevIdx) {
                              | Some(prev) =>
                                switch (prev.quality, prev.colorGroup) {
                                | (Some(pq), Some(pg)) =>
                                  let score = ImageAnalysis.calculateSimilarity(
                                    Obj.magic(q),
                                    Obj.magic(pq),
                                  )
                                  if score > 0.65 {
                                    foundMatch := Some(pg)
                                  }
                                | _ => ()
                                }
                              | None => ()
                              }
                            }
                          }
                        }

                        if foundMatch.contents == None && existingCount > 0 {
                          /* Check match with last existing */
                          switch Belt.Array.get(existingScenes, existingCount - 1) {
                          | Some(lastS) =>
                            switch lastS.quality {
                            | Some(lq) =>
                              let score = ImageAnalysis.calculateSimilarity(
                                Obj.magic(q),
                                Obj.magic(lq),
                              )
                              if score > 0.65 {
                                foundMatch := lastS.colorGroup
                              }
                            | None => ()
                            }
                          | None => ()
                          }
                        }
                      | None => ()
                      }

                      switch foundMatch.contents {
                      | Some(g) => current.colorGroup = Some(g)
                      | None =>
                        lastGroupRef := lastGroupRef.contents + 1
                        current.colorGroup = Some(Belt.Int.toString(lastGroupRef.contents))
                      }
                    },
                  )

                  updateProgress(98.0, "Updating Sidebar...", true, "Finalizing")

                  let jsonPayload = Belt.Array.map(
                    validProcessed,
                    item => {
                      let preview = Option.getOr(item.preview, item.original)
                      let tiny = Option.getOr(item.tiny, preview)

                      let obj = Dict.make()
                      Dict.set(
                        obj,
                        "id",
                        Nullable.toOption(item.id)->Option.getOr("")->JSON.Encode.string,
                      )
                      Dict.set(obj, "originalName", File.name(item.original)->JSON.Encode.string)
                      Dict.set(obj, "name", File.name(preview)->JSON.Encode.string)

                      let unsafeObj = (
                        Obj.magic(obj): {
                          "id": string,
                          "originalName": string,
                          "name": string,
                          "original": file,
                          "preview": file,
                          "tiny": file,
                          "quality": JSON.t,
                          "metadata": JSON.t,
                          "colorGroup": string,
                        }
                      )

                      Obj.magic(unsafeObj)["original"] = item.original
                      Obj.magic(unsafeObj)["preview"] = preview
                      Obj.magic(unsafeObj)["tiny"] = tiny
                      Obj.magic(unsafeObj)["quality"] = Option.getOr(item.quality, JSON.Encode.null)
                      Obj.magic(unsafeObj)["metadata"] = Option.getOr(
                        item.metadata,
                        JSON.Encode.null,
                      )
                      Obj.magic(unsafeObj)["colorGroup"] = Option.getOr(item.colorGroup, "0")

                      (Obj.magic(unsafeObj): JSON.t)
                    },
                  )

                  GlobalStateBridge.dispatch(AddScenes(jsonPayload))

                  updateProgress(100.0, "Completed", false, "Done")

                  let reportData = Belt.Array.map(
                    validProcessed,
                    i => {
                      let item: ExifReportGenerator.sceneDataItem = {
                        original: Obj.magic(i.original),
                        metadata: i.metadata,
                        quality: i.quality,
                      }
                      item
                    },
                  )

                  ExifReportGenerator.generateExifReport(reportData)
                  ->Promise.then(res => res)
                  ->Promise.then(
                    res => {
                      GlobalStateBridge.dispatch(SetExifReport(JSON.Encode.string(res.report)))

                      if res.suggestedName != "" {
                        let currentName = GlobalStateBridge.getState().tourName
                        if currentName == "" {
                          GlobalStateBridge.dispatch(SetTourName(res.suggestedName))
                        }
                      }
                      Promise.resolve()
                    },
                  )
                  ->ignore

                  let durationStr = ((Date.now() -. startTime) /. 1000.0)->Float.toFixed(~digits=1)

                  Promise.resolve({
                    "qualityResults": [],
                    "duration": durationStr,
                  })->Promise.then(res => {
                    Logger.endOperation(~module_="Upload", ~operation="BATCH", ~data=Some({
                      "successful": Belt.Array.length(validProcessed),
                      "failed": Belt.Array.length(uniqueItems) - Belt.Array.length(validProcessed),
                      "totalDurationMs": Date.now() -. startTime
                    }), ())
                    Promise.resolve(res)
                  })
                }
              },
            )
          })
        }
      }
    }
  })
}
