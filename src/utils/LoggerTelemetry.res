/* src/utils/LoggerTelemetry.res */

open ReBindings
open LoggerCommon

let telemetryQueue: array<logEntry> = []
let isFlushing = ref(false)
let bypassTestEnvCheck = ref(false)

let setBypassTestEnvCheck = (v: bool) => {
  bypassTestEnvCheck := v
}

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
  ])
}

let encodeTelemetryBatch = (batch: telemetryBatch) => {
  let encode = JsonCombinators.Json.Encode.object
  let array = JsonCombinators.Json.Encode.array

  encode([("entries", array(encodeLogEntry)(batch.entries))])
}

let rec attemptSendBatch = async (payload: telemetryBatch, retries: int) => {
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
      false
    }
  }
}

let flushTelemetry = async () => {
  if Array.length(telemetryQueue) > 0 && !isFlushing.contents {
    isFlushing := true

    let batchLimit = Constants.Telemetry.batchSize
    let currentQueueLen = Array.length(telemetryQueue)
    let takeCount = if currentQueueLen > batchLimit {
      batchLimit
    } else {
      currentQueueLen
    }

    let batch = Belt.Array.slice(telemetryQueue, ~offset=0, ~len=takeCount)
    ignore(%raw(`telemetryQueue.splice(0, takeCount)`))

    let payload: telemetryBatch = {entries: batch}
    let _ = await attemptSendBatch(payload, 0)
    isFlushing := false
  }
}

let sendTelemetry = async entry => {
  if Constants.isTestEnvironment() && !bypassTestEnvCheck.contents {
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
      | e => Console.error(`[Logger] Failed to send immediate telemetry: ${getErrorMessage(e)}`)
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
