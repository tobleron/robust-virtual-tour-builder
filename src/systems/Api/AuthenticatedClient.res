/* src/systems/Api/AuthenticatedClient.res */
open ReBindings
open Types

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

let circuitBreaker = CircuitBreaker.make()

let lastNotificationTime = ref(0.0)
let throttledNotification = (message, importance) => {
  let now = Date.now()
  if now -. lastNotificationTime.contents > 5000.0 {
    lastNotificationTime := now
    NotificationManager.dispatch({
      id: "cb-status-notification",
      importance,
      context: Operation("api"),
      message,
      details: None,
      action: None,
      duration: 5000,
      dismissible: true,
      createdAt: now,
    })
  }
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
  ~signal: option<ReBindings.AbortController.signal>=?,
  (),
) => {
  let sessionId = switch GlobalStateBridge.getState().sessionId {
  | Some(id) => id
  | None => "anonymous"
  }

  Dict.set(headers, "X-Session-ID", sessionId)

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
    let requestId = try {
      Crypto.randomUUID()
    } catch {
    | _ => "req_" ++ Float.toString(Date.now())
    }
    Dict.set(headers, "X-Request-ID", requestId)

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
      "signal": signal,
    }

    try {
      let res = await fetch(url, options)
      if res.status >= 400 {
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
        } else if lastState === CircuitBreaker.Closed && currentState === CircuitBreaker.Closed {
          throttledNotification("Connection issues detected. Retrying automatically...", Error)
        }

        let errorText = await res.text()
        Error(`HttpError: Status ${Belt.Int.toString(res.status)} - ${errorText}`)
      } else {
        CircuitBreaker.recordSuccess(circuitBreaker)
        Ok(res)
      }
    } catch {
    | e =>
      let errObj: {..} = Obj.magic(e)
      let name: string = try {errObj["name"]} catch {
      | _ => "Unknown"
      }
      let msg: string = try {errObj["message"]} catch {
      | _ => String.make(e)
      }

      if name == "AbortError" || name == "Abort" {
        Error("AbortError")
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
  ~signal: option<ReBindings.AbortController.signal>=?,
  ~retryConfig: option<Retry.config>=?,
  (),
) => {
  // Inject Request ID for distributed tracing and retry linking
  let requestId = try {
    Crypto.randomUUID()
  } catch {
  | _ => "req_" ++ Float.toString(Date.now())
  }

  Retry.execute(
    ~fn=(~signal) =>
      request(url, ~method=method->Option.getOr("GET"), ~body?, ~formData?, ~headers, ~signal, ()),
    ~signal=switch signal {
    | Some(s) => s
    | None => ReBindings.AbortController.signal(ReBindings.AbortController.newAbortController())
    },
    ~config=Option.getOr(retryConfig, {...Retry.defaultConfig, maxRetries: 3}),
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
        id: `retry-${requestId}-${Belt.Int.toString(attempt)}`,
        importance: Warning,
        context: Operation("api"),
        message: `Retrying request... (attempt ${Belt.Int.toString(attempt)})`,
        details: Some(`Next attempt in ${Float.toString(Float.fromInt(delay) /. 1000.0)}s`),
        action: None,
        duration: 10000,
        dismissible: true,
        createdAt: Date.now(),
      })
    },
  )
}
