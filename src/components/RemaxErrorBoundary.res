@module("./SafeErrorBoundary.js")
external component: React.component<{
  "children": React.element,
  "onError": option<(JsExn.t, {..}) => unit>,
  "fallback": option<React.element>,
}> = "SafeErrorBoundaryComponent"

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
  React.createElement(
    component,
    {
      "children": children,
      "onError": Some(handleComponentError),
      "fallback": None,
    },
  )
}
