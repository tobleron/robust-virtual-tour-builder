/* src/utils/LoggerTelemetry.res */

open ReBindings
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
          ~body=JSON.stringify(castToJson(payload)),
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
    | Critical | High =>
      let endpoint = if p == Critical {
        "/api/telemetry/error"
      } else {
        "/api/telemetry/log"
      }
      try {
        let _ = await RequestQueue.schedule(() =>
          Fetch.fetch(
            Constants.backendUrl ++ endpoint,
            Fetch.requestInit(
              ~method="POST",
              ~headers=Dict.fromArray([("Content-Type", "application/json")]),
              ~body=JSON.stringify(castToJson(entry)),
              (),
            ),
          )
        )
      } catch {
      | e => Console.error(`[Logger] Failed to send immediate telemetry: ${getErrorMessage(e)}`)
      }
    | Medium =>
      if Array.length(telemetryQueue) < Constants.Telemetry.queueMaxSize {
        let _ = Array.push(telemetryQueue, entry)
      }
      if Array.length(telemetryQueue) >= Constants.Telemetry.batchSize {
        let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
      }
    | Low => ()
    }
  }
}
