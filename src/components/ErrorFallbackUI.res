open ReBindings

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = (~onReload=?) => {
  let handleReload = _ => {
    switch onReload {
    | Some(fn) => fn()
    | None => {
        Window.reloadLocation()
      }
    }
  }

  <div className="error-fallback-container">
    <div className="error-fallback-card">
      <h1 className="error-fallback-title"> {React.string("Application Error")} </h1>
      <p className="error-fallback-message">
        {React.string(
          "An unexpected error occurred during rendering. The application has been halted to prevent data corruption.",
        )}
      </p>
      <button onClick={handleReload} className="error-fallback-btn">
        {React.string("Reload Application")}
      </button>
    </div>
  </div>
}
