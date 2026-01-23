/**
 * Logger.res - Type-Safe Unified Logging System
 * 
 * Replaces Debug.js and Logger.js with a single, strictly-typed module.
 */
open ReBindings

// =============================================================================
// TYPES
// =============================================================================

type level =
  | Trace
  | Debug
  | Info
  | Warn
  | Error
  | Perf

type priority =
  | Critical
  | High
  | Medium
  | Low

type logEntry = {
  timestampMs: float,
  timestamp: string,
  @as("module") module_: string,
  level: string,
  message: string,
  data: option<JSON.t>,
  priority: string,
}

type telemetryBatch = {entries: array<logEntry>}

type timedResult<'a> = {
  result: 'a,
  durationMs: float,
}

type operationResult<'a> = result<'a, string>

external castToJson: 'a => JSON.t = "%identity"
external asDynamic: 'a => {..} = "%identity"

let optToNullable = (opt: option<'a>): Nullable.t<'a> =>
  switch opt {
  | Some(v) => Nullable.make(v)
  | None => Nullable.null
  }

// =============================================================================
// STATE & CONSTANTS
// =============================================================================

let entries: array<logEntry> = []
let maxEntries = 2000
let appLog: array<string> = []
let maxAppLogEntries = 1000

let telemetryQueue: array<logEntry> = []
let batchTimer = ref(None)

let enabled = ref(Constants.isDebugBuild())
let minLevel = ref(Info)
let enabledModules = ref(Belt.Set.String.empty)

let levelPriority = (level: level): int =>
  switch level {
  | Trace => 0
  | Debug => 1
  | Info => 2
  | Perf => 2
  | Warn => 3
  | Error => 4
  }

let levelToTelemetryPriority = (level: level): priority =>
  switch level {
  | Error => Critical
  | Warn => High
  | Info | Perf => Medium
  | Trace | Debug => Low
  }

let levelToString = (level: level): string =>
  switch level {
  | Trace => "trace"
  | Debug => "debug"
  | Info => "info"
  | Warn => "warn"
  | Error => "error"
  | Perf => "perf"
  }

let priorityToString = (p: priority): string =>
  switch p {
  | Critical => "critical"
  | High => "high"
  | Medium => "medium"
  | Low => "low"
  }

let stringToLevel = (s: string): level =>
  switch s {
  | "trace" => Trace
  | "debug" => Debug
  | "info" => Info
  | "warn" => Warn
  | "error" => Error
  | "perf" => Perf
  | _ => Info
  }

let moduleColors = Dict.fromArray([
  ("Teaser", "#f97316"),
  ("Navigation", "#3b82f6"),
  ("Store", "#10b981"),
  ("Viewer", "#8b5cf6"),
  ("Hotspot", "#ec4899"),
  ("Export", "#14b8a6"),
  ("Default", "#64748b"),
])

// =============================================================================
// VISUAL BADGE
// =============================================================================

let showDebugBadge = () => {
  // Visual debug badge disabled as per user request (Invisible for now)
  ()
}

let hideDebugBadge = () => {
  switch Dom.getElementById("debug-badge")->Nullable.toOption {
  | Some(b) => Dom.removeElement(b)
  | None => ()
  }
}

// =============================================================================
// INTERNAL LOGGING CORE
// =============================================================================

let retryCount = ref(0)
let isFlushing = ref(false)

let flushTelemetry = async () => {
  if Array.length(telemetryQueue) > 0 && !isFlushing.contents {
    isFlushing := true

    // Take a batch from the queue
    let batchLimit = Constants.Telemetry.batchSize
    let currentQueueLen = Array.length(telemetryQueue)
    let takeCount = if currentQueueLen > batchLimit {
      batchLimit
    } else {
      currentQueueLen
    }

    let batch = Belt.Array.slice(telemetryQueue, ~offset=0, ~len=takeCount)
    // Remove from queue
    ignore(%raw(`telemetryQueue.splice(0, takeCount)`))

    let payload: telemetryBatch = {entries: batch}

    let rec attemptSend = async retries => {
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
        isFlushing := false
      } catch {
      | _ if retries < Constants.Telemetry.retryMaxAttempts => {
          let delay = Belt.Float.toInt(
            Belt.Int.toFloat(Constants.Telemetry.retryBackoffMs) *.
            Math.pow(2.0, ~exp=Belt.Int.toFloat(retries)),
          )
          let _ = await Promise.make((resolve, _) => {
            let _ = Window.setTimeout(() => resolve(ignore()), delay)
          })
          await attemptSend(retries + 1)
        }
      | _ => {
          Console.error("[Logger] Failed to send telemetry batch after max retries")
          isFlushing := false
        }
      }
    }

    await attemptSend(0)
  }
}

