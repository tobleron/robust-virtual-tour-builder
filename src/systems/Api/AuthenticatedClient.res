/* src/systems/Api/AuthenticatedClient.res */
open ReBindings

type headers
@send external getHeader: (headers, string) => Nullable.t<string> = "get"

type response = {
  status: int,
  statusText: string,
  json: unit => Promise.t<JSON.t>,
  text: unit => Promise.t<string>,
  blob: unit => Promise.t<Blob.t>,
  headers: headers,
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
  let timeoutId = ref(None)

  let onParentAbort = () => {
    // Do not set cleaned := true here to allow cleanup() to run fully
    switch timeoutId.contents {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    ReBindings.AbortController.abort(controller)
  }

  switch parentSignal {
  | Some(s) =>
    if ReBindings.AbortSignal.aborted(s) {
      ReBindings.AbortController.abort(controller)
    } else {
      s->ReBindings.AbortSignal.addEventListener("abort", onParentAbort)
    }
  | None => ()
  }

  timeoutId := Some(ReBindings.Window.setTimeout(() => {
        if !cleaned.contents {
          timedOut := true
          cleaned := true
          ReBindings.AbortController.abort(controller)
          // Remove parent listener on timeout too
          Option.forEach(parentSignal, s =>
            s->ReBindings.AbortSignal.removeEventListener("abort", onParentAbort)
          )
        }
      }, timeoutMs))

  let cleanup = () => {
    if !cleaned.contents {
      cleaned := true
      switch timeoutId.contents {
      | Some(id) => ReBindings.Window.clearTimeout(id)
      | None => ()
      }
      Option.forEach(parentSignal, s =>
        s->ReBindings.AbortSignal.removeEventListener("abort", onParentAbort)
      )
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
  let currentOperationId = Logger.getOperationId()

  Dict.set(headers, "X-Session-ID", sessionId)
  currentOperationId->Option.forEach(opId => Dict.set(headers, "X-Operation-ID", opId))

  // HARDENING: Check operation validity before request.
  // Only lifecycle operation IDs are eligible for cancellation checks.
  let isOpCancelled =
    currentOperationId
    ->Option.map(id =>
      if String.startsWith(id, "op_") {
        !OperationLifecycle.isActive(id)
      } else {
        false
      }
    )
    ->Option.getOr(false)

  if isOpCancelled {
    Error("OperationCancelled")
  } else {
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

    if !NetworkStatus.isOnline() {
      Logger.warn(
        ~module_="AuthenticatedClient",
        ~message="REQUEST_SKIPPED_OFFLINE",
        ~data=Some(Logger.castToJson({"url": url, "method": method})),
        (),
      )
      Error("NetworkOffline")
    } else {
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

        if res.status == 429 {
          signalScope.cleanup()
          // Treat 429 as failure for circuit breaker stats to help global backoff if needed
          CircuitBreaker.recordFailure(circuitBreaker)

          let retryAfter =
            res.headers
            ->getHeader("Retry-After")
            ->Nullable.toOption
            ->Option.flatMap(Belt.Int.fromString)
            ->Option.getOr(10)

          EventBus.dispatch(RateLimitBackoff(retryAfter))

          Error(`RateLimited: ${Belt.Int.toString(retryAfter)}`)
        } else if res.status >= 400 {
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
    ~shouldRetry=error => {
      if error == "NetworkOffline" || error == "OperationCancelled" {
        false
      } else if String.startsWith(error, "RateLimited: ") {
        true
      } else {
        Retry.defaultShouldRetry(error)
      }
    },
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
    ~getDelay=(error, _) => {
      if String.startsWith(error, "RateLimited: ") {
        let parts = String.split(error, ": ")
        if Array.length(parts) == 2 {
          parts[1]->Option.flatMap(Belt.Int.fromString)->Option.map(s => s * 1000)
        } else {
          None
        }
      } else {
        None
      }
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
    | Retry.Exhausted("NetworkOffline") => () // Handled by offline banner
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
