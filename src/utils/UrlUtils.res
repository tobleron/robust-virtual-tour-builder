/**
 * UrlUtils.res - Utility for generating safe object URLs
 */
open ReBindings

let safeCreateObjectURL = (obj: 'a): string => {
  try {
    URL.createObjectURL(obj)
  } catch {
  | JsExn(e) =>
    Logger.error(
      ~module_="UrlUtils",
      ~message="OBJECT_URL_FAILED",
      ~data=Some({"error": JsExn.message(e)}),
      (),
    )
    Console.error2("Failed to create object URL:", e)
    ""
  | _ =>
    Logger.error(
      ~module_="UrlUtils",
      ~message="OBJECT_URL_FAILED",
      ~data=Some({"error": "Unknown"}),
      (),
    )
    Console.error("Failed to create object URL: Unknown error")
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
  if !String.startsWith(url, "http") {
    URL.revokeObjectURL(url)
  }
}
