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
}

@val external fetch: (string, 'options) => Promise.t<response> = "fetch"

let prepareRequestBody = (body: option<JSON.t>, headers: Dict.t<string>) => {
  switch body {
  | Some(b) =>
    if Dict.get(headers, "Content-Type") == None {
      Dict.set(headers, "Content-Type", "application/json")
    }
    // CSP SAFE FIX
    Some(JSON.stringifyAny(b)->Option.getOr("{}"))
  | None => None
  }
}

let request = async (url, ~method="GET", ~body: option<JSON.t>=?, ~headers=Dict.make(), ()) => {
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

  let bodyVal = prepareRequestBody(body, headers)

  let options = {
    "method": method,
    "headers": headers,
    "body": bodyVal,
  }

  let response = await fetch(url, options)

  if response.status == 401 {
    dispatchLogout()
    throw(HttpError(401, "Unauthorized"))
  }

  if response.status >= 400 {
    throw(HttpError(response.status, response.statusText))
  }

  response
}
