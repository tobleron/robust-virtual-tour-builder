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

let sessionId = ref(None)
let currentOperationId = ref(None)

let setOperationId = id => currentOperationId := id
let getOperationId = () => currentOperationId.contents
let getSessionId = () => sessionId.contents

let runtimeContext = (): LoggerLogic.runtimeContext => {
  entries,
  maxEntries,
  appLog,
  maxAppLogEntries,
  currentOperationId: currentOperationId.contents,
  currentSessionId: sessionId.contents,
  sendTelemetryFn: sendTelemetry,
  logToConsoleFn: (module_, level, message, data) => logToConsole(~module_, ~level, ~message, ~data),
}

let createLogEntry = (~module_: string, ~level: level, ~message: string, ~data: option<JSON.t>): logEntry =>
  LoggerLogic.createLogEntry(~currentOperationId=currentOperationId.contents, ~currentSessionId=sessionId.contents, ~module_, ~level, ~message, ~data)

let updateLogBuffers = (entry: logEntry, level: level, module_: string, message: string) => {
  LoggerLogic.updateLogBuffers(
    ~entries,
    ~maxEntries,
    ~appLog,
    ~maxAppLogEntries,
    entry,
    level,
    module_,
    message,
  )
}

let log = (~module_: string, ~level: level, ~message: string, ~data: 'a=?, ()): unit =>
  LoggerLogic.log(~ctx=runtimeContext(), ~module_, ~level, ~message, ~data?, ())

let trace = (~module_, ~message, ~data: 'a=?, ()) =>
  log(~module_, ~level=Trace, ~message, ~data?, ())
let debug = (~module_, ~message, ~data: 'a=?, ()) =>
  log(~module_, ~level=Debug, ~message, ~data?, ())
let info = (~module_, ~message, ~data: 'a=?, ()) => log(~module_, ~level=Info, ~message, ~data?, ())
let warn = (~module_, ~message, ~data: 'a=?, ()) => log(~module_, ~level=Warn, ~message, ~data?, ())
let error = (~module_, ~message, ~data: 'a=?, ()) =>
  log(~module_, ~level=Error, ~message, ~data?, ())

let logWithAppError = (~module_: string, ~level: level, ~message: string, ~appError: SharedTypes.appError, ~operationContext: option<string>=?, ~data: option<JSON.t>=?, ()) =>
  LoggerLogic.logWithAppError(~emitLog=(module_, level, message, data) => log(~module_=module_, ~level, ~message, ~data?, ()), ~module_, ~level, ~message, ~appError, ~operationContext?, ~data?, ())

let warnWithAppError = (
  ~module_,
  ~message,
  ~appError: SharedTypes.appError,
  ~operationContext: option<string>=?,
  ~data: option<JSON.t>=?,
  (),
) => logWithAppError(~module_, ~level=Warn, ~message, ~appError, ~operationContext?, ~data?, ())

let errorWithAppError = (
  ~module_,
  ~message,
  ~appError: SharedTypes.appError,
  ~operationContext: option<string>=?,
  ~data: option<JSON.t>=?,
  (),
) => logWithAppError(~module_, ~level=Error, ~message, ~appError, ~operationContext?, ~data?, ())

let perf = (~module_, ~message, ~durationMs, ~data: 'a=?, ()) =>
  LoggerLogic.perf(~emitLog=(module_, level, message, data) => log(~module_=module_, ~level, ~message, ~data?, ()), ~module_, ~message, ~durationMs, ~data?, ())

let timed = (~module_: string, ~operation: string, fn: unit => 'a): timedResult<'a> => {
  LoggerLogic.timed(
    ~perfFn=(module_, operation, durationMs) =>
      perf(~module_=module_, ~message=operation, ~durationMs, ()),
    ~module_,
    ~operation,
    fn,
  )
}

let timedAsync = async (~module_: string, ~operation: string, fn: unit => promise<'a>): timedResult<'a> =>
  await LoggerLogic.timedAsync(~perfFn=(module_, operation, durationMs) => perf(~module_=module_, ~message=operation, ~durationMs, ()), ~module_, ~operation, fn)

let attempt = (~module_: string, ~operation: string, fn: unit => 'a): operationResult<'a> => {
  LoggerLogic.attempt(
    ~emitError=(module_, message, payload) =>
      error(~module_=module_, ~message, ~data=Some(payload), ()),
    ~module_,
    ~operation,
    fn,
  )
}

let attemptAsync = async (~module_: string, ~operation: string, fn: unit => promise<'a>): operationResult<'a> =>
  await LoggerLogic.attemptAsync(~emitError=(module_, message, payload) => error(~module_=module_, ~message, ~data=Some(payload), ()), ~module_, ~operation, fn)

let startOperation = (~module_, ~operation, ~data=?, ()) =>
  debug(~module_, ~message=`${operation}_START`, ~data?, ())
let endOperation = (~module_, ~operation, ~data=?, ()) =>
  debug(~module_, ~message=`${operation}_COMPLETE`, ~data?, ())
let initialized = (~module_) => debug(~module_, ~message=`${module_} initialized`, ())

let logResult = (
  ~module_: string,
  ~message: string,
  result: Belt.Result.t<'a, 'e>,
  ~verbose=false,
) =>
  LoggerLogic.logResult(
    ~emitDebug=(module_, message) => debug(~module_=module_, ~message, ()),
    ~emitError=(module_, message, payload) => error(~module_=module_, ~message, ~data=Some(payload), ()),
    ~module_,
    ~message,
    result,
    ~verbose,
  )

// --- Facade & Init ---

let isDiagnosticMode = () => Constants.Telemetry.diagnosticMode.contents

let setLevel = lvl =>
  LoggerLogic.setLevel(
    ~minLevel,
    ~emitInfo=(module_, message, data) => info(~module_=module_, ~message, ~data?, ()),
    lvl,
  )

let enable = () =>
  LoggerLogic.enable(
    ~enabled,
    ~enabledModules,
    ~emitInfo=(module_, message, data) => info(~module_=module_, ~message, ~data?, ()),
  )

let enableDiagnostics = () =>
  LoggerLogic.enableDiagnostics(
    ~emitInfo=(module_, message, data) => info(~module_=module_, ~message, ~data?, ()),
  )

let disableDiagnostics = () =>
  LoggerLogic.disableDiagnostics(
    ~emitInfo=(module_, message, data) => info(~module_=module_, ~message, ~data?, ()),
  )

let disable = () =>
  LoggerLogic.disable(
    ~enabled,
    ~emitInfo=(module_, message, data) => info(~module_=module_, ~message, ~data?, ()),
  )

let toggle = () => {
  LoggerLogic.toggle(~enabled, ~enableFn=enable, ~disableFn=disable)
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
let setGlobalLoggerWarnHook: (
  (string, string, JSON.t) => unit
) => unit = %raw(`function(cb){ globalThis.__vtbLoggerWarn = cb; }`)

let batchTimer = ref(None)

let init = () => {
  LoggerLogic.ensureSessionId(sessionId)

  let debugObj = LoggerLogic.buildDebugObject(
    ~enable,
    ~disable,
    ~toggle,
    ~setLevelFromString=s => setLevel(stringToLevel(s)),
    ~getLog=() => entries,
    ~clearEntries=() => {%raw(`entries.length = 0`)},
    ~enableDiagnostics,
    ~disableDiagnostics,
    ~raiseTestError=() => {
      ignore(%raw(`(function(){ throw new Error("Test Error from Console") })()`))
    },
  )
  Window.setDebug(Window.window, asDynamic(debugObj))
  Window.setAppLog(Window.window, appLog)
  setGlobalLoggerWarnHook((module_, message, data) => {
    warn(~module_, ~message, ~data=Some(data), ())
  })

  LoggerLogic.bindGlobalErrorHandler(
    ~extractStack=errObj =>
      switch toNullable(errObj)->Nullable.toOption {
      | Some(e) => e["stack"]
      | None => ""
      },
    ~emitError=(module_, message, data) => error(~module_=module_, ~message, ~data?, ()),
  )

  LoggerLogic.bindUnhandledRejectionHandler(
    ~toUnhandledEvent,
    ~getReasonDetails=evt => {
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
      (reasonStr, stack)
    },
    ~preventDefaultIfNeeded=evt => {
      if !(Window.window["location"]["hostname"]->String.includes("localhost")) {
        UnhandledRejectionEvent.preventDefault(evt)
      }
    },
    ~emitError=(module_, message, data) => error(~module_=module_, ~message, ~data?, ()),
  )

  LoggerLogic.installLongTaskObserver()
  LoggerLogic.installLongTaskListener(
    ~debugFn=(module_, message, data) => debug(~module_=module_, ~message, ~data?, ()),
  )
  LoggerLogic.subscribeEventBusLogging(
    ~debugFn=(module_, message, data) => debug(~module_=module_, ~message, ~data?, ()),
    ~warnFn=(module_, message, data) => warn(~module_=module_, ~message, ~data?, ()),
    ~errorFn=(module_, message, data) => error(~module_=module_, ~message, ~data?, ()),
  )

  initialized(~module_="Logger")

  LoggerLogic.startBatchTimer(~batchTimer, ~flushTelemetry)
}
