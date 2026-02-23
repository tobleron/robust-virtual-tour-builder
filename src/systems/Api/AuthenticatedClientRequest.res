/* src/systems/Api/AuthenticatedClientRequest.res */

open ReBindings
include AuthenticatedClientBase

let request = async (
  url,
  ~method="GET",
  ~body: option<JSON.t>=?,
  ~formData: option<FormData.t>=?,
  ~headers=Dict.make(),
  ~signal: option<ReBindings.AbortSignal.t>=?,
  ~requestId: option<string>=?,
  ~operationId: option<string>=?,
  (),
) => {
  let sessionId = switch Logger.getSessionId() {
  | Some(id) => id
  | None => "anonymous"
  }
  let effectiveOperationId = switch operationId {
  | Some(id) => Some(id)
  | None => Logger.getOperationId()
  }

  Dict.set(headers, "X-Session-ID", sessionId)
  effectiveOperationId->Option.forEach(opId => {
    Dict.set(headers, "X-Operation-ID", opId)
    Dict.set(headers, "X-Correlation-ID", opId)
  })

  // HARDENING: Check operation validity before request.
  // Only lifecycle operation IDs are eligible for cancellation checks.
  let isOpCancelled =
    effectiveOperationId
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

        let timeoutMs = getTimeoutMs(~method, ~url)
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
            // 429 is a controlled throttling response, not a transport failure.
            // Do not trip the circuit breaker; rely on Retry-After backoff.

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
              Error(
                "TimeoutError: Request timed out after " ++ Belt.Int.toString(timeoutMs) ++ "ms",
              )
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
