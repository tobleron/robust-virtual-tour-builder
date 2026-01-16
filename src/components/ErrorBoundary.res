@module("./ErrorBoundary.js")
external make: (
  ~children: React.element,
  ~onError: (JsExn.t, {..}) => unit=?,
  ~fallback: React.element=?,
) => React.element = "default"

let handleComponentError = (error, _errorInfo) => {
  Logger.error(
    ~module_="ErrorBoundary",
    ~message=switch JsExn.message(error) {
    | Some(msg) => msg
    | None => "Unknown render error"
    },
    ~data=error,
    (),
  )
}

@react.component
let make = (~children) => {
  make(~children, ~onError=handleComponentError)
}
