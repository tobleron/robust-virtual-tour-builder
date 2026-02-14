/**
 * UrlUtils.res - Utility for generating safe object URLs
 */
open ReBindings

@val external decodeUriComponent: string => string = "decodeURIComponent"

let safeCreateObjectURL = (obj: 'a): string => {
  try {
    URL.createObjectURL(obj)
  } catch {
  | exn =>
    let (msg, stack) = Logger.getErrorDetails(exn)
    Logger.error(
      ~module_="UrlUtils",
      ~message="CREATE_URL_FAILED",
      ~data=Some({"error": msg, "stack": stack}),
      (),
    )
    ""
  }
}

let fileToUrl = (file: Types.file): string => {
  switch file {
  | Url(s) => s
  | Blob(b) => safeCreateObjectURL(b)
  | File(f) => safeCreateObjectURL(f)
  }
}

let revokeUrl = (url: string) => {
  if !String.startsWith(url, "http") && url != "" {
    // Delay revocation by 5 seconds to ensure Pannellum has finished reading the blob
    let _ = Window.setTimeout(() => {
      try {
        URL.revokeObjectURL(url)
      } catch {
      | _ => ()
      }
    }, 5000)
  }
}

let stripExtension = (filename: string): string => {
  let lastDot = String.lastIndexOf(filename, ".")
  if lastDot == -1 {
    filename
  } else {
    String.substring(filename, ~start=0, ~end=lastDot)
  }
}

let getExtension = (filename: string): string => {
  let lastDot = String.lastIndexOf(filename, ".")
  if lastDot == -1 {
    "webp" // Default fallback or empty
  } else {
    String.substring(filename, ~start=lastDot + 1, ~end=String.length(filename))
  }
}

let stripQuery = (url: string): string => {
  let parts = String.split(url, "?")
  Belt.Array.get(parts, 0)->Option.getOr(url)
}

let stripQueryAndFragment = (url: string): string => {
  let withoutQuery = stripQuery(url)
  let parts = String.split(withoutQuery, "#")
  Belt.Array.get(parts, 0)->Option.getOr(withoutQuery)
}

let decodeURIComponentSafely = (value: string): string => {
  try {
    decodeUriComponent(value)
  } catch {
  | _ => value
  }
}

let getFileNameFromUrl = (url: string): string => {
  let cleaned = stripQueryAndFragment(url)
  let segments = String.split(cleaned, "/")
  let lastSegment = Belt.Array.get(segments, Belt.Array.length(segments) - 1)->Option.getOr(cleaned)

  if lastSegment == "" {
    ""
  } else {
    decodeURIComponentSafely(lastSegment)
  }
}
