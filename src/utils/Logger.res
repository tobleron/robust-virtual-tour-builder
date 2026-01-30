/* src/utils/Logger.res */

open ReBindings

/* Include shared types and helpers */
include LoggerCommon

// --- Telemetry & Console ---

/*
   Orchestrate sub-modules:
   - LoggerCommon: Shared types/utils
   - LoggerTelemetry: Backend logging
   - LoggerConsole: Frontend/Console logging
*/

/* Re-export state for compatibility and tests */
let telemetryQueue = LoggerTelemetry.telemetryQueue
let isFlushing = LoggerTelemetry.isFlushing
let setBypassTestEnvCheck = LoggerTelemetry.setBypassTestEnvCheck
let flushTelemetry = LoggerTelemetry.flushTelemetry
let sendTelemetry = LoggerTelemetry.sendTelemetry

let enabled = LoggerConsole.enabled
let minLevel = LoggerConsole.minLevel
let enabledModules = LoggerConsole.enabledModules
let logToConsole = LoggerConsole.logToConsole

let entries: array<logEntry> = []
let maxEntries = 2000
let appLog: array<string> = []
let maxAppLogEntries = 1000

let createLogEntry = (
  ~module_: string,
  ~level: level,
  ~message: string,
  ~data: option<JSON.t>,
): logEntry => {
  let timestampMs = Date.now()
  let timestamp = Date.toISOString(Date.make())
  let p = levelToTelemetryPriority(level)
  {
    timestampMs,
    timestamp,
    module_,
    level: levelToString(level),
    message,
    data,
    priority: priorityToString(p),
  }
}

let updateLogBuffers = (entry: logEntry, level: level, module_: string, message: string) => {
  Array.push(entries, entry)
  if Array.length(entries) > maxEntries {
    let _ = Array.shift(entries)
  }

  /* App Log Buffer (for UI) */
  let appLogMsg = `[${entry.timestamp}][${levelToString(
      level,
    )->String.toUpperCase}] [${module_}] ${message}`
  Array.push(appLog, appLogMsg)
  if Array.length(appLog) > maxAppLogEntries {
    let _ = Array.shift(appLog)
  }
}

let log = (~module_: string, ~level: level, ~message: string, ~data: 'a=?, ()): unit => {
  let jsonParams = data->Option.map(castToJson)
  let entry = createLogEntry(~module_, ~level, ~message, ~data=jsonParams)

  updateLogBuffers(entry, level, module_, message)

  /* Backend Telemetry */
  let _ = sendTelemetry(entry)->Promise.catch(_ => Promise.resolve())

  /* Console Output */
  logToConsole(~module_, ~level, ~message, ~data=jsonParams)
}

