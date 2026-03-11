/* src/utils/LoggerLogic.res */
// @efficiency-role: service-orchestrator

open ReBindings
open LoggerCommon

type runtimeContext = {
  entries: array<logEntry>,
  maxEntries: int,
  appLog: array<string>,
  maxAppLogEntries: int,
  currentOperationId: option<string>,
  currentSessionId: option<string>,
  sendTelemetryFn: logEntry => Promise.t<unit>,
  logToConsoleFn: (string, level, string, option<JSON.t>) => unit,
}

let createLogEntry = (
  ~currentOperationId: option<string>,
  ~currentSessionId: option<string>,
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
    requestId: None,
    operationId: currentOperationId,
    sessionId: currentSessionId,
  }
}

let updateLogBuffers = (
  ~entries: array<logEntry>,
  ~maxEntries: int,
  ~appLog: array<string>,
  ~maxAppLogEntries: int,
  entry: logEntry,
  level: level,
  module_: string,
  message: string,
) => {
  Array.push(entries, entry)
  if Array.length(entries) > maxEntries {
    let _ = Array.shift(entries)
  }

  let appLogMsg = `[${entry.timestamp}][${levelToString(
      level,
    )->String.toUpperCase}] [${module_}] ${message}`
  Array.push(appLog, appLogMsg)
  if Array.length(appLog) > maxAppLogEntries {
    let _ = Array.shift(appLog)
  }
}

let log = (
  ~ctx: runtimeContext,
  ~module_: string,
  ~level: level,
  ~message: string,
  ~data: 'a=?,
  (),
): unit => {
  let jsonParams = data->Option.map(castToJson)
  let entry = createLogEntry(
    ~currentOperationId=ctx.currentOperationId,
    ~currentSessionId=ctx.currentSessionId,
    ~module_,
    ~level,
    ~message,
    ~data=jsonParams,
  )

  updateLogBuffers(
    ~entries=ctx.entries,
    ~maxEntries=ctx.maxEntries,
    ~appLog=ctx.appLog,
    ~maxAppLogEntries=ctx.maxAppLogEntries,
    entry,
    level,
    module_,
    message,
  )

  let _ = ctx.sendTelemetryFn(entry)->Promise.catch(_ => Promise.resolve())
  ctx.logToConsoleFn(module_, level, message, jsonParams)
}

let logWithAppError = (
  ~emitLog: (string, level, string, option<JSON.t>) => unit,
  ~module_: string,
  ~level: level,
  ~message: string,
  ~appError: SharedTypes.appError,
  ~operationContext: option<string>=?,
  ~data: option<JSON.t>=?,
  (),
) => {
  let payload = JsonCombinators.Json.Encode.object([
    ("error_type", JsonCombinators.Json.Encode.string(SharedTypes.appErrorType(appError))),
    ("error_message", JsonCombinators.Json.Encode.string(SharedTypes.appErrorMessage(appError))),
    ("retryable", JsonCombinators.Json.Encode.bool(SharedTypes.appErrorRetryable(appError))),
    (
      "error_code",
      switch SharedTypes.appErrorCode(appError) {
      | Some(code) => JsonCombinators.Json.Encode.string(code)
      | None => JsonCombinators.Json.Encode.null
      },
    ),
    (
      "operation_context",
      switch operationContext {
      | Some(ctx) => JsonCombinators.Json.Encode.string(ctx)
      | None => JsonCombinators.Json.Encode.null
      },
    ),
    (
      "extra",
      switch data {
      | Some(v) => v
      | None => JsonCombinators.Json.Encode.null
      },
    ),
  ])

  emitLog(module_, level, message, Some(payload))
}

let getPerfThreshold = (durationMs: float) => {
  LoggerPerf.getPerfThreshold(durationMs)
}

let getPerfEmoji = (durationMs: float) => {
  LoggerPerf.getPerfEmoji(durationMs)
}

let getPerfLevel = (durationMs: float) => {
  LoggerPerf.getPerfLevel(durationMs)
}

let enrichPerfData = (data: option<'a>, durationMs: float, threshold: string): JSON.t =>
  LoggerPerf.enrichPerfData(data, durationMs, threshold)

let perf = (
  ~emitLog: (string, level, string, option<JSON.t>) => unit,
  ~module_: string,
  ~message: string,
  ~durationMs: float,
  ~data: 'a=?,
  (),
) => LoggerPerf.perf(~emitLog, ~module_, ~message, ~durationMs, ~data?, ())

let timed = (
  ~perfFn: (string, string, float) => unit,
  ~module_: string,
  ~operation: string,
  fn: unit => 'a,
): timedResult<'a> => LoggerPerf.timed(~perfFn, ~module_, ~operation, fn)

let timedAsync = async (
  ~perfFn: (string, string, float) => unit,
  ~module_: string,
  ~operation: string,
  fn: unit => promise<'a>,
): timedResult<'a> => await LoggerPerf.timedAsync(~perfFn, ~module_, ~operation, fn)

let attempt = (
  ~emitError: (string, string, JSON.t) => unit,
  ~module_: string,
  ~operation: string,
  fn: unit => 'a,
): operationResult<'a> => {
  try {
    let res = fn()
    Belt.Result.Ok(res)
  } catch {
  | e => {
      let (msg, stack) = getErrorDetails(e)
      emitError(module_, `${operation}_FAILED`, castToJson({"error": msg, "stack": stack}))
      Belt.Result.Error(msg)
    }
  }
}

