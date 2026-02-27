open Actions

let bytesToMb = (sizeBytes: float): float => sizeBytes /. 1024.0 /. 1024.0

let pickUploadConcurrency = (files: array<UploadTypes.file>): int => {
  let totalBytes =
    files->Belt.Array.reduce(0.0, (acc, file) => acc +. BrowserBindings.File.size(file))
  let largestBytes = files->Belt.Array.reduce(0.0, (acc, file) => {
    let size = BrowserBindings.File.size(file)
    if size > acc {
      size
    } else {
      acc
    }
  })

  let totalMb = bytesToMb(totalBytes)
  let largestMb = bytesToMb(largestBytes)

  let selected = if (
    totalMb >= Constants.Media.uploadHeavyFolderThresholdMb ||
      largestMb >= Constants.Media.uploadVeryLargeFileThresholdMb
  ) {
    1
  } else if totalMb >= 600.0 {
    3
  } else if totalMb >= 350.0 {
    4
  } else {
    Constants.Media.uploadMaxConcurrencyDefault
  }

  Logger.info(
    ~module_="UploadLogic",
    ~message="UPLOAD_CONCURRENCY_SELECTED",
    ~data=Some({
      "fileCount": Belt.Array.length(files),
      "totalMb": Float.toFixed(totalMb, ~digits=1),
      "largestMb": Float.toFixed(largestMb, ~digits=1),
      "maxConcurrency": selected,
    }),
    (),
  )
  selected
}

let handleFingerprinting = (
  validFiles: array<UploadTypes.file>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  journalId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  Logger.info(~module_="UploadLogic", ~message="START_FINGERPRINTING", ())
  updateProgress(0.0, "Scanning images...", true, "Scanning")
  FingerprintService.fingerprintFiles(validFiles, ~signal?)->Promise.then(results => {
    updateProgress(18.0, "Preparing batch...", true, "Scanning")
    let currentState = getState()
    let uniqueItems = FingerprintService.filterDuplicates(
      results,
      ~inventory=currentState.inventory,
      ~onDuplicate=c =>
        UploadUtils.notify("Skipped " ++ Belt.Int.toString(c) ++ " duplicates.", "info"),
      ~onRestore=id => dispatch(RemoveDeletedSceneId(id)),
    )
    let skippedFromFingerprint = Belt.Array.length(results) - Belt.Array.length(uniqueItems)
    let uploadConcurrency = pickUploadConcurrency(validFiles)
    UploadFinalizer.executeProcessingChain(
      uniqueItems,
      uploadConcurrency,
      startTime,
      updateProgress,
      skippedFromFingerprint,
      journalId,
      ~getState,
      ~dispatch,
    )
  })
}
