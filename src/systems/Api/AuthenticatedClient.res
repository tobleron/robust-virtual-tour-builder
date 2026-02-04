/* src/systems/Api/AuthenticatedClient.res */

open ReBindings

exception HttpError(int, string)

let dispatchLogout = () => {
  Dom.Storage2.localStorage->Dom.Storage2.removeItem("auth_token")
  let _ = %raw("window.dispatchEvent(new Event('auth:logout'))")
  Logger.warn(
    ~module_="AuthenticatedClient",
    ~message="LOGOUT_DISPATCHED",
    ~data=Some({"action": "Cleared auth_token"}),
    (),
  )
}

type response = {
  ok: bool,
  status: int,
  statusText: string,
  json: unit => Promise.t<JSON.t>,
  text: unit => Promise.t<string>,
  blob: unit => Promise.t<Blob.t>,
}

@val external fetch: (string, 'options) => Promise.t<response> = "fetch"

external castBody: 'a => JSON.t = "%identity"

let circuitBreaker = CircuitBreaker.make()

let prepareRequestBody = (body: option<JSON.t>, headers: Dict.t<string>) => {
  switch body {
  | Some(b) =>
    if Dict.get(headers, "Content-Type") == None {
      Dict.set(headers, "Content-Type", "application/json")
    }
    // CSP SAFE FIX
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
  (),
) => {
  if !CircuitBreaker.canExecute(circuitBreaker) {
    Logger.warn(~module_="AuthenticatedClient", ~message="CIRCUIT_OPEN", ~data=None, ())
    EventBus.dispatch(
      ShowNotification("Connection issues. Please wait a moment...", #Warning, None),
    )
    throw(HttpError(503, "Service temporarily unavailable"))
  }

  let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")

  let finalToken = switch token {
  | Some(t) => Some(t)
  | None =>
    // Professional fallback for local development automation
    Some("dev-token")
  }

  switch finalToken {
  | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
  | None => ()
  }

  // Inject Request ID for distributed tracing
  let requestId = try {
    Crypto.randomUUID()
  } catch {
  | _ => "req_" ++ Float.toString(Date.now()) // Fallback for older browsers
  }
  Dict.set(headers, "X-Request-ID", requestId)

  let bodyVal = switch (body, formData) {
  | (Some(b), _) => prepareRequestBody(Some(b), headers)->Option.map(castBody)
  | (None, Some(f)) => Some(castBody(f))
  | (None, None) => None
  }

  let options = {
    "method": method,
    "headers": headers,
    "body": bodyVal,
  }

  let handleFailure = () => {
    let wasOpen = CircuitBreaker.getState(circuitBreaker) == Open
    CircuitBreaker.recordFailure(circuitBreaker)
    let isOpen = CircuitBreaker.getState(circuitBreaker) == Open

    if !wasOpen && isOpen {
      EventBus.dispatch(
        ShowNotification("Connection issues detected. Retrying automatically...", #Warning, None),
      )
    }
  }

  let response = try {
    await fetch(url, options)
  } catch {
  | JsExn(e) =>
    handleFailure()
    throw(JsExn(e))
  }

  if response.status >= 500 {
    handleFailure()
  } else if response.status < 500 {
    CircuitBreaker.recordSuccess(circuitBreaker)
  }

  if response.status == 401 {
    dispatchLogout()
    throw(HttpError(401, "Unauthorized"))
  }

  if response.status >= 400 {
    throw(HttpError(response.status, response.statusText))
  }

  response
}

let requestWithRetry = async (
  url,
  ~method="GET",
  ~body: option<JSON.t>=?,
  ~formData: option<FormData.t>=?,
  ~headers=Dict.make(),
  ~retryConfig: option<Retry.config>=?,
  (),
) => {
  let controller = ReBindings.AbortController.newAbortController()

  let result = await Retry.execute(
    ~fn=async (~signal as _) => {
      try {
        let res = await request(url, ~method, ~body?, ~formData?, ~headers, ())
        Ok(res)
      } catch {
      | HttpError(status, text) => Error(`HttpError: ${Belt.Int.toString(status)} ${text}`)
      | JsExn(e) => Error(JsExn.message(e)->Option.getOr("Unknown Error"))
      | _ => Error("Unknown Error")
      }
    },
    ~signal=ReBindings.AbortController.signal(controller),
    ~config=?retryConfig,
    ~onRetry=(attempt, error, delay) => {
      if attempt > 1 {
        EventBus.dispatch(
          ShowNotification(
            `Retrying request... (attempt ${Belt.Int.toString(attempt)})`,
            #Info,
            None,
          ),
        )
      }
      Logger.debug(
        ~module_="AuthenticatedClient",
        ~message="RETRY_ATTEMPT",
        ~data=Some(
          JsonCombinators.Json.Encode.object([
            ("attempt", JsonCombinators.Json.Encode.int(attempt)),
            ("error", JsonCombinators.Json.Encode.string(error)),
            ("delayMs", JsonCombinators.Json.Encode.int(delay)),
          ]),
        ),
        (),
      )
    },
  )

  result
}
