open ReBindings

type apiError = {
  error: string,
  details: option<string>,
}

let apiErrorDecoder = JsonCombinators.Json.Decode.object(field => {
  {
    error: field.required("error", JsonCombinators.Json.Decode.string),
    details: field.optional("details", JsonCombinators.Json.Decode.string),
  }
})

let throwableMessageRaw: 'a => string = %raw(`
  function(e) {
    try {
      if (e == null) return "";
      if (typeof e === "string") return e;
      if (e instanceof Error) return e.message || String(e);
      if (typeof e.message === "string" && e.message.length > 0) return e.message;
      if (typeof e === "object") {
        try {
          return JSON.stringify(e);
        } catch (_) {
          return String(e);
        }
      }
      return String(e);
    } catch (_) {
      return "";
    }
  }
`)

let normalizeThrowableMessage = (exn: exn): string => {
  let (msg, _) = Logger.getErrorDetails(exn)
  if msg != "" && msg != "Unknown JS Error" && msg != "Unknown Error" {
    msg
  } else {
    let fallback = throwableMessageRaw(exn)
    if fallback != "" {
      fallback
    } else {
      "Unexpected export error"
    }
  }
}

let isUnauthorizedHttpError = (msg: string): bool => {
  String.includes(msg, "HttpError: Status 401")
}

let extractHttpErrorBody = (msg: string): string => {
  let parts = String.split(msg, " - ")
  if Belt.Array.length(parts) > 1 {
    Belt.Array.get(parts, 1)->Option.getOr(msg)
  } else {
    msg
  }
}

let backendOfflineExportMessage = () =>
  "Export backend is unreachable at " ++
  Constants.backendUrl ++ ". Start backend server (`npm run dev:backend`) and retry."

let fetchSceneUrlBlob = async (~url: string, ~authToken: option<string>, ~signal: option<BrowserBindings.AbortSignal.t>=?): result<
  Blob.t,
  string,
> => {
  try {
    let headers = Dict.make()
    authToken->Option.forEach(t => Dict.set(headers, "Authorization", "Bearer " ++ t))
    let response = await Fetch.fetch(
      url,
      Fetch.requestInit(~method="GET", ~headers, ~signal?, ()),
    )
    if Fetch.ok(response) {
      let b = await Fetch.blob(response)
      Ok(b)
    } else {
      let body = await Fetch.text(response)
      Error("HttpError: Status " ++ Belt.Int.toString(Fetch.status(response)) ++ " - " ++ body)
    }
  } catch {
  | exn => {
      let msg = normalizeThrowableMessage(exn)
      Error("Failed to fetch scene asset: " ++ msg)
    }
  }
}

let normalizeLogoExtension = (name: string): string => {
  let parts = name->String.toLowerCase->String.split(".")
  let ext = parts->Belt.Array.get(Array.length(parts) - 1)->Option.getOr("png")
  switch ext {
  | "png" | "jpg" | "jpeg" | "webp" | "svg" => ext
  | _ => "png"
  }
}

let filenameFromUrl = (url: string): option<string> => {
  let cleaned = url->String.split("?")->Belt.Array.get(0)->Option.getOr(url)
  let segments = cleaned->String.split("/")
  let fileName = segments->Belt.Array.get(Array.length(segments) - 1)->Option.getOr("")
  if fileName == "" {
    None
  } else {
    Some(fileName)
  }
}

let isLikelyImageUrl = (url: string): bool => {
  let lowered = url->String.toLowerCase
  String.includes(lowered, ".png") ||
  String.includes(lowered, ".jpg") ||
  String.includes(lowered, ".jpeg") ||
  String.includes(lowered, ".webp") ||
  String.includes(lowered, ".svg")
}

let isLikelyImageBlob = (~blob: Blob.t, ~urlHint: option<string>): bool => {
  let mime = blob->Blob.type_->String.toLowerCase
  if String.startsWith(mime, "image/") {
    true
  } else {
    switch (mime, urlHint) {
    | ("", Some(url)) => isLikelyImageUrl(url)
    | _ => false
    }
  }
}

let fetchLib = async (filename, ~signal: option<BrowserBindings.AbortSignal.t>=?) => {
  try {
    let response = await Fetch.fetch("/libs/" ++ filename, Fetch.requestInit(~method="GET", ~signal?, ()))

    if !Fetch.ok(response) {
      Error("Missing Library: " ++ filename)
    } else {
      let b = await Fetch.blob(response)
      Ok(b)
    }
  } catch {
  | exn =>
    let (msg, _stack) = Logger.getErrorDetails(exn)
    Error(msg)
  }
}
