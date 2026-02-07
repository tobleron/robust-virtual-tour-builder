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
