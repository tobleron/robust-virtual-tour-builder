/* src/utils/LoggerLogic.res */

open! LoggerTypes
open LoggerTelemetry

let entries: array<logEntry> = []
let maxEntries = 2000
let appLog: array<string> = []
let maxAppLogEntries = 1000

let enabled = ref(Constants.isDebugBuild())
let minLevel = ref(Info)
let enabledModules = ref(Belt.Set.String.empty)

let log = (~module_: string, ~level: level, ~message: string, ~data: 'a=?, ()): unit => {
  let timestampMs = Date.now()
  let timestamp = Date.toISOString(Date.make())
  let p = levelToTelemetryPriority(level)

  let entry = {
    timestampMs,
    timestamp,
    module_,
    level: levelToString(level),
    message,
    data: data->Option.map(castToJson),
    priority: priorityToString(p),
  }

  Array.push(entries, entry)
  if Array.length(entries) > maxEntries {
    let _ = Array.shift(entries)
  }

  /* App Log Buffer (for UI) */
  let appLogMsg = `[${timestamp}][${levelToString(
      level,
    )->String.toUpperCase}] [${module_}] ${message}`
  Array.push(appLog, appLogMsg)
  if Array.length(appLog) > maxAppLogEntries {
    let _ = Array.shift(appLog)
  }

  /* Backend Telemetry */
  let _ = sendTelemetry(entry)->Promise.catch(_ => Promise.resolve())

  /* Console Output */
  if enabled.contents && levelPriority(level) >= levelPriority(minLevel.contents) {
    let hasFilter = Belt.Set.String.size(enabledModules.contents) > 0
    if !hasFilter || Belt.Set.String.has(enabledModules.contents, module_) {
      let color =
        Dict.get(moduleColors, module_)->Option.getOr(
          Dict.get(moduleColors, "Default")->Option.getOr("#64748b"),
        )
      let prefix = `%c[${module_}]%c`
      let prefixStyle = `color: ${color}; font-weight: bold;`
      let resetStyle = "color: inherit;"

      let consoleMethod = switch level {
      | Trace | Debug | Perf => "log"
      | Info => "info"
      | Warn => "warn"
      | Error => "error"
      }

      let callConsole: (string, string, string, string, string, Nullable.t<JSON.t>) => unit = %raw(`
        function(method, p1, p2, p3, msg, data) {
          if (data !== null && data !== undefined) {
            console[method](p1, p2, p3, msg, data);
          } else {
            console[method](p1, p2, p3, msg);
          }
        }
      `)

      callConsole(
        consoleMethod,
        prefix,
        prefixStyle,
        resetStyle,
        message,
        data->Option.map(castToJson)->optToNullable,
      )
    }
  }
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
