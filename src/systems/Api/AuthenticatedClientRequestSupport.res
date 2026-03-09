/* src/systems/Api/AuthenticatedClientRequestSupport.res */

open ReBindings
include AuthenticatedClientBase

let classifyRateLimitScope = (url: string): string => {
  if String.includes(url, "/health") {
    "health"
  } else if (
    String.includes(url, "/media/process-full") || String.includes(url, "/media/resize-batch")
  ) {
    "media_heavy"
  } else if (
    String.includes(url, "/project/load") ||
    String.includes(url, "/project/import/status") ||
    String.includes(url, "/project/export/status")
  ) {
    "read"
  } else if String.includes(url, "/geocoding") || String.includes(url, "/project/file/") {
    "read"
  } else {
    "write"
  }
}

let resolveEffectiveOperationId = (~operationId: option<string>=?): option<string> =>
  switch operationId {
  | Some(id) => Some(id)
  | None => Logger.getOperationId()
  }

let applyTraceHeaders = (
  ~headers: Dict.t<string>,
  ~effectiveOperationId: option<string>,
) => {
  let sessionId = switch Logger.getSessionId() {
  | Some(id) => id
  | None => "anonymous"
  }
  Dict.set(headers, "X-Session-ID", sessionId)
  effectiveOperationId->Option.forEach(opId => {
    Dict.set(headers, "X-Operation-ID", opId)
    Dict.set(headers, "X-Correlation-ID", opId)
  })
}

let isLifecycleOperationCancelled = (effectiveOperationId: option<string>): bool =>
  effectiveOperationId
  ->Option.map(id =>
    if String.startsWith(id, "op_") {
      !OperationLifecycle.isActive(id)
    } else {
      false
    }
  )
  ->Option.getOr(false)

let injectAuthorizationHeader = (headers: Dict.t<string>) => {
  if Dict.get(headers, "Authorization") == None {
    let token = Dom.Storage2.localStorage->Dom.Storage2.getItem("auth_token")
    let finalToken = switch token {
    | Some(t) => Some(t)
    | None if Constants.isDebugBuild() => Some("dev-token")
    | None => None
    }

    finalToken->Option.forEach(t => {
      let cookieValue = "auth_token=" ++ t ++ "; path=/; SameSite=Strict"
      Dom.setCookie(cookieValue)
    })

    finalToken->Option.forEach(t => Dict.set(headers, "Authorization", "Bearer " ++ t))
  }
}

let buildRequestId = (requestId: option<string>): string =>
  switch requestId {
  | Some(id) => id
  | None =>
    try {
      Crypto.randomUUID()
    } catch {
    | _ => "req_" ++ Float.toString(Date.now())
    }
  }

let buildRequestBody = (
  ~body: option<JSON.t>=?,
  ~formData: option<FormData.t>=?,
  ~headers: Dict.t<string>,
): option<JSON.t> =>
  switch (body, formData) {
  | (Some(b), Some(f)) =>
    Some(prepareRequestBody(Some(b), headers)->Option.map(castBody)->Option.getOr(castBody(f)))
  | (Some(b), _) => prepareRequestBody(Some(b), headers)->Option.map(castBody)
  | (None, Some(f)) => Some(castBody(f))
  | (None, None) => None
  }
