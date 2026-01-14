open ReBindings
open EventBus

// Helper for styles
external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = () => {
  let (activeConfig, setActiveConfig) = React.useState(_ => None)

  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | ShowModal(config) => setActiveConfig(_ => Some(config))
      | CloseModal => setActiveConfig(_ => None)
      | _ => ()
      }
    })
    Some(unsubscribe)
  })
  
  // Escape key handler
  React.useEffect1(() => {
    let handleKey = e => {
       if (Obj.magic(e)["key"] == "Escape") {
         switch activeConfig {
         | Some(config) => 
            if (Belt.Option.getWithDefault(config.allowClose, true)) {
               EventBus.dispatch(CloseModal)
            }
         | None => ()
         }
       }
    }
    let _ = Window.addEventListener("keydown", handleKey)
    Some(() => Window.removeEventListener("keydown", handleKey))
  }, [activeConfig])

  let portalTarget = Dom.getElementById("modal-container")
  
  switch (Nullable.toOption(portalTarget), activeConfig) {
  | (Some(target), Some(config)) =>
    ReactDOM.createPortal(
      <div className="modal-overlay" style={makeStyle({"display": "flex", "position": "fixed", "top": "0", "left": "0", "width": "100%", "height": "100%", "background": "rgba(0,0,0,0.7)", "backdropFilter": "blur(12px)", "zIndex": "20000", "justifyContent": "center", "alignItems": "center", "padding": "16px", "transition": "opacity 0.3s ease-in-out", "opacity": "1"})}>
         <div className="modal-box-premium" style={makeStyle({"transform": "scale(1)", "transition": "all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)", "width": "100%", "maxWidth": "340px"})}>
             // Icon
             {switch config.icon {
              | Some(icon) =>
                  <div style={makeStyle({"textAlign": "center", "marginBottom": "16px"})}>
                      <span className="material-icons" style={makeStyle({"fontSize": "40px", "color": "#fbbf24", "filter": "drop-shadow(0 0 12px rgba(251, 191, 36, 0.4))"})}>{React.string(icon)}</span>
                  </div>
              | None => React.null
             }}
             // Title
             <h3 style={makeStyle({"margin": "0 0 4px 0", "fontSize": "20px", "fontWeight": "800", "letterSpacing": "-0.02em", "textAlign": "center", "color": "white"})}>{React.string(config.title)}</h3>
             // Description
             {switch config.description {
             | Some(desc) => <p style={makeStyle({"fontSize": "13px", "color": "rgba(255,255,255,0.6)", "marginBottom": "20px", "textAlign": "center"})}>{React.string(desc)}</p>
             | None => React.null
             }}
             // Content Html
             {switch config.contentHtml {
             | Some(html) => <div className="modal-content-body" dangerouslySetInnerHTML={"__html": html} />
             | None => React.null
             }}
             // Buttons
             <div className="modal-actions" style={makeStyle({"display": "flex", "flexDirection": "column", "gap": "10px", "marginTop": "20px"})}>
                {config.buttons->Belt.Array.mapWithIndex((i, btn) => {
                   <button key={Belt.Int.toString(i)} className={`modal-btn-premium ${btn.class_}`} style={makeStyle({"width": "100%"})} onClick={_ => {
                      btn.onClick()
                      if (Belt.Option.getWithDefault(btn.autoClose, true)) {
                        EventBus.dispatch(CloseModal)
                      }
                   }}>
                      <span>{React.string(btn.label)}</span>
                   </button>
                })->React.array}
             </div>
         </div>
      </div>,
      (Obj.magic(target))
    )
  | _ => React.null
  }
}
