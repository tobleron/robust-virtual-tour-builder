/* src/utils/LoggerTelemetry.res */

open ReBindings
open LoggerCommon

type transportTask = LoggerTelemetryTransport.transportTask

let telemetryQueue: array<logEntry> = []
let isFlushing = ref(false)
let bypassTestEnvCheck = ref(false)
let telemetrySuspendedUntil = ref(0.0)
let idleFlushPending = ref(false)
let bandwidthWindowStartMs = ref(0.0)
let bandwidthBytesSent = ref(0)
let adaptiveSamplingScale = ref(1.0)

let sampleRateInfo = 0.5
let sampleRateDebugProd = 0.1
let samplingBandwidthBudgetBytesPerSec = 10000

let setBypassTestEnvCheck = (v: bool) => { bypassTestEnvCheck := v }
let nowMs = () => Date.now()
let clearSuspensionIfExpired = () => {
  LoggerTelemetryTransport.clearSuspensionIfExpired(~nowMs, ~telemetrySuspendedUntil)
}
let isTelemetrySuspended = () => {
  LoggerTelemetryTransport.isTelemetrySuspended(~clearSuspensionIfExpired, ~telemetrySuspendedUntil)
}
let suspendTelemetry = () => {
  LoggerTelemetryTransport.suspendTelemetry(~nowMs, ~telemetrySuspendedUntil)
}

let suspendTelemetryForMs = (durationMs: float) => {
  LoggerTelemetryTransport.suspendTelemetryForMs(
    ~nowMs,
    ~telemetrySuspendedUntil,
    ~_telemetryQueue=telemetryQueue,
    durationMs,
  )
}

let parseRetryAfterHeaderMs = (res: Fetch.response): option<float> => {
  LoggerTelemetryTransport.parseRetryAfterHeaderMs(res)
}
let validateTelemetryResponse = async (res: Fetch.response): Promise.t<unit> => {
  let validation = LoggerTelemetryTransport.classifyTelemetryResponse(~parseRetryAfterHeaderMs, res)
  LoggerTelemetryTransport.validationToPromise(~suspendTelemetryForMs, validation)
}
let canUseTelemetryNetwork = () => Constants.Telemetry.enabled && !isTelemetrySuspended()

let noteTelemetryPayloadBytes = (payloadBytes: int) => {
  LoggerTelemetryTransport.noteTelemetryPayloadBytes(
    ~nowMs,
    ~bandwidthWindowStartMs,
    ~bandwidthBytesSent,
    ~adaptiveSamplingScale,
    ~samplingBandwidthBudgetBytesPerSec,
    payloadBytes,
  )
}

let transportQueue: array<transportTask> = []
let transportActive = ref(0)
let transportQueueOverflowReason = "TelemetryTransportQueueOverflow"

let processTransportQueue = () => {
  LoggerTelemetryTransport.processTransportQueue(~transportActive, ~transportQueue)
}

let scheduleTransport = (task: unit => Promise.t<unit>): Promise.t<unit> =>
  LoggerTelemetryTransport.scheduleTransport(
    ~transportQueue,
    ~transportQueueOverflowReason,
    ~processTransportQueue,
    task,
  )

let queueFillRatio = () => { LoggerTelemetryPolicy.queueFillRatio(~telemetryQueue) }
let shouldSendLowPriority = () => { LoggerTelemetryPolicy.shouldSendLowPriority(~telemetryQueue) }
let shouldQueueForPriority = p => {
  LoggerTelemetryPolicy.shouldQueueForPriority(~telemetryQueue, p)
}
let sanitizeJson = (_entry: JSON.t, _fields: array<string>): JSON.t => {
  LoggerTelemetryPayload.sanitizeJson(_entry, _fields)
}
let sanitizePayload = (data: option<JSON.t>): option<JSON.t> => {
  LoggerTelemetryPayload.sanitizePayload(data)
}
let encodeLogEntry = (entry: logEntry) => { LoggerTelemetryPayload.encodeLogEntry(entry) }
let encodeTelemetryBatch = (batch: telemetryBatch) => {
  LoggerTelemetryPayload.encodeTelemetryBatch(batch)
}
let deduplicateBatchEntries = (_entries: array<logEntry>): array<logEntry> => {
  LoggerTelemetryPayload.deduplicateBatchEntries(_entries)
}
let isTransportQueueOverflow = err => getErrorMessage(err) == transportQueueOverflowReason
let runIdle = (_task: unit => unit) => { LoggerTelemetryPolicy.runIdle(_task) }

let attemptSendBatch = async (payload: telemetryBatch, retries: int) => {
  await LoggerTelemetryTransport.attemptSendBatch(
    ~canUseTelemetryNetwork,
    ~scheduleTransport,
    ~encodeTelemetryBatch,
    ~validateTelemetryResponse=res =>
      LoggerTelemetryTransport.validateTelemetryResponse(
        ~parseRetryAfterHeaderMs,
        ~suspendTelemetryForMs,
        res,
      ),
    ~noteTelemetryPayloadBytes,
    ~isTransportQueueOverflow,
    ~suspendTelemetry,
    payload,
    retries,
  )
}

let hasFlushableTelemetry = () =>
  Array.length(telemetryQueue) > 0 && !isFlushing.contents && canUseTelemetryNetwork()

