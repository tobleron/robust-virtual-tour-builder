external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = () => {
  <div
    style={makeStyle({
      "position": "fixed",
      "inset": "0",
      "display": "flex",
      "flexDirection": "column",
      "alignItems": "center",
      "justifyContent": "center",
      "backgroundColor": "#0f172a",
      "color": "#f8fafc",
      "padding": "2rem",
      "textAlign": "center",
      "zIndex": "9999",
      "fontFamily": "system-ui, -apple-system, sans-serif",
    })}
  >
    <div
      style={makeStyle({
        "maxWidth": "28rem",
        "padding": "2.5rem",
        "borderRadius": "1.5rem",
        "backgroundColor": "rgba(30, 41, 59, 0.5)",
        "backdropFilter": "blur(12px)",
        "border": "1px solid #334155",
        "boxShadow": "0 25px 50px -12px rgba(0, 0, 0, 0.5)",
      })}
    >
      <h1
        style={makeStyle({
          "fontSize": "1.875rem",
          "fontWeight": "700",
          "marginBottom": "0.75rem",
          "letterSpacing": "-0.025em",
        })}
      >
        {React.string("Application Error")}
      </h1>
      <p style={makeStyle({"color": "#94a3b8", "marginBottom": "2rem", "lineHeight": "1.6"})}>
        {React.string(
          "An unexpected error occurred during rendering. The application has been halted to prevent data corruption.",
        )}
      </p>
      <button
        onClick={_ => {
          let _ = %raw("window.location.reload()")
        }}
        style={makeStyle({
          "width": "100%",
          "backgroundColor": "#2563eb",
          "color": "white",
          "fontWeight": "600",
          "padding": "0.875rem 1.5rem",
          "borderRadius": "0.75rem",
          "border": "none",
          "cursor": "pointer",
          "transition": "background-color 0.2s",
        })}
      >
        {React.string("Reload Application")}
      </button>
    </div>
  </div>
}
