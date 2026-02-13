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

let rec attemptSendBatch = async (payload: telemetryBatch, retries: int) => {
  if !canUseTelemetryNetwork() {
    false
  } else {
    try {
      let _ = await RequestQueue.schedule(() =>
        Fetch.fetch(
          Constants.backendUrl ++ "/api/telemetry/batch",
          Fetch.requestInit(
            ~method="POST",
            ~headers=Dict.fromArray([("Content-Type", "application/json")]),
            ~body=JsonCombinators.Json.stringify(encodeTelemetryBatch(payload)),
            (),
          ),
        )
      )
      true
    } catch {
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
  if Array.length(telemetryQueue) > 0 && !isFlushing.contents && canUseTelemetryNetwork() {
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
    let p = stringToLevel(entry.level)->levelToTelemetryPriority
    switch p {
    | Critical =>
      try {
        let _ = await RequestQueue.schedule(() =>
          Fetch.fetch(
            Constants.backendUrl ++ "/api/telemetry/error",
            Fetch.requestInit(
              ~method="POST",
              ~headers=Dict.fromArray([("Content-Type", "application/json")]),
              ~body=JsonCombinators.Json.stringify(encodeLogEntry(entry)),
              (),
            ),
          )
        )
      } catch {
      | e =>
        Console.error(`[Logger] Failed to send immediate telemetry: ${getErrorMessage(e)}`)
        suspendTelemetry()
      }

    | High | Medium | Low =>
      let shouldSend = if p == High || p == Medium {
        true
      } else if Constants.Telemetry.diagnosticMode.contents {
        true
      } else {
        let filters = Constants.Telemetry.traceFilterModules
        let moduleName = entry.module_
        if Array.length(filters) == 0 {
          false
        } else {
          filters->Array.includes(moduleName) || filters->Array.includes("*")
        }
      }

      if shouldSend {
        if Array.length(telemetryQueue) < Constants.Telemetry.queueMaxSize {
          let _ = Array.push(telemetryQueue, entry)
        }
        if Array.length(telemetryQueue) >= Constants.Telemetry.batchSize {
          let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
        }
      }
    }
  }
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
