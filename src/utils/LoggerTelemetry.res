/* src/utils/LoggerTelemetry.res */

open ReBindings
open RescriptSchema
open LoggerCommon

let telemetryQueue: array<logEntry> = []
let isFlushing = ref(false)
let bypassTestEnvCheck = ref(false)

let setBypassTestEnvCheck = (v: bool) => {
  bypassTestEnvCheck := v
}

let rec attemptSendBatch = async (payload: telemetryBatch, retries: int) => {
  try {
    let _ = await RequestQueue.schedule(() =>
      Fetch.fetch(
        Constants.backendUrl ++ "/api/telemetry/batch",
        Fetch.requestInit(
          ~method="POST",
          ~headers=Dict.fromArray([("Content-Type", "application/json")]),
          ~body=S.reverseConvertToJsonStringOrThrow(payload, telemetryBatchSchema),
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
    // Critical: Send immediately to Error endpoint (triggers Error Log)
    | Critical =>
      try {
        let _ = await RequestQueue.schedule(() =>
          Fetch.fetch(
            Constants.backendUrl ++ "/api/telemetry/error",
            Fetch.requestInit(
              ~method="POST",
              ~headers=Dict.fromArray([("Content-Type", "application/json")]),
              ~body=S.reverseConvertToJsonStringOrThrow(entry, logEntrySchema),
              (),
            ),
          )
        )
      } catch {
      | e => Console.error(`[Logger] Failed to send immediate telemetry: ${getErrorMessage(e)}`)
      }

    // High/Medium: Standard Logs (Warn/Info) - Send to Log endpoint (Diagnostic Log)
    // Low: Debug/Trace - Only if Diagnostic Mode is ON or filtered
    | High | Medium | Low =>
      let shouldSend = if p == High || p == Medium {
        true
      } else if Constants.Telemetry.diagnosticMode.contents {
        true
      } else {
        // Micro-management: Allow specific modules even when diagnostic mode is OFF
        let filters = Constants.Telemetry.traceFilterModules
        let moduleName = entry.module_
        if Array.length(filters) == 0 {
          false
        } else {
          filters->Array.includes(moduleName) || filters->Array.includes("*")
        }
      }

      if shouldSend {
        // If Diagnostic Mode is ON, we send immediately for a "Live" experience.
        // Otherwise, we batch to save resources.
        if Constants.Telemetry.diagnosticMode.contents {
          // Reuse the immediate send logic but at info level (sent to /api/telemetry/log)
          try {
            let _ = await RequestQueue.schedule(() =>
              Fetch.fetch(
                Constants.backendUrl ++ "/api/telemetry/log",
                Fetch.requestInit(
                  ~method="POST",
                  ~headers=Dict.fromArray([("Content-Type", "application/json")]),
                  ~body=S.reverseConvertToJsonStringOrThrow(entry, logEntrySchema),
                  (),
                ),
              )
            )
          } catch {
          | _ => () // Fail silently to avoid interrupting the app
          }
        } else {
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
}
