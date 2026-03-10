/* src/utils/LoggerTelemetryTransport.res */

open ReBindings
open LoggerCommon

type transportTask = {
  task: unit => Promise.t<unit>,
  resolve: unit => unit,
  reject: exn => unit,
}

type responseValidation = LoggerTelemetryResponse.responseValidation =
  | TelemetryResponseOk
  | TelemetryResponseRateLimited({status: int, retryMs: float})
  | TelemetryResponseHttpError(int)

type flushPayload = LoggerTelemetryFlush.flushPayload = {
  takeCount: int,
  payload: telemetryBatch,
}

let nowMs = () => Date.now()

let clearSuspensionIfExpired = (
  ~nowMs: unit => float,
  ~telemetrySuspendedUntil: ref<float>,
) => {
  if telemetrySuspendedUntil.contents != 0.0 && nowMs() >= telemetrySuspendedUntil.contents {
    telemetrySuspendedUntil := 0.0
  }
}

let isTelemetrySuspended = (
  ~clearSuspensionIfExpired: unit => unit,
  ~telemetrySuspendedUntil: ref<float>,
) => {
  clearSuspensionIfExpired()
  telemetrySuspendedUntil.contents != 0.0
}

let suspendTelemetry = (~nowMs: unit => float, ~telemetrySuspendedUntil: ref<float>) =>
  telemetrySuspendedUntil := nowMs() + Constants.Telemetry.suspendDurationMs

let suspendTelemetryForMs = (
  ~nowMs: unit => float,
  ~telemetrySuspendedUntil: ref<float>,
  ~_telemetryQueue: array<logEntry>,
  durationMs: float,
) => {
  let boundedDurationMs = if durationMs <= 0.0 {
    Constants.Telemetry.suspendDurationMs
  } else {
    durationMs
  }
  telemetrySuspendedUntil := nowMs() + boundedDurationMs
  ignore(%raw(`_telemetryQueue.splice(0, _telemetryQueue.length)`))
}

let parseRetryAfterHeaderMs = (res: Fetch.response): option<float> =>
  LoggerTelemetryResponse.parseRetryAfterHeaderMs(res)

let classifyTelemetryResponse = (
  ~parseRetryAfterHeaderMs: Fetch.response => option<float>,
  res: Fetch.response,
): responseValidation =>
  LoggerTelemetryResponse.classifyTelemetryResponse(~parseRetryAfterHeaderMs, res)

let validationToPromise = (
  ~suspendTelemetryForMs: float => unit,
  validation: responseValidation,
): Promise.t<unit> =>
  LoggerTelemetryResponse.validationToPromise(~suspendTelemetryForMs, validation)

let validateTelemetryResponse = (
  ~parseRetryAfterHeaderMs: Fetch.response => option<float>,
  ~suspendTelemetryForMs: float => unit,
  res: Fetch.response,
): Promise.t<unit> =>
  LoggerTelemetryResponse.validateTelemetryResponse(
    ~parseRetryAfterHeaderMs,
    ~suspendTelemetryForMs,
    res,
  )

let canUseTelemetryNetwork = (~isTelemetrySuspended: unit => bool) =>
  Constants.Telemetry.enabled && !isTelemetrySuspended()

let noteTelemetryPayloadBytes = (
  ~nowMs: unit => float,
  ~bandwidthWindowStartMs: ref<float>,
  ~bandwidthBytesSent: ref<int>,
  ~adaptiveSamplingScale: ref<float>,
  ~samplingBandwidthBudgetBytesPerSec: int,
  payloadBytes: int,
) => {
  let now = nowMs()
  if bandwidthWindowStartMs.contents == 0.0 {
    bandwidthWindowStartMs := now
  } else if now -. bandwidthWindowStartMs.contents >= 1000.0 {
    bandwidthWindowStartMs := now
    bandwidthBytesSent := 0
    adaptiveSamplingScale := 1.0
  }

  bandwidthBytesSent := bandwidthBytesSent.contents + payloadBytes
  if bandwidthBytesSent.contents > samplingBandwidthBudgetBytesPerSec {
    adaptiveSamplingScale := 0.5
  }
}