let sendTelemetry = async entry => {
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
    | JsExn(e) =>
      Console.error(
        `[Logger] Failed to send immediate telemetry: ${e
          ->JsExn.message
          ->Option.getOr("Unknown")}`,
      )
    | _ => Console.error("[Logger] Failed to send immediate telemetry (Unknown error)")
    }
  | Medium =>
    if Array.length(telemetryQueue) < Constants.Telemetry.queueMaxSize {
      let _ = Array.push(telemetryQueue, entry)
    }
    if Array.length(telemetryQueue) >= Constants.Telemetry.batchSize {
      let _ = flushTelemetry()
    }
  | Low => ()
  }
}

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
  let _ = sendTelemetry(entry)

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

// =============================================================================
// PUBLIC API
// =============================================================================

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
  try {Ok(fn())} catch {
  | JsExn(e) => {
      let msg = e->JsExn.message->Option.getOr("Unknown error")
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": msg, "stack": e->JsExn.stack}),
        (),
      )
      Error(msg)
    }
  | _ => {
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": "Unknown exception"}),
        (),
      )
      Error("Unknown exception")
    }
  }
}

let attemptAsync = async (
  ~module_: string,
  ~operation: string,
  fn: unit => promise<'a>,
): operationResult<'a> => {
  try {Ok(await fn())} catch {
  | JsExn(e) => {
      let msg = e->JsExn.message->Option.getOr("Unknown error")
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": msg, "stack": e->JsExn.stack}),
        (),
      )
      Error(msg)
    }
  | _ => {
      error(
        ~module_,
        ~message=`${operation}_FAILED`,
        ~data=castToJson({"error": "Unknown exception"}),
        (),
      )
      Error("Unknown exception")
    }
  }
}

let startOperation = (~module_, ~operation, ~data=?, ()) =>
  info(~module_, ~message=`${operation}_START`, ~data?, ())
let endOperation = (~module_, ~operation, ~data=?, ()) =>
  info(~module_, ~message=`${operation}_COMPLETE`, ~data?, ())
let initialized = (~module_) => info(~module_, ~message=`${module_} initialized`, ())

let setLevel = lvl => {
  minLevel := lvl
  info(~module_="Logger", ~message=`Log level set to ${levelToString(lvl)}`, ())
}

let enable = () => {
  enabled := true
  enabledModules := Belt.Set.String.empty
  showDebugBadge()
  info(~module_="Logger", ~message="Debug mode ENABLED", ())
}

let disable = () => {
  enabled := false
  hideDebugBadge()
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

external asDynamic: 'a => {..} = "%identity"

// =============================================================================
// GLOBAL BINDINGS (INIT)
// =============================================================================

// =============================================================================
// HELPER MODULES (Error Extraction)
// =============================================================================

module JsError = {
  type t
  @get external message: t => string = "message"
  @get external stack: t => Nullable.t<string> = "stack"
  @get external name: t => string = "name"
}

let getErrorDetails = (e: exn): (string, string) => {
  switch JsExn.fromException(e) {
  | Some(jsExn) => (
      JsExn.message(jsExn)->Option.getOr("Unknown JS Error"),
      JsExn.stack(jsExn)->Option.getOr(""),
    )
  | None => ("Non-JS ReScript Error", "")
  }
}

let getErrorMessage = (e: exn): string => {
  let (msg, _) = getErrorDetails(e)
  msg
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

// =============================================================================
// GLOBAL BINDINGS (INIT)
// =============================================================================

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

    // Prevent default logging in production to avoid console noise + double logging
    // But allow in localhost for dev convenience
    if !(Window.window["location"]["hostname"]->String.includes("localhost")) {
      UnhandledRejectionEvent.preventDefault(evt)
    }
  })

  initialized(~module_="Logger")
  if enabled.contents {
    showDebugBadge()
  }

  /* Start Telemetry Batch Timer */
  batchTimer := Some(ReBindings.Window.setInterval(() => {
        let _ = flushTelemetry()
      }, Constants.Telemetry.batchInterval))
}
