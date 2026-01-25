/* src/systems/UploadProcessor.res */
open ReBindings
open UploadProcessorTypes
open UploadProcessorLogic
open Actions

let processUploads = (
  files: array<file>,
  progressCallback: option<(float, string, bool, string) => unit>,
): Promise.t<processResult> => {
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
        "Backend Server Not Connected! The image processing server (port 8080) is not running. Please start the backend server with 'npm run dev:backend' or 'cargo run' in the backend directory.",
        "error",
      )
      Promise.resolve({
        qualityResults: [],
        duration: "0.0",
        report: ({success: [], skipped: []}: Types.uploadReport),
      })
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
        Promise.resolve({
          qualityResults: [],
          duration: "0.0",
          report: ({success: [], skipped: []}: Types.uploadReport),
        })
      } else {
        /* Validate Files */
        let validFiles = ImageValidator.validateFiles(files, msg => notify(msg, "warning"))

        if Belt.Array.length(validFiles) == 0 {
          notify("No valid image files selected!", "error")
          Promise.resolve({
            qualityResults: [],
            duration: "0.0",
            report: ({success: [], skipped: []}: Types.uploadReport),
          })
        } else {
          /* Phase 1: Fingerprinting */
          updateProgress(0.0, "Scanning files...", true, "Fingerprinting")
          Logger.debug(~module_="Upload", ~message="PHASE_FINGERPRINTING", ())

          FingerprintService.fingerprintFiles(validFiles)->Promise.then(results => {
            updateProgress(18.0, "Cleaning up scanning...", true, "Fingerprinting")

            /* Filter duplicates */
            let state = GlobalStateBridge.getState()
            let uniqueItems = FingerprintService.filterDuplicates(
              results,
              ~existingScenes=state.scenes,
              ~deletedIds=state.deletedSceneIds,
              ~onDuplicate=c =>
                notify("Skipped " ++ Belt.Int.toString(c) ++ " duplicates.", "info"),
              ~onRestore=id => GlobalStateBridge.dispatch(RemoveDeletedSceneId(id)),
            )

            /* Phase 2: Optimization */
            updateProgress(20.0, "Processing images...", true, "Processing")
            Logger.debug(~module_="Upload", ~message="PHASE_PROCESSING", ())

            processWithQueue(uniqueItems, 6, updateProgress)->Promise.then(
              processedItems => {
                let validProcessed = Belt.Array.keep(processedItems, i => i.error == None)

                if Belt.Array.length(validProcessed) == 0 && Belt.Array.length(uniqueItems) > 0 {
                  notify("All uploads failed.", "error")
                  Promise.resolve({
                    qualityResults: [],
                    duration: "0.0",
                    report: ({success: [], skipped: []}: Types.uploadReport),
                  })
                } else {
                  /* Phase 3: Clustering & Finalizing */
                  finalizeUploads(validProcessed, startTime, updateProgress)->Promise.then(
                    res => {
                      Logger.endOperation(
                        ~module_="Upload",
                        ~operation="BATCH",
                        ~data=Some({
                          "successful": Belt.Array.length(validProcessed),
                          "failed": Belt.Array.length(uniqueItems) -
                          Belt.Array.length(validProcessed),
                          "totalDurationMs": Date.now() -. startTime,
                        }),
                        (),
                      )
                      Promise.resolve(res)
                    },
                  )
                }
              },
            )
          })
        }
      }
    }
  })
}
