/* src/systems/Api/AuthenticatedClientRequest.res */

open ReBindings
include AuthenticatedClientBase

let classifyRateLimitScope = (url: string): string => {
  AuthenticatedClientRequestSupport.classifyRateLimitScope(url)
}

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
  let domain = CircuitBreakerRegistry.resolveDomainForUrl(url)
  let domainKey = domain->CircuitBreakerRegistry.domainToKey
  let domainBreaker = getDomainCircuitBreaker(domain)
  let effectiveOperationId = AuthenticatedClientRequestSupport.resolveEffectiveOperationId(
    ~operationId?,
  )
  AuthenticatedClientRequestSupport.applyTraceHeaders(~headers, ~effectiveOperationId)
  let isOpCancelled = AuthenticatedClientRequestSupport.isLifecycleOperationCancelled(
    effectiveOperationId,
  )

  if isOpCancelled {
    Error("OperationCancelled")
  } else {
    AuthenticatedClientRequestSupport.injectAuthorizationHeader(headers)

    if !NetworkStatus.isOnline() {
      Logger.warn(
        ~module_="AuthenticatedClient",
        ~message="REQUEST_SKIPPED_OFFLINE",
        ~data=Some(Logger.castToJson({"url": url, "method": method})),
        (),
      )
      Error("NetworkOffline")
    } else {
      let lastState = CircuitBreaker.getState(domainBreaker)
      let canRun = CircuitBreaker.canExecute(domainBreaker)
      if !canRun {
        NotificationManager.dispatch({
          id: "cb-open-notification-" ++ domainKey,
          importance: Warning,
          context: Operation("api"),
          message: "Connection issues. Please wait before retrying.",
          details: None,
          action: None,
          duration: 10000,
          dismissible: true,
          createdAt: Date.now(),
        })
        Error("Circuit breaker is open")
      } else {
        let finalRequestId = AuthenticatedClientRequestSupport.buildRequestId(requestId)
        Dict.set(headers, "X-Request-ID", finalRequestId)
        if method == "POST" || method == "PUT" || method == "PATCH" || method == "DELETE" {
          if Dict.get(headers, "X-Idempotency-Key") == None {
            Dict.set(headers, "X-Idempotency-Key", finalRequestId)
          }
        }

        let timeoutMs = getTimeoutMs(~method, ~url)
        let signalScope = prepareRequestSignal(~parentSignal=signal, ~timeoutMs)
        let bodyVal = AuthenticatedClientRequestSupport.buildRequestBody(
          ~body?,
          ~formData?,
          ~headers,
        )

        let options = {
          "method": method,
          "headers": headers,
          "body": bodyVal,
          "signal": Some(signalScope.signal),
        }

        await AuthenticatedClientRequestRuntime.perform(
          ~url,
          ~options,
          ~signalScope,
          ~timeoutMs,
          ~domain,
          ~domainKey,
          ~domainBreaker,
          ~lastState,
          ~scopeClass=classifyRateLimitScope(url),
        )
      }
    }
  }
}
