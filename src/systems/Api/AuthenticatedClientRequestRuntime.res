/* src/systems/Api/AuthenticatedClientRequestRuntime.res */

include AuthenticatedClientBase

let probeHealth = async (
  ~lastState,
  ~domainBreaker,
  ~signalScope: requestSignalScope,
): bool => {
  if lastState === CircuitBreaker.Open || lastState === CircuitBreaker.HalfOpen {
    let probeRes = await fetch(
      Constants.backendUrl ++ "/health",
      {
        "method": "GET",
        "headers": Dict.make(),
        "signal": Some(signalScope.signal),
      },
    )
    if probeRes.status >= 400 {
      CircuitBreaker.recordFailure(domainBreaker)
      false
    } else {
      CircuitBreaker.recordSuccess(domainBreaker)
      true
    }
  } else {
    true
  }
}

let handleResponse = async (
  ~res: response,
  ~signalScope: requestSignalScope,
  ~domain,
  ~domainKey: string,
  ~domainBreaker,
  ~lastState,
  ~scopeClass: string,
): result<response, string> => {
  if res.status == 429 {
    signalScope.cleanup()
    CircuitBreakerRegistry.releaseBulkhead(domain)

    let retryAfter =
      res.headers
      ->getHeader("Retry-After")
      ->Nullable.toOption
      ->Option.flatMap(Belt.Int.fromString)
      ->Option.getOr(10)
    let rateScope =
      res.headers
      ->getHeader("x-ratelimit-scope")
      ->Nullable.toOption
      ->Option.getOr(scopeClass)

    RequestQueue.handleRateLimitForScope(~scope=rateScope, ~seconds=retryAfter)
    EventBus.dispatch(RateLimitBackoff(retryAfter))
    Error(`RateLimited: ${Belt.Int.toString(retryAfter)}`)
  } else if res.status >= 400 {
    signalScope.cleanup()
    CircuitBreaker.recordFailure(domainBreaker)
    CircuitBreakerRegistry.releaseBulkhead(domain)
    let currentState = CircuitBreaker.getState(domainBreaker)

    if currentState === CircuitBreaker.Open && lastState !== CircuitBreaker.Open {
      Logger.info(
        ~module_="AuthenticatedClient",
        ~message="CIRCUIT_OPENED",
        ~data=Logger.castToJson({"domain": domainKey}),
        (),
      )
      NotificationManager.dispatch({
        id: "circuit-breaker-open-" ++ domainKey,
        importance: Warning,
        context: Operation("network"),
        message: "Connection issues detected for service domain.",
        details: Some("Circuit breaker activated to prevent overload in this domain."),
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
    CircuitBreaker.recordSuccess(domainBreaker)
    CircuitBreakerRegistry.releaseBulkhead(domain)
    Ok(res)
  }
}

let classifyException = (
  ~e: exn,
  ~signalScope: requestSignalScope,
  ~timeoutMs: int,
  ~domainBreaker,
): string => {
  signalScope.cleanup()
  let (name, msg) = switch JsExn.fromException(e) {
  | Some(err) => (
      Option.getOr(JsExn.name(err), "Unknown"),
      Option.getOr(JsExn.message(err), "Unknown Error"),
    )
  | None => ("Unknown", String.make(e))
  }

  if name == "AbortError" || name == "Abort" {
    if signalScope.wasTimedOut() {
      "TimeoutError: Request timed out after " ++ Belt.Int.toString(timeoutMs) ++ "ms"
    } else {
      "AbortError"
    }
  } else {
    CircuitBreaker.recordFailure(domainBreaker)
    if msg == "" {
      "Unknown Error"
    } else {
      msg
    }
  }
}

let perform = async (
  ~url: string,
  ~options: 'options,
  ~signalScope: requestSignalScope,
  ~timeoutMs: int,
  ~domain,
  ~domainKey: string,
  ~domainBreaker,
  ~lastState,
  ~scopeClass: string,
): result<response, string> => {
  let acquireSucceeded = CircuitBreakerRegistry.tryAcquireBulkhead(domain)
  if !acquireSucceeded {
    Error("BulkheadRejected: Too many concurrent requests in domain")
  } else {
    try {
      let probeAllowed = await probeHealth(~lastState, ~domainBreaker, ~signalScope)
      if !probeAllowed {
        CircuitBreakerRegistry.releaseBulkhead(domain)
        signalScope.cleanup()
        Error("Circuit breaker is open")
      } else {
        let _ = await RequestQueue.waitForScope(~scope=scopeClass)
        let res = await fetch(url, options)
        await handleResponse(
          ~res,
          ~signalScope,
          ~domain,
          ~domainKey,
          ~domainBreaker,
          ~lastState,
          ~scopeClass,
        )
      }
    } catch {
    | e =>
      CircuitBreakerRegistry.releaseBulkhead(domain)
      Error(classifyException(~e, ~signalScope, ~timeoutMs, ~domainBreaker))
    }
  }
}
