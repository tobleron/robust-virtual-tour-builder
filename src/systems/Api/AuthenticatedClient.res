/* src/systems/Api/AuthenticatedClient.res */
open ReBindings

type response = {
  status: int,
  statusText: string,
  json: unit => Promise.t<JSON.t>,
  text: unit => Promise.t<string>,
  blob: unit => Promise.t<Blob.t>,
}

@val external fetch: (string, 'options) => Promise.t<response> = "fetch"

let fetchJson = (res: response) => res.json()
let fetchText = (res: response) => res.text()
let fetchBlob = (res: response) => res.blob()

external castBody: 'a => JSON.t = "%identity"
let toUpper: string => string = %raw("(s) => String(s || '').toUpperCase()")

let circuitBreaker = CircuitBreaker.make()

module TimeoutPolicy = {
  let getTimeoutMs = (method: string): int => {
    switch toUpper(method) {
    | "GET"
    | "HEAD" => 10000
    | "DELETE" => 15000
    | "POST"
    | "PUT"
    | "PATCH" => 25000
    | _ => 15000
    }
  }
}

type requestSignalScope = {
  signal: ReBindings.AbortSignal.t,
  cleanup: unit => unit,
  wasTimedOut: unit => bool,
}

let prepareRequestSignal = (
  ~parentSignal: option<ReBindings.AbortSignal.t>,
  ~timeoutMs: int,
): requestSignalScope => {
  let controller = ReBindings.AbortController.make()
  let requestSignal = ReBindings.AbortController.signal(controller)
  let timedOut = ref(false)
  let cleaned = ref(false)

  let timeoutId = ReBindings.Window.setTimeout(() => {
    timedOut := true
    ReBindings.AbortController.abort(controller)
  }, timeoutMs)

  let detachParentAbort = ref(None)
  switch parentSignal {
  | Some(s) =>
    if ReBindings.AbortSignal.aborted(s) {
      ReBindings.AbortController.abort(controller)
    } else {
      let onAbort = () => ReBindings.AbortController.abort(controller)
      s->ReBindings.AbortSignal.addEventListener("abort", onAbort)
      detachParentAbort :=
        Some(() => s->ReBindings.AbortSignal.removeEventListener("abort", onAbort))
    }
  | None => ()
  }

  let cleanup = () => {
    if !cleaned.contents {
      cleaned := true
      ReBindings.Window.clearTimeout(timeoutId)
      detachParentAbort.contents->Option.forEach(fn => fn())
    }
  }

  {signal: requestSignal, cleanup, wasTimedOut: () => timedOut.contents}
}

let prepareRequestBody = (body: option<JSON.t>, headers: Dict.t<string>): option<string> => {
  switch body {
  | Some(b) =>
    if Dict.get(headers, "Content-Type") == None {
      Dict.set(headers, "Content-Type", "application/json")
    }
    Some(JsonCombinators.Json.stringify(b))
  | None => None
  }
}

let request = async (
  url,
  ~method="GET",
  ~body: option<JSON.t>=?,
  ~formData: option<FormData.t>=?,
  ~headers=Dict.make(),
  ~signal: option<ReBindings.AbortSignal.t>=?,
  ~requestId: option<string>=?,
  (),
) => {
  let sessionId = switch Logger.getSessionId() {
  | Some(id) => id
  | None => "anonymous"
  }

  Dict.set(headers, "X-Session-ID", sessionId)
  Logger.getOperationId()->Option.forEach(opId => Dict.set(headers, "X-Operation-ID", opId))

  // Inject Authorization header if not already present
  if Dict.get(headers, "Authorization") == None {
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")

    let finalToken = switch token {
    | Some(t) => Some(t)
    | None if Constants.isDebugBuild() => Some("dev-token") // Only allowed in debug builds
    | None => None
    }

    // Sync the effective token to cookie for media requests (image GETs cannot send custom headers).
    finalToken->Option.forEach(t => {
      let cookieValue = "auth_token=" ++ t ++ "; path=/; SameSite=Strict"
      let _ = %raw(`(val) => { document.cookie = val }`)(cookieValue)
    })

    finalToken->Option.forEach(t => Dict.set(headers, "Authorization", "Bearer " ++ t))
  }

  let lastState = CircuitBreaker.getState(circuitBreaker)
  if lastState === CircuitBreaker.Open {
    NotificationManager.dispatch({
      id: "cb-open-notification",
      importance: Warning,
      context: Operation("api"),
      message: "Connection issues: Circuit breaker is open. Please wait 30 seconds.",
      details: None,
      action: None,
      duration: 10000,
      dismissible: true,
      createdAt: Date.now(),
    })
    Error("Circuit breaker is open")
  } else {
    // Inject Request ID for distributed tracing
    let finalRequestId = switch requestId {
    | Some(id) => id
    | None =>
      try {
        Crypto.randomUUID()
      } catch {
      | _ => "req_" ++ Float.toString(Date.now())
      }
    }
    Dict.set(headers, "X-Request-ID", finalRequestId)
    Logger.setOperationId(Some(finalRequestId)) // Link telemetry to this request as well

    let timeoutMs = TimeoutPolicy.getTimeoutMs(method)
    let signalScope = prepareRequestSignal(~parentSignal=signal, ~timeoutMs)

    let bodyVal = switch (body, formData) {
    | (Some(b), Some(f)) =>
      Some(
        prepareRequestBody(Some(b), headers)
        ->Option.map(castBody)
        ->Option.getOr(castBody(f)),
      )
    | (Some(b), _) => prepareRequestBody(Some(b), headers)->Option.map(castBody)
    | (None, Some(f)) => Some(castBody(f))
    | (None, None) => None
    }

    let options = {
      "method": method,
      "headers": headers,
      "body": bodyVal,
      "signal": Some(signalScope.signal),
    }

    try {
      let res = await fetch(url, options)
      if res.status >= 400 {
        signalScope.cleanup()
        CircuitBreaker.recordFailure(circuitBreaker)
        let currentState = CircuitBreaker.getState(circuitBreaker)

        if currentState === CircuitBreaker.Open && lastState !== CircuitBreaker.Open {
          NotificationManager.dispatch({
            id: "circuit-breaker-open",
            importance: Warning,
            context: Operation("network"),
            message: "Connection issues: Circuit breaker activated",
            details: Some(
              "Multiple requests failing. Circuit breaker activated to prevent overload.",
            ),
            action: None,
            duration: 10000,
            dismissible: true,
            createdAt: Date.now(),
          })
        }

        let errorText = await res.text()
        Error(`HttpError: Status ${Belt.Int.toString(res.status)} - ${errorText}`)
      } else {
        signalScope.cleanup()
        CircuitBreaker.recordSuccess(circuitBreaker)
        Ok(res)
      }
    } catch {
    | e =>
      signalScope.cleanup()
      // Use JsExn as suggested by deprecation warning
      let (name, msg) = switch JsExn.fromException(e) {
      | Some(err) => (
          Option.getOr(JsExn.name(err), "Unknown"),
          Option.getOr(JsExn.message(err), "Unknown Error"),
        )
      | None => ("Unknown", String.make(e))
      }

      if name == "AbortError" || name == "Abort" {
        if signalScope.wasTimedOut() {
          Error("TimeoutError: Request timed out after " ++ Belt.Int.toString(timeoutMs) ++ "ms")
        } else {
          Error("AbortError")
        }
      } else {
        CircuitBreaker.recordFailure(circuitBreaker)
        Error(
          if msg == "" {
            "Unknown Error"
          } else {
            msg
          },
        )
      }
    }
  }
}

let requestWithRetry = (
  url,
  ~method=?,
  ~body=?,
  ~formData=?,
  ~headers=Dict.make(),
  ~signal: option<ReBindings.AbortSignal.t>=?,
  ~retryConfig: option<Retry.config>=?,
  (),
) => {
  // Inject Request ID for distributed tracing and retry linking
  let requestId = try {
    Crypto.randomUUID()
  } catch {
  | _ => "req_" ++ Float.toString(Date.now())
  }
  let incidentNotificationId = "api-incident-" ++ requestId
  let resolvedSignal = switch signal {
  | Some(s) => s
  | None => ReBindings.AbortController.signal(ReBindings.AbortController.make())
  }
  let defaultRetryConfig: Retry.config = {
    maxRetries: 3,
    initialDelayMs: 500,
    maxDelayMs: 8000,
    backoffMultiplier: 2.0,
    jitter: true,
  }

  Retry.execute(
    ~fn=(~signal) =>
      request(
        url,
        ~method=method->Option.getOr("GET"),
        ~body?,
        ~formData?,
        ~headers,
        ~signal,
        ~requestId,
        (),
      ),
    ~signal=resolvedSignal,
    ~config=Option.getOr(retryConfig, defaultRetryConfig),
    ~onRetry=(attempt, error, delay) => {
      Logger.warn(
        ~module_="AuthenticatedClient",
        ~message="RETRY_ATTEMPT",
        ~data=Some({
          "attempt": attempt,
          "error": error,
          "delay": delay,
        }),
        (),
      )

      NotificationManager.dispatch({
        id: incidentNotificationId,
        importance: Warning,
        context: Operation("api"),
        message: "Connection issue detected. Retrying request.",
        details: Some(
          `Attempt ${Belt.Int.toString(
              attempt,
            )} failed (${error}). Next attempt in ${Float.toString(
              Float.fromInt(delay) /. 1000.0,
            )}s`,
        ),
        action: None,
        duration: 10000,
        dismissible: true,
        createdAt: Date.now(),
      })
    },
  )->Promise.then(result => {
    switch result {
    | Retry.Success(_, attempts) if attempts > 1 =>
      NotificationManager.dispatch({
        id: incidentNotificationId,
        importance: Success,
        context: Operation("api"),
        message: "Connection recovered.",
        details: Some("Request succeeded after retries."),
        action: None,
        duration: 4000,
        dismissible: true,
        createdAt: Date.now(),
      })
    | Retry.Exhausted("AbortError") => NotificationManager.dismiss(incidentNotificationId)
    | Retry.Exhausted(error) =>
      NotificationManager.dispatch({
        id: incidentNotificationId,
        importance: Error,
        context: Operation("api"),
        message: "Request failed.",
        details: Some(error),
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
    | _ => ()
    }
    Promise.resolve(result)
  })
}
