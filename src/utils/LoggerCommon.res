/* src/utils/LoggerCommon.res */

external castToJson: 'a => JSON.t = "%identity"
external asDynamic: 'a => {..} = "%identity"
external castToUnknown: 'a => unknown = "%identity"

// --- Types ---

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
  requestId: option<string>,
  operationId: option<string>,
  sessionId: option<string>,
}

type telemetryBatch = {entries: array<logEntry>}

type timedResult<'a> = {
  result: 'a,
  durationMs: float,
}

type operationResult<'a> = result<'a, string>

let optToNullable = (opt: option<'a>): Nullable.t<'a> =>
  switch opt {
  | Some(v) => Nullable.make(v)
  | None => Nullable.null
  }

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

let levelMap = Dict.fromArray([
  ("trace", Trace),
  ("debug", Debug),
  ("info", Info),
  ("warn", Warn),
  ("error", Error),
  ("perf", Perf),
])

let stringToLevel = (s: string): level => {
  Dict.get(levelMap, s)->Option.getOr(Info)
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

module JsError = {
  type t
  @get external message: t => string = "message"
  @get external stack: t => Nullable.t<string> = "stack"
  @get external name: t => string = "name"
}

// Improved Error Details: Use %raw to stringify non-JS Error exceptions
let getErrorDetails = (e: exn): (string, string) => {
  switch JsExn.fromException(e) {
  | Some(jsExn) => (
      JsExn.message(jsExn)->Option.getOr("Unknown JS Error"),
      JsExn.stack(jsExn)->Option.getOr(""),
    )
  | None =>
    let rawStr = try {
      %raw(`String(e)`)
    } catch {
    | _ => "Unknown Error"
    }
    (rawStr, "")
  }
}

let getErrorMessage = (e: exn): string => {
  let (msg, _) = getErrorDetails(e)
  msg
}
