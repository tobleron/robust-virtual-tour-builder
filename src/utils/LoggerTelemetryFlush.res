/* src/utils/LoggerTelemetryFlush.res */

open LoggerCommon

type flushPayload = {
  takeCount: int,
  payload: telemetryBatch,
}

let buildFlushPayload = (
  ~telemetryQueue: array<logEntry>,
  ~deduplicateBatchEntries: array<logEntry> => array<logEntry>,
): flushPayload => {
  let batchLimit = Constants.Telemetry.batchSize
  let currentQueueLen = Array.length(telemetryQueue)
  let takeCount = if currentQueueLen > batchLimit {
    batchLimit
  } else {
    currentQueueLen
  }
  let batch = Belt.Array.slice(telemetryQueue, ~offset=0, ~len=takeCount)->deduplicateBatchEntries
  {takeCount, payload: {entries: batch}}
}

let tryFlushWithBeacon = (
  ~encodeTelemetryBatch: telemetryBatch => JSON.t,
  ~noteTelemetryPayloadBytes: int => unit,
  payload: telemetryBatch,
): bool => {
  if WebApiBindings.hasSendBeacon() {
    let jsonStr = JsonCombinators.Json.stringify(encodeTelemetryBatch(payload))
    let blob = BrowserBindings.Blob.newBlob([jsonStr], {"type": "application/json"})
    let sent = WebApiBindings.sendBeaconBlob(Constants.backendUrl ++ "/api/telemetry/batch", blob)
    if sent {
      noteTelemetryPayloadBytes(String.length(jsonStr))
    }
    sent
  } else {
    false
  }
}

let completeFlush = (
  ~_telemetryQueue: array<logEntry>,
  ~_takeCount: int,
  ~networkSuccess: bool,
  ~suspendTelemetry: unit => unit,
) => {
  if networkSuccess {
    ignore(%raw(`_telemetryQueue.splice(0, _takeCount)`))
  } else {
    suspendTelemetry()
  }
}