let rec processTransportQueue = (
  ~transportActive: ref<int>,
  ~transportQueue: array<transportTask>,
) => {
  if (
    transportActive.contents < Constants.Telemetry.transportMaxConcurrent &&
      Array.length(transportQueue) > 0
  ) {
    switch Array.shift(transportQueue) {
    | Some(entry) =>
      transportActive := transportActive.contents + 1
      let _ =
        entry.task()
        ->Promise.then(_ => {
          transportActive := transportActive.contents - 1
          entry.resolve()
          processTransportQueue(~transportActive, ~transportQueue)
          Promise.resolve()
        })
        ->Promise.catch(err => {
          transportActive := transportActive.contents - 1
          entry.reject(err)
          processTransportQueue(~transportActive, ~transportQueue)
          Promise.resolve()
        })
        ->ignore
    | None => ()
    }
  }
}

let scheduleTransport = (
  ~transportQueue: array<transportTask>,
  ~transportQueueOverflowReason: string,
  ~processTransportQueue: unit => unit,
  task: unit => Promise.t<unit>,
): Promise.t<unit> =>
  Promise.make((resolve, reject) => {
    if Array.length(transportQueue) >= Constants.Telemetry.transportMaxQueued {
      reject(Failure(transportQueueOverflowReason))
    } else {
      let entry = {task, resolve: _ => resolve(), reject}
      let _ = Array.push(transportQueue, entry)
      processTransportQueue()
    }
  })

let isTransportQueueOverflow = (~transportQueueOverflowReason: string, err: exn) =>
  getErrorMessage(err) == transportQueueOverflowReason

let buildFlushPayload = (
  ~telemetryQueue: array<logEntry>,
  ~deduplicateBatchEntries: array<logEntry> => array<logEntry>,
): flushPayload =>
  LoggerTelemetryFlush.buildFlushPayload(~telemetryQueue, ~deduplicateBatchEntries)

let tryFlushWithBeacon = (
  ~encodeTelemetryBatch: telemetryBatch => JSON.t,
  ~noteTelemetryPayloadBytes: int => unit,
  payload: telemetryBatch,
): bool =>
  LoggerTelemetryFlush.tryFlushWithBeacon(~encodeTelemetryBatch, ~noteTelemetryPayloadBytes, payload)

let completeFlush = (
  ~_telemetryQueue: array<logEntry>,
  ~_takeCount: int,
  ~networkSuccess: bool,
  ~suspendTelemetry: unit => unit,
) =>
  LoggerTelemetryFlush.completeFlush(~_telemetryQueue, ~_takeCount, ~networkSuccess, ~suspendTelemetry)

let rec attemptSendBatch = async (
  ~canUseTelemetryNetwork: unit => bool,
  ~scheduleTransport: (unit => Promise.t<unit>) => Promise.t<unit>,
  ~encodeTelemetryBatch: telemetryBatch => JSON.t,
  ~validateTelemetryResponse: Fetch.response => Promise.t<unit>,
  ~noteTelemetryPayloadBytes: int => unit,
  ~isTransportQueueOverflow: exn => bool,
  ~suspendTelemetry: unit => unit,
  payload: telemetryBatch,
  retries: int,
) => {
  if !canUseTelemetryNetwork() {
    false
  } else {
    try {
      let _ = await scheduleTransport(async () => {
        let encodedPayload = JsonCombinators.Json.stringify(encodeTelemetryBatch(payload))
        let res = await Fetch.fetch(
          Constants.backendUrl ++ "/api/telemetry/batch",
          Fetch.requestInit(
            ~method="POST",
            ~headers=Dict.fromArray([("Content-Type", "application/json")]),
            ~body=encodedPayload,
            (),
          ),
        )
        let _ = await validateTelemetryResponse(res)
        noteTelemetryPayloadBytes(String.length(encodedPayload))
      })
      true
    } catch {
    | err if isTransportQueueOverflow(err) => false
    | _ if retries < Constants.Telemetry.retryMaxAttempts => {
        let delay = Belt.Float.toInt(
          Belt.Int.toFloat(Constants.Telemetry.retryBackoffMs) *.
          Math.pow(2.0, ~exp=Belt.Int.toFloat(retries)),
        )
        let _ = await Promise.make((resolve, _) => {
          let _ = Window.setTimeout(() => resolve(ignore()), delay)
        })
        await attemptSendBatch(
          ~canUseTelemetryNetwork,
          ~scheduleTransport,
          ~encodeTelemetryBatch,
          ~validateTelemetryResponse,
          ~noteTelemetryPayloadBytes,
          ~isTransportQueueOverflow,
          ~suspendTelemetry,
          payload,
          retries + 1,
        )
      }
    | _ => {
        Console.error("[Logger] Failed to send telemetry batch after max retries")
        suspendTelemetry()
        false
      }
    }
  }
}

let isBrowserRuntime = (): bool =>
  %raw(`typeof window !== "undefined" && typeof document !== "undefined"`)