let attemptAsync = async (
  ~emitError: (string, string, JSON.t) => unit,
  ~module_: string,
  ~operation: string,
  fn: unit => promise<'a>,
): operationResult<'a> => {
  try {
    let res = await fn()
    Belt.Result.Ok(res)
  } catch {
  | e => {
      let (msg, stack) = getErrorDetails(e)
      emitError(module_, `${operation}_FAILED`, castToJson({"error": msg, "stack": stack}))
      Belt.Result.Error(msg)
    }
  }
}

let logResult = (
  ~emitDebug: (string, string) => unit,
  ~emitError: (string, string, JSON.t) => unit,
  ~module_: string,
  ~message: string,
  result: Belt.Result.t<'a, 'e>,
  ~verbose=false,
) => {
  switch result {
  | Ok(_) =>
    if verbose {
      emitDebug(module_, `${message}_SUCCESS`)
    }
  | Error(_e) =>
    let errStr = try {
      %raw(`String(_e)`)
    } catch {
    | _ => "Unknown Error"
    }
    emitError(module_, `${message}_FAILED`, castToJson({"error": errStr}))
  }
}

let ensureSessionId = (sessionId: ref<option<string>>) => {
  if sessionId.contents == None {
    sessionId :=
      Some(
        try {
          Crypto.randomUUID()
        } catch {
        | _ => "sess_" ++ Float.toString(Date.now())
        },
      )
  }
}

let setLevel = (
  ~minLevel: ref<level>,
  ~emitInfo: (string, string, option<JSON.t>) => unit,
  lvl: level,
) => {
  minLevel := lvl
  emitInfo("Logger", `Log level set to ${levelToString(lvl)}`, None)
}

let enable = (
  ~enabled: ref<bool>,
  ~enabledModules: ref<Belt.Set.String.t>,
  ~emitInfo: (string, string, option<JSON.t>) => unit,
) => {
  enabled := true
  enabledModules := Belt.Set.String.empty
  emitInfo("Logger", "Debug mode ENABLED", None)
}

let enableDiagnostics = (~emitInfo: (string, string, option<JSON.t>) => unit) => {
  Constants.Telemetry.diagnosticMode := true
  emitInfo("Logger", "Diagnostic Mode ENABLED (All logs sent to server)", None)
}

let disableDiagnostics = (~emitInfo: (string, string, option<JSON.t>) => unit) => {
  Constants.Telemetry.diagnosticMode := false
  emitInfo("Logger", "Diagnostic Mode DISABLED", None)
}

let disable = (~enabled: ref<bool>, ~emitInfo: (string, string, option<JSON.t>) => unit) => {
  enabled := false
  emitInfo("Logger", "Debug mode DISABLED", None)
}

let toggle = (~enabled: ref<bool>, ~enableFn: unit => unit, ~disableFn: unit => unit): bool => {
  if enabled.contents {
    disableFn()
  } else {
    enableFn()
  }
  enabled.contents
}

let buildDebugObject = (
  ~enable: unit => unit,
  ~disable: unit => unit,
  ~toggle: unit => bool,
  ~setLevelFromString: string => unit,
  ~getLog: unit => array<logEntry>,
  ~clearEntries: unit => unit,
  ~enableDiagnostics: unit => unit,
  ~disableDiagnostics: unit => unit,
  ~raiseTestError: unit => unit,
) =>
  LoggerDiagnostics.buildDebugObject(
    ~enable,
    ~disable,
    ~toggle,
    ~setLevelFromString,
    ~getLog,
    ~clearEntries,
    ~enableDiagnostics,
    ~disableDiagnostics,
    ~raiseTestError,
  )

let installLongTaskObserver = () => {
  LoggerDiagnostics.installLongTaskObserver()
}

let bindGlobalErrorHandler = (
  ~extractStack: 'errObj => string,
  ~emitError: (string, string, option<JSON.t>) => unit,
) => LoggerDiagnostics.bindGlobalErrorHandler(~extractStack, ~emitError)

let bindUnhandledRejectionHandler = (
  ~toUnhandledEvent: 'eventLike => 'event,
  ~getReasonDetails: 'event => (string, string),
  ~preventDefaultIfNeeded: 'event => unit,
  ~emitError: (string, string, option<JSON.t>) => unit,
) =>
  LoggerDiagnostics.bindUnhandledRejectionHandler(
    ~toUnhandledEvent,
    ~getReasonDetails,
    ~preventDefaultIfNeeded,
    ~emitError,
  )

let installLongTaskListener = (~debugFn: (string, string, option<JSON.t>) => unit) =>
  LoggerDiagnostics.installLongTaskListener(~debugFn)

let subscribeEventBusLogging = (
  ~debugFn: (string, string, option<JSON.t>) => unit,
  ~warnFn: (string, string, option<JSON.t>) => unit,
  ~errorFn: (string, string, option<JSON.t>) => unit,
) => LoggerDiagnostics.subscribeEventBusLogging(~debugFn, ~warnFn, ~errorFn)

let startBatchTimer = (~batchTimer: ref<option<int>>, ~flushTelemetry: unit => Promise.t<unit>) =>
  LoggerDiagnostics.startBatchTimer(~batchTimer, ~flushTelemetry)
