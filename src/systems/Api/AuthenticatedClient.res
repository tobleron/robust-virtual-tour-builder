/* src/systems/Api/AuthenticatedClient.res */

open ReBindings
open RescriptSchema

exception HttpError(int, string)

let dispatchLogout = () => {
  let _ = %raw("window.dispatchEvent(new Event('auth:logout'))")
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
    Some(S.reverseConvertToJsonStringOrThrow(b, Schemas.Shared.jsonSchema))
  | None => None
  }
}

let request = async (url, ~method="GET", ~body: option<JSON.t>=?, ~headers=Dict.make(), ()) => {
  let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")

  switch token {
  | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
  | None => ()
  }

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
