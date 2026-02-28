/* src/utils/LoggerTelemetry.res */

open ReBindings
open LoggerCommon

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

let setBypassTestEnvCheck = (v: bool) => {
  bypassTestEnvCheck := v
}

let nowMs = () => Date.now()

let clearSuspensionIfExpired = () => {
  if telemetrySuspendedUntil.contents != 0.0 && nowMs() >= telemetrySuspendedUntil.contents {
    telemetrySuspendedUntil := 0.0
  }
}

let isTelemetrySuspended = () => {
  clearSuspensionIfExpired()
  telemetrySuspendedUntil.contents != 0.0
}

let suspendTelemetry = () =>
  telemetrySuspendedUntil := nowMs() + Constants.Telemetry.suspendDurationMs

let suspendTelemetryForMs = (durationMs: float) => {
  let boundedDurationMs = if durationMs <= 0.0 {
    Constants.Telemetry.suspendDurationMs
  } else {
    durationMs
  }
  telemetrySuspendedUntil := nowMs() + boundedDurationMs
  ignore(%raw(`telemetryQueue.splice(0, telemetryQueue.length)`))
}

let parseRetryAfterHeaderMs = (res: Fetch.response): option<float> => {
  let headers = WebApiBindings.Fetch.headers(res)
  let direct = WebApiBindings.Fetch.getHeader(headers, "retry-after")->Nullable.toOption
  let xRate = WebApiBindings.Fetch.getHeader(headers, "x-ratelimit-after")->Nullable.toOption
  let raw = direct->Option.orElse(xRate)
  raw->Option.flatMap(raw => {
    switch Belt.Int.fromString(raw) {
    | Some(seconds) if seconds > 0 => Some(Belt.Int.toFloat(seconds) *. 1000.0)
    | _ => None
    }
  })
}

let validateTelemetryResponse = async (res: Fetch.response): Promise.t<unit> => {
  let status = WebApiBindings.Fetch.status(res)
  if status == 429 {
    let retryMs = parseRetryAfterHeaderMs(res)->Option.getOr(Constants.Telemetry.suspendDurationMs)
    suspendTelemetryForMs(retryMs)
    Promise.reject(Failure(`TelemetryRateLimited:${Belt.Int.toString(status)}`))
  } else if status >= 400 {
    Promise.reject(Failure(`TelemetryHttpError:${Belt.Int.toString(status)}`))
  } else {
    Promise.resolve()
  }
}

let canUseTelemetryNetwork = () => Constants.Telemetry.enabled && !isTelemetrySuspended()

let noteTelemetryPayloadBytes = (payloadBytes: int) => {
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

type transportTask = {
  task: unit => Promise.t<unit>,
  resolve: unit => unit,
  reject: exn => unit,
}

let transportQueue: array<transportTask> = []
let transportActive = ref(0)
let transportQueueOverflowReason = "TelemetryTransportQueueOverflow"

let rec processTransportQueue = () => {
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
          processTransportQueue()
          Promise.resolve()
        })
        ->Promise.catch(err => {
          transportActive := transportActive.contents - 1
          entry.reject(err)
          processTransportQueue()
          Promise.resolve()
        })
        ->ignore
    | None => ()
    }
  }
}

let scheduleTransport = (task: unit => Promise.t<unit>): Promise.t<unit> =>
  Promise.make((resolve, reject) => {
    if Array.length(transportQueue) >= Constants.Telemetry.transportMaxQueued {
      reject(Failure(transportQueueOverflowReason))
    } else {
      let entry = {task, resolve: _ => resolve(), reject}
      let _ = Array.push(transportQueue, entry)
      processTransportQueue()
    }
  })

let queueFillRatio = () => {
  let maxSize = Constants.Telemetry.queueMaxSize
  if maxSize <= 0 {
    0.0
  } else {
    Belt.Int.toFloat(Array.length(telemetryQueue)) /. Belt.Int.toFloat(maxSize)
  }
}

let shouldSendLowPriority = () => {
  let fill = queueFillRatio()
  if fill >= Constants.Telemetry.lowPriorityDropThreshold {
    false
  } else if fill >= Constants.Telemetry.lowPrioritySamplingThreshold {
    Math.random() < Constants.Telemetry.lowPrioritySamplingRate
  } else {
    true
  }
}

let shouldQueueForPriority = p =>
  switch p {
  | Low => shouldSendLowPriority()
  | _ => true
  }

let sanitizeJson = (_entry: JSON.t, _fields: array<string>): JSON.t =>
  %raw(`(function(_entry, _fields) {
    if (!_entry || typeof _entry !== 'object') {
      return _entry;
    }
    const sanitized = {..._entry};
    for (let idx = 0; idx < _fields.length; idx++) {
      const key = _fields[idx];
      if (Object.prototype.hasOwnProperty.call(sanitized, key)) {
        sanitized[key] = '[REDACTED]';
      }
    }
    return sanitized;
  })(_entry, _fields)`)

let sanitizePayload = (data: option<JSON.t>): option<JSON.t> =>
  data->Option.map(json => sanitizeJson(json, Constants.Telemetry.sensitiveFields))

