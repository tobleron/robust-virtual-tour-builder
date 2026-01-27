/* src/utils/Logger.res - Facade for Logger */

open ReBindings
include LoggerTypes
include LoggerTelemetry
include LoggerLogic

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
