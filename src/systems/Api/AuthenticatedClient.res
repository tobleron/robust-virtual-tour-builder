open ReBindings
include AuthenticatedClientRequest

let requestWithRetry = (
  url,
  ~method=?,
  ~body=?,
  ~formData=?,
  ~headers=Dict.make(),
  ~signal: option<ReBindings.AbortSignal.t>=?,
  ~retryConfig: option<Retry.config>=?,
  ~operationId: option<string>=?,
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
        ~operationId?,
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
