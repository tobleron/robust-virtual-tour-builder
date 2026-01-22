/**
 * UrlUtils.res - Utility for generating safe object URLs
 */
open ReBindings

let safeCreateObjectURL = (obj: 'a): string => {
  try {
    URL.createObjectURL(obj)
  } catch {
  | exn =>
    let (msg, stack) = Logger.getErrorDetails(exn)
    Logger.error(
      ~module_="UrlUtils",
      ~message="CREATE_URL_FAILED",
      ~data={"error": msg, "stack": stack},
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
  if !String.startsWith(url, "http") {
    URL.revokeObjectURL(url)
  }
}
