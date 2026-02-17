/* src/utils/LoggerTelemetry.res */

open ReBindings
open LoggerCommon

let telemetryQueue: array<logEntry> = []
let isFlushing = ref(false)
let bypassTestEnvCheck = ref(false)
let telemetrySuspendedUntil = ref(0.0)

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

let canUseTelemetryNetwork = () => Constants.Telemetry.enabled && !isTelemetrySuspended()

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

let isTransportQueueOverflow = err => getErrorMessage(err) == transportQueueOverflowReason

let rec attemptSendBatch = async (payload: telemetryBatch, retries: int) => {
  if !canUseTelemetryNetwork() {
    false
  } else {
    try {
      let _ = await scheduleTransport(() =>
        Fetch.fetch(
          Constants.backendUrl ++ "/api/telemetry/batch",
          Fetch.requestInit(
            ~method="POST",
            ~headers=Dict.fromArray([("Content-Type", "application/json")]),
            ~body=JsonCombinators.Json.stringify(encodeTelemetryBatch(payload)),
            (),
          ),
        )->Promise.then(_ => Promise.resolve())
      )
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

let flushTelemetry = async () => {
  if !NetworkStatus.isOnline() {
    Console.info2(
      "[LoggerTelemetry] FLUSH_SKIPPED_OFFLINE. Queued:",
      Array.length(telemetryQueue),
    )
    // Don't reset the timer, just skip this flush cycle
  } else if Array.length(telemetryQueue) > 0 && !isFlushing.contents && canUseTelemetryNetwork() {
    isFlushing := true

    let batchLimit = Constants.Telemetry.batchSize
    let currentQueueLen = Array.length(telemetryQueue)
    let takeCount = if currentQueueLen > batchLimit {
      batchLimit
    } else {
      currentQueueLen
    }

    let batch = Belt.Array.slice(telemetryQueue, ~offset=0, ~len=takeCount)
    let payload: telemetryBatch = {entries: batch}

    let beaconSuccess = if WebApiBindings.hasSendBeacon() {
      let jsonStr = JsonCombinators.Json.stringify(encodeTelemetryBatch(payload))
      // Use Blob to enforce application/json content type
      let blob = BrowserBindings.Blob.newBlob([jsonStr], {"type": "application/json"})
      WebApiBindings.sendBeaconBlob(Constants.backendUrl ++ "/api/telemetry/batch", blob)
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

let sendTelemetry = async entry => {
  if !canUseTelemetryNetwork() {
    ()
  } else if Constants.isTestEnvironment() && !bypassTestEnvCheck.contents {
    ()
  } else {
    let sanitizedEntry = {...entry, data: sanitizePayload(entry.data)}
    let p = stringToLevel(sanitizedEntry.level)->levelToTelemetryPriority

    switch p {
    | Critical =>
      try {
        let _ = await scheduleTransport(() =>
          Fetch.fetch(
            Constants.backendUrl ++ "/api/telemetry/error",
            Fetch.requestInit(
              ~method="POST",
              ~headers=Dict.fromArray([("Content-Type", "application/json")]),
              ~body=JsonCombinators.Json.stringify(encodeLogEntry(sanitizedEntry)),
              (),
            ),
          )->Promise.then(_ => Promise.resolve())
        )
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
      if shouldQueue {
        if Array.length(telemetryQueue) < Constants.Telemetry.queueMaxSize {
          let _ = Array.push(telemetryQueue, sanitizedEntry)
          if Array.length(telemetryQueue) >= Constants.Telemetry.batchSize {
            let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
          }
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
      let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
    }
  })
}

// Periodic flush every 2 seconds
let flushTimer = ref(None)
let startPeriodicFlush = () => {
  switch flushTimer.contents {
  | Some(_) => ()
  | None => flushTimer := Some(Window.setInterval(() => {
          let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
        }, 2000))
  }
}
let _ = startPeriodicFlush()
let _ = initializeNetworkListener()
