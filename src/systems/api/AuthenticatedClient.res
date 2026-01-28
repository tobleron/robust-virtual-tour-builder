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

let request = async (url, ~method="GET", ~body: option<JSON.t>=?, ~headers=Dict.make(), ()) => {
  let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")

  switch token {
  | Some(t) => Dict.set(headers, "Authorization", "Bearer " ++ t)
  | None => ()
  }

  switch body {
  | Some(_) =>
    if Dict.get(headers, "Content-Type") == None {
      Dict.set(headers, "Content-Type", "application/json")
    }
  | None => ()
  }

  let bodyVal = switch body {
  | Some(b) => Some(JSON.stringify(b))
  | None => None
  }

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