let flushTelemetry = async () => {
  if !NetworkStatus.isOnline() {
    Console.info2("[LoggerTelemetry] FLUSH_SKIPPED_OFFLINE. Queued:", Array.length(telemetryQueue))
  } else if hasFlushableTelemetry() {
    isFlushing := true

    let {takeCount, payload} = LoggerTelemetryTransport.buildFlushPayload(
      ~telemetryQueue,
      ~deduplicateBatchEntries,
    )
    let beaconSuccess = LoggerTelemetryTransport.tryFlushWithBeacon(
      ~encodeTelemetryBatch,
      ~noteTelemetryPayloadBytes,
      payload,
    )

    let networkSuccess = if beaconSuccess {
      true
    } else {
      await attemptSendBatch(payload, 0)
    }
    LoggerTelemetryTransport.completeFlush(
      ~_telemetryQueue=telemetryQueue,
      ~_takeCount=takeCount,
      ~networkSuccess,
      ~suspendTelemetry,
    )

    isFlushing := false
  }
}

let scheduleIdleFlush = () => {
  LoggerTelemetryPolicy.scheduleIdleFlush(~idleFlushPending, ~runIdle, ~flushTelemetry)
}

let shouldSampleByLevel = (level: level): bool => {
  LoggerTelemetryPolicy.shouldSampleByLevel(
    ~adaptiveSamplingScale,
    ~sampleRateInfo,
    ~sampleRateDebugProd,
    level,
  )
}

let sendTelemetry = async entry => {
  if !canUseTelemetryNetwork() {
    ()
  } else if Constants.isTestEnvironment() && !bypassTestEnvCheck.contents {
    ()
  } else if !shouldSampleByLevel(stringToLevel(entry.level)) {
    ()
  } else {
    let sanitizedEntry = {...entry, data: sanitizePayload(entry.data)}
    let p = stringToLevel(sanitizedEntry.level)->levelToTelemetryPriority

    switch p {
    | Critical =>
      try {
        let _ = await scheduleTransport(async () => {
          let encoded = JsonCombinators.Json.stringify(encodeLogEntry(sanitizedEntry))
          let res = await Fetch.fetch(
            Constants.backendUrl ++ "/api/telemetry/error",
            Fetch.requestInit(
              ~method="POST",
              ~headers=Dict.fromArray([("Content-Type", "application/json")]),
              ~body=encoded,
              (),
            ),
          )
          let _ = await validateTelemetryResponse(res)
          noteTelemetryPayloadBytes(String.length(encoded))
        })
      } catch {
      | err if isTransportQueueOverflow(err) => ()
      | err => {
          Console.error(`[Logger] Failed to send immediate telemetry: ${getErrorMessage(err)}`)
          suspendTelemetry()
        }
      }

    | High | Medium | Low =>
      let shouldSend = if p == High || p == Medium {
        true
      } else if Constants.Telemetry.diagnosticMode.contents {
        true
      } else {
        let filters = Constants.Telemetry.traceFilterModules
        let moduleName = sanitizedEntry.module_
        if Array.length(filters) == 0 {
          false
        } else {
          filters->Array.includes(moduleName) || filters->Array.includes("*")
        }
      }

      let shouldQueue = shouldSend && shouldQueueForPriority(p)
      if shouldQueue && Array.length(telemetryQueue) < Constants.Telemetry.queueMaxSize {
        let _ = Array.push(telemetryQueue, sanitizedEntry)
        if Array.length(telemetryQueue) >= Constants.Telemetry.batchSize {
          scheduleIdleFlush()
        }
      }
    }
  }
}

let initializeNetworkListener = () => {
  let _ = NetworkStatus.subscribe(online => {
    if online {
      Console.info("[LoggerTelemetry] FLUSH_ON_RECONNECT")
      telemetrySuspendedUntil := 0.0
      scheduleIdleFlush()
    }
  })
}

let flushWithBeaconOnUnload = () => {
  if (
    Array.length(telemetryQueue) == 0 ||
    !canUseTelemetryNetwork() ||
    !WebApiBindings.hasSendBeacon()
  ) {
    ()
  } else {
    let payload: telemetryBatch = {entries: deduplicateBatchEntries(telemetryQueue)}
    let jsonStr = JsonCombinators.Json.stringify(encodeTelemetryBatch(payload))
    let blob = BrowserBindings.Blob.newBlob([jsonStr], {"type": "application/json"})
    if WebApiBindings.sendBeaconBlob(Constants.backendUrl ++ "/api/telemetry/batch", blob) {
      ignore(%raw(`telemetryQueue.splice(0, telemetryQueue.length)`))
      noteTelemetryPayloadBytes(String.length(jsonStr))
    }
  }
}

let initializeBeforeUnloadListener = () => {
  let _ = Window.addEventListener("beforeunload", (_: Dom.event) => flushWithBeaconOnUnload())
}

let isBrowserRuntime = (): bool => { LoggerTelemetryTransport.isBrowserRuntime() }

let flushTimer = ref(None)
let startPeriodicFlush = () => {
  switch flushTimer.contents {
  | Some(_) => ()
  | None => flushTimer := Some(Window.setInterval(() => {
          scheduleIdleFlush()
        }, Constants.Telemetry.batchInterval))
  }
}

let _ = if isBrowserRuntime() {
  startPeriodicFlush()
  initializeNetworkListener()
  initializeBeforeUnloadListener()
} else {
  ()
}