let trace = (~module_, ~message, ~data: 'a=?, ()) =>
  log(~module_, ~level=Trace, ~message, ~data?, ())
let debug = (~module_, ~message, ~data: 'a=?, ()) =>
  log(~module_, ~level=Debug, ~message, ~data?, ())
let info = (~module_, ~message, ~data: 'a=?, ()) => log(~module_, ~level=Info, ~message, ~data?, ())
let warn = (~module_, ~message, ~data: 'a=?, ()) => log(~module_, ~level=Warn, ~message, ~data?, ())
let error = (~module_, ~message, ~data: 'a=?, ()) =>
  log(~module_, ~level=Error, ~message, ~data?, ())

let perf = (~module_, ~message, ~durationMs, ~data: 'a=?, ()) => {
  let threshold = if durationMs > 500.0 {
    "VERY_SLOW"
  } else if durationMs > 100.0 {
    "SLOW"
  } else {
    "OK"
  }
  let emoji = if durationMs > 500.0 {
    "🐢"
  } else if durationMs > 100.0 {
    "⏱️"
  } else {
    "⚡"
  }
  let level = if durationMs > 500.0 {
    Warn
  } else if durationMs > 100.0 {
    Info
  } else {
    Debug
  }

  let pd = switch data {
  | Some(d) =>
    let obj = Object.assign(Object.make(), asDynamic(d))
    asDynamic(obj)
  | None => asDynamic(Object.make())
  }
  pd["durationMs"] = durationMs
  pd["threshold"] = threshold

  log(
    ~module_,
    ~level,
    ~message=`${emoji} ${message} (${Float.toFixed(durationMs, ~digits=2)}ms)`,
    ~data=?Some(castToJson(pd)),
    (),
  )
}

let timed = (~module_: string, ~operation: string, fn: unit => 'a): timedResult<'a> => {
  let start = Date.now()
  let result = fn()
  let durationMs = Date.now() -. start
  perf(~module_, ~message=operation, ~durationMs, ())
  {result, durationMs}
}

let timedAsync = async (~module_: string, ~operation: string, fn: unit => promise<'a>): timedResult<
  'a,
> => {
  let start = Date.now()
  let result = await fn()
  let durationMs = Date.now() -. start
  perf(~module_, ~message=operation, ~durationMs, ())
  {result, durationMs}
}

let attempt = (~module_: string, ~operation: string, fn: unit => 'a): operationResult<'a> => {
  try {
    let res = fn()
    Belt.Result.Ok(res)
  } catch {
  | JsExn(e) => {
      let msg = e->JsExn.message->Option.getOr("Unknown error")
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": msg, "stack": e->JsExn.stack}),
        (),
      )
      Belt.Result.Error(msg)
    }
  | _ => {
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": "Unknown exception"}),
        (),
      )
      Belt.Result.Error("Unknown exception")
    }
  }
}

let attemptAsync = async (
  ~module_: string,
  ~operation: string,
  fn: unit => promise<'a>,
): operationResult<'a> => {
  try {
    let res = await fn()
    Belt.Result.Ok(res)
  } catch {
  | JsExn(e) => {
      let msg = e->JsExn.message->Option.getOr("Unknown error")
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": msg, "stack": e->JsExn.stack}),
        (),
      )
      Belt.Result.Error(msg)
    }
  | _ => {
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": "Unknown exception"}),
        (),
      )
      Belt.Result.Error("Unknown exception")
    }
  }
}

let startOperation = (~module_, ~operation, ~data=?, ()) =>
  info(~module_, ~message=`${operation}_START`, ~data?, ())
let endOperation = (~module_, ~operation, ~data=?, ()) =>
  info(~module_, ~message=`${operation}_COMPLETE`, ~data?, ())
let initialized = (~module_) => info(~module_, ~message=`${module_} initialized`, ())

// --- Facade & Init ---

let setLevel = lvl => {
  minLevel := lvl
  info(~module_="Logger", ~message=`Log level set to ${levelToString(lvl)}`, ())
}

let enable = () => {
  enabled := true
  enabledModules := Belt.Set.String.empty
  info(~module_="Logger", ~message="Debug mode ENABLED", ())
}

let disable = () => {
  enabled := false
  info(~module_="Logger", ~message="Debug mode DISABLED", ())
}

let toggle = () => {
  if enabled.contents {
    disable()
  } else {
    enable()
  }
  enabled.contents
}

module UnhandledRejectionEvent = {
  type t
  type reason
  @get external getReason: t => reason = "reason"
  @get external getPromise: t => Promise.t<'a> = "promise"
  @send external preventDefault: t => unit = "preventDefault"

  external reasonToError: reason => JsError.t = "%identity"
  external reasonToString: reason => string = "%identity"
  let isError: reason => bool = %raw(`function(r) { return r instanceof Error }`)
}

external toNullable: 'a => Nullable.t<'a> = "%identity"
external toUnhandledEvent: 'a => UnhandledRejectionEvent.t = "%identity"

let batchTimer = ref(None)

let init = () => {
  /* Expose to Window */
  let debugObj = {
    "enable": enable,
    "disable": disable,
    "toggle": toggle,
    "setLevel": s => setLevel(stringToLevel(s)),
    "getLog": () => entries,
    "clear": () => {%raw(`entries.length = 0`)},
    "isEnabled": () => enabled.contents,
    "testError": () => {
      ignore(%raw(`(function(){ throw new Error("Test Error from Console") })()`))
    },
  }
  Window.setDebug(Window.window, asDynamic(debugObj))
  Window.setAppLog(Window.window, appLog)

  /* Intercept Global Errors with Stack Traces */
  Window.setOnError(Window.window, (msg, source, line, col, errObj) => {
    let stack = switch toNullable(errObj)->Nullable.toOption {
    | Some(e) => e["stack"]
    | None => ""
    }

    error(
      ~module_="Global",
      ~message="UNCAUGHT_ERROR",
      ~data=castToJson({
        "message": msg,
        "source": source,
        "line": line,
        "col": col,
        "stack": stack,
      }),
      (),
    )
    false
  })

  Window.setOnUnhandledRejection(Window.window, event => {
    let evt = toUnhandledEvent(event)
    let reason = UnhandledRejectionEvent.getReason(evt)
    let isError = UnhandledRejectionEvent.isError(reason)

    let reasonStr = isError
      ? JsError.message(UnhandledRejectionEvent.reasonToError(reason))
      : UnhandledRejectionEvent.reasonToString(reason)

    let stack = isError
      ? JsError.stack(UnhandledRejectionEvent.reasonToError(reason))
        ->Nullable.toOption
        ->Option.getOr("")
      : ""

    error(
      ~module_="Global",
      ~message="UNHANDLED_REJECTION",
      ~data=castToJson({
        "reason": reasonStr,
        "stack": stack,
      }),
      (),
    )

    if !(Window.window["location"]["hostname"]->String.includes("localhost")) {
      UnhandledRejectionEvent.preventDefault(evt)
    }
  })

  initialized(~module_="Logger")

  /* Start Telemetry Batch Timer */
  batchTimer := Some(Window.setInterval(() => {
        let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
      }, Constants.Telemetry.batchInterval))
}
