open Actions

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
      ~onDuplicate=c =>
        UploadUtils.notify("Skipped " ++ Belt.Int.toString(c) ++ " duplicates.", "info"),
      ~onRestore=id => dispatch(RemoveDeletedSceneId(id)),
    )
    let skippedFromFingerprint = Belt.Array.length(results) - Belt.Array.length(uniqueItems)
    UploadFinalizer.executeProcessingChain(
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
