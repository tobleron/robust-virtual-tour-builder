/* src/systems/UploadProcessorLogic.res */
// @efficiency-role: domain-logic
@@warning("-45")

open UploadTypes

type filenameItem = {item: uploadItem, name: string, index: int}

external castToJson: 'a => JSON.t = "%identity"

module Utils = {
  // Restore Utils to match snapshot
  module NotificationHelpers = {
    let getNotificationType = (typeStr: string) => {
      UploadUtils.NotificationHelpers.getNotificationType(typeStr)
    }
  }

  let notify = (msg, typeStr) => {
    UploadUtils.notify(msg, typeStr)
  }
}

// From UploadProcessorQueue
let handleProcessSuccess = (res: Resizer.processResult, item: uploadItem) => {
  UploadItemProcessor.handleProcessSuccess(res, item)
}

let handleProcessError = (msg, item: uploadItem) => {
  UploadItemProcessor.handleProcessError(msg, item)
}

let processItem = (i, item: uploadItem, onStatus: string => unit) => {
  UploadItemProcessor.processItem(i, item, onStatus)
}

// Helper for payload creation
let createScenePayload = (items: array<UploadTypes.uploadItem>) => {
  UploadReporting.createScenePayload(items)
}

let handleExifReport = (
  processedWithClusters: array<UploadTypes.uploadItem>,
  skippedCount: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  UploadReporting.handleExifReport(processedWithClusters, skippedCount, ~getState, ~dispatch)
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
  UploadFinalizer.finalizeUploads(
    validProcessed,
    startTime,
    updateProgress,
    skippedCount,
    ~getState,
    ~dispatch,
  )
}

let recoverUpload = (entry: OperationJournal.journalEntry) => {
  UploadRecovery.recoverUpload(entry)
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
  UploadFinalizer.executeProcessingChain(
    uniqueItems,
    maxConcurrency,
    startTime,
    updateProgress,
    skippedCount,
    journalId,
    ~getState,
    ~dispatch,
  )
}

let handleFingerprinting = (
  validFiles: array<UploadTypes.file>,
  startTime: float,
  updateProgress: (float, string, bool, string) => unit,
  journalId: string,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  UploadScanner.handleFingerprinting(
    validFiles,
    startTime,
    updateProgress,
    journalId,
    ~getState,
    ~dispatch,
  )
}