let encodeLogEntry = (entry: logEntry) => {
  let encode = JsonCombinators.Json.Encode.object
  let float = JsonCombinators.Json.Encode.float
  let string = JsonCombinators.Json.Encode.string
  let option = JsonCombinators.Json.Encode.option
  let id = (v: JSON.t) => v

  encode([
    ("timestampMs", float(entry.timestampMs)),
    ("timestamp", string(entry.timestamp)),
    ("module", string(entry.module_)),
    ("level", string(entry.level)),
    ("message", string(entry.message)),
    ("data", option(id)(entry.data)),
    ("priority", string(entry.priority)),
    ("requestId", option(string)(entry.requestId)),
    ("operationId", option(string)(entry.operationId)),
    ("sessionId", option(string)(entry.sessionId)),
  ])
}

let encodeTelemetryBatch = (batch: telemetryBatch) => {
  let encode = JsonCombinators.Json.Encode.object
  let array = JsonCombinators.Json.Encode.array

  encode([("entries", array(encodeLogEntry)(batch.entries))])
}

let deduplicateBatchEntries = (_entries: array<logEntry>): array<logEntry> =>
  %raw(`(function(_entries) {
    const grouped = new Map();
    for (const entry of _entries) {
      const key = [
        entry.module,
        entry.level,
        entry.message,
        entry.priority,
        entry.requestId || "",
        entry.operationId || "",
        entry.sessionId || "",
        JSON.stringify(entry.data || null)
      ].join("|");
      const current = grouped.get(key);
      if (current) {
        current.__count = (current.__count || 1) + 1;
        if ((entry.timestampMs || 0) > (current.timestampMs || 0)) {
          current.timestampMs = entry.timestampMs;
          current.timestamp = entry.timestamp;
        }
      } else {
        grouped.set(key, {...entry, __count: 1});
      }
    }

    const merged = [];
    for (const item of grouped.values()) {
      const count = item.__count || 1;
      if (count > 1) {
        const baseData = item.data && typeof item.data === "object" && !Array.isArray(item.data)
          ? {...item.data}
          : {};
        baseData.count = count;
        item.data = baseData;
      }
      delete item.__count;
      merged.push(item);
    }
    return merged;
  })(_entries)`)

let isTransportQueueOverflow = err => getErrorMessage(err) == transportQueueOverflowReason

let runIdle = (_task: unit => unit) =>
  %raw(`(function(task){
    if (typeof window !== "undefined" && typeof window.requestIdleCallback === "function") {
      window.requestIdleCallback(() => task(), {timeout: 1500});
    } else {
      setTimeout(task, 0);
    }
  })(_task)`)

let rec attemptSendBatch = async (payload: telemetryBatch, retries: int) => {
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
        await attemptSendBatch(payload, retries + 1)
      }
    | _ => {
        Console.error("[Logger] Failed to send telemetry batch after max retries")
        suspendTelemetry()
        false
      }
    }
  }
}

let rec flushTelemetry = async () => {
  if !NetworkStatus.isOnline() {
    Console.info2("[LoggerTelemetry] FLUSH_SKIPPED_OFFLINE. Queued:", Array.length(telemetryQueue))
  } else if Array.length(telemetryQueue) > 0 && !isFlushing.contents && canUseTelemetryNetwork() {
    isFlushing := true

    let batchLimit = Constants.Telemetry.batchSize
    let currentQueueLen = Array.length(telemetryQueue)
    let takeCount = if currentQueueLen > batchLimit {
      batchLimit
    } else {
      currentQueueLen
    }

    let batch = Belt.Array.slice(telemetryQueue, ~offset=0, ~len=takeCount)->deduplicateBatchEntries
    let payload: telemetryBatch = {entries: batch}

    let beaconSuccess = if WebApiBindings.hasSendBeacon() {
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

    let networkSuccess = if beaconSuccess {
      true
    } else {
      await attemptSendBatch(payload, 0)
    }

    if networkSuccess {
      ignore(%raw(`telemetryQueue.splice(0, takeCount)`))
    } else {
      suspendTelemetry()
    }

    isFlushing := false
  }
}

and scheduleIdleFlush = () => {
  if !idleFlushPending.contents {
    idleFlushPending := true
    runIdle(() => {
      idleFlushPending := false
      let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
    })
  }
}

let shouldSampleByLevel = (level: level): bool => {
  let baseRate = switch level {
  | Warn => 1.0
  | Info | Perf => sampleRateInfo
  | Trace =>
    if Constants.Telemetry.diagnosticMode.contents {
      1.0
    } else {
      0.0
    }
  | Debug =>
    if Constants.isDebugBuild() || Constants.Telemetry.diagnosticMode.contents {
      1.0
    } else {
      sampleRateDebugProd
    }
  | _ => 1.0
  }

  if baseRate >= 1.0 {
    true
  } else if baseRate <= 0.0 {
    false
  } else {
    let effectiveRate = baseRate *. adaptiveSamplingScale.contents
    Math.random() < effectiveRate
  }
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

let isBrowserRuntime = (): bool =>
  %raw(`typeof window !== "undefined" && typeof document !== "undefined"`)

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
