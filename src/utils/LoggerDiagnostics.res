/* src/utils/LoggerDiagnostics.res */
// @efficiency-role: service-orchestrator

open ReBindings
open LoggerCommon

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
) => {
  {
    "enable": enable,
    "disable": disable,
    "toggle": toggle,
    "setLevel": setLevelFromString,
    "getLog": getLog,
    "clear": clearEntries,
    "enableDiagnostics": enableDiagnostics,
    "disableDiagnostics": disableDiagnostics,
    "testError": raiseTestError,
  }
}

let installLongTaskObserver = () => {
  let _ = %raw(`
    (function() {
      if (typeof PerformanceObserver !== 'undefined') {
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            if (entry.duration > 50) {
              window.dispatchEvent(new CustomEvent('vtb-long-task', {
                detail: {
                  durationMs: entry.duration,
                  startTime: entry.startTime,
                  name: entry.name
                }
              }));
            }
          });
        });
        observer.observe({ entryTypes: ["longtask"] });
      }
    })()
  `)
  ()
}

let bindGlobalErrorHandler = (
  ~extractStack: 'errObj => string,
  ~emitError: (string, string, option<JSON.t>) => unit,
) => {
  Window.setOnError(Window.window, (msg, source, line, col, errObj) => {
    emitError(
      "Global",
      "UNCAUGHT_ERROR",
      Some(castToJson({
        "message": msg,
        "source": source,
        "line": line,
        "col": col,
        "stack": extractStack(errObj),
      })),
    )
    false
  })
}

let bindUnhandledRejectionHandler = (
  ~toUnhandledEvent: 'eventLike => 'event,
  ~getReasonDetails: 'event => (string, string),
  ~preventDefaultIfNeeded: 'event => unit,
  ~emitError: (string, string, option<JSON.t>) => unit,
) => {
  Window.setOnUnhandledRejection(Window.window, event => {
    let evt = toUnhandledEvent(event)
    let (reasonStr, stack) = getReasonDetails(evt)

    emitError(
      "Global",
      "UNHANDLED_REJECTION",
      Some(castToJson({
        "reason": reasonStr,
        "stack": stack,
      })),
    )

    preventDefaultIfNeeded(evt)
  })
}

let installLongTaskListener = (~debugFn: (string, string, option<JSON.t>) => unit) => {
  let _ = Window.addEventListener("vtb-long-task", (_e: Dom.event) => {
    let detail = %raw(`_e.detail`)
    debugFn("Performance", "LONG_TASK_DETECTED", Some(castToJson(detail)))
  })
  ()
}

let subscribeEventBusLogging = (
  ~debugFn: (string, string, option<JSON.t>) => unit,
  ~warnFn: (string, string, option<JSON.t>) => unit,
  ~errorFn: (string, string, option<JSON.t>) => unit,
) => {
  let _ = EventBus.subscribe(evt => {
    switch evt {
    | EventBus.ShowModal(config) =>
      debugFn("Modal", `Opening Modal: ${config.title}`, Some(castToJson(config.description)))
    | EventBus.UpdateProcessing(status) =>
      if status["error"] {
        errorFn("Processing", `Processing Error: ${status["message"]}`, Some(castToJson(status)))
      }
    | EventBus.NavStart(payload) =>
      debugFn(
        "Navigation",
        `Navigating to Journey ${Belt.Int.toString(payload.journeyId)}`,
        None,
      )
    | EventBus.NetworkStatusChanged(online) =>
      if online {
        debugFn("NetworkStatus", "NETWORK_ONLINE", None)
      } else {
        warnFn("NetworkStatus", "NETWORK_OFFLINE", None)
      }
    | _ => ()
    }
  })
  ()
}

let startBatchTimer = (
  ~batchTimer: ref<option<int>>,
  ~flushTelemetry: unit => Promise.t<unit>,
) => {
  batchTimer := Some(Window.setInterval(() => {
        let _ = flushTelemetry()->Promise.catch(_ => Promise.resolve())
      }, Constants.Telemetry.batchInterval))
}
