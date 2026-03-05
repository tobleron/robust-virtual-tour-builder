type internal_props = {
  "children": React.element,
  "onError": option<(JsExn.t, JSON.t) => unit>,
  "fallback": option<React.element>,
}

@val external internal_component: React.component<internal_props> = "SafeErrorBoundaryInternal"

let _ = ErrorFallbackUI.make

%%raw(`
class SafeErrorBoundaryInternal extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true };
    }

    componentDidCatch(error, errorInfo) {
        if (this.props.onError) {
            try {
                this.props.onError(error, errorInfo);
            } catch (e) {
                Logger.error('SafeErrorBoundary', 'onError_HANDLER_FAILED', { error: e }, undefined);
            }
        }
    }

    render() {
        if (this.state.hasError) {
            if (this.props.fallback) {
                return this.props.fallback;
            }
            return React.createElement(ErrorFallbackUI.make, {});
        }

        return this.props.children;
    }
}
`)

let handleComponentError = (~featureName: string, error: JsExn.t, _errorInfo: JSON.t) => {
  let message = switch JsExn.message(error) {
  | Some(msg) => msg
  | None => "Unknown render error"
  }
  let stack = JsExn.stack(error)->Option.getOr("")
  Logger.error(
    ~module_="ErrorBoundary",
    ~message="FEATURE_CRASH",
    ~data=Logger.castToJson({
      "feature": featureName,
      "error": message,
      "stack": stack,
    }),
    (),
  )
}

@react.component
let make = (~children, ~featureName="App", ~fallback: option<React.element>=?) => {
  React.createElement(
    internal_component,
    {
      "children": children,
      "onError": Some((error, info) => handleComponentError(~featureName, error, info)),
      "fallback": fallback,
    },
  )
}
