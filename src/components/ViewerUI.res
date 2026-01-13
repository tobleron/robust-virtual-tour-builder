/* src/components/ViewerUI.res */

// Do not open ReBindings globally to avoid Dom conflict
// open ReBindings 
open Navigation

module SimulationSystem = {
  @module("../systems/SimulationSystem.bs.js")
  external startAutoPilot: unit => unit = "startAutoPilot"
  @module("../systems/SimulationSystem.bs.js")
  external stopAutoPilot: bool => unit = "stopAutoPilot"
  @module("../systems/SimulationSystem.bs.js")
  external isAutoPilotActive: unit => bool = "isAutoPilotActive"
}

module LabelMenu = {
  // Uses standard Dom.element because it comes from a React ref
  @module("./LabelMenu.js")
  external toggleLabelMenu: Dom.element => unit = "toggleLabelMenu"
}

// Floor Levels
type floorLevel = {
  id: string,
  label: string,
  short: string,
  suffix: string
}

let floorLevels = [
  {id: "b2", label: "Basement 2", short: "B", suffix: "-2"},
  {id: "b1", label: "Basement 1", short: "B", suffix: "-1"},
  {id: "ground", label: "Ground Floor", short: "G", suffix: ""},
  {id: "first", label: "First Floor", short: "+1", suffix: ""},
  {id: "second", label: "Second Floor", short: "+2", suffix: ""},
  {id: "third", label: "Third Floor", short: "+3", suffix: ""},
  {id: "fourth", label: "Fourth Floor", short: "+4", suffix: ""},
  {id: "roof", label: "Roof Top", short: "R", suffix: ""},
]

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

module StaticDiv = {
  @react.component
  let make = (~id, ~className=?, ~style=?, ~children=?) => {
    <div id ?className ?style>{children->Belt.Option.getWithDefault(React.null)}</div>
  }
}



@module("react")
external memoCustom: (
  React.component<'props>,
  ('props, 'props) => bool
) => React.component<'props> = "memo"

// Memoize with 'true' to never re-render after mount
let staticDivComp = memoCustom(StaticDiv.make, (_, _) => true)
module MemoStaticDiv = {
  let make = staticDivComp
}

module StaticSvg = {
  @react.component
  let make = (~id, ~style) => {
    <svg id style />
  }
}
let staticSvgComp = memoCustom(StaticSvg.make, (_, _) => true)
module MemoStaticSvg = {
  let make = staticSvgComp
}

@react.component
let make = () => {
  let (_tick, setTick) = React.useState(_ => 0)
  let state = Store.store.state
  let (simActive, setSimActive) = React.useState(_ => SimulationSystem.isAutoPilotActive())
  
  // Standard Dom.element ref
  let labelBtnRef = React.useRef(Nullable.null)

  React.useEffect0(() => {
    let _unsubscribe = Store.store.subscribe(_ => {
        setTick(t => t + 1)
        setSimActive(_ => SimulationSystem.isAutoPilotActive())
    })
    Some(() => ()) // Store uses a simple array push, no easy unsubscribe yet but this is fine for now
  })

  // Handlers
  let handleFabClick = (e) => {
       JsxEvent.Mouse.stopPropagation(e)
       Store.store.state.isLinking = !state.isLinking
       Store.store.notify()
       ReBindings.Notification.notify(
           if state.isLinking { "Link Mode: ACTIVE" } else { "Link Mode: OFF" },
           if state.isLinking { "success" } else { "warning" }
       )
  }

  let handleSimClick = (e) => {
       JsxEvent.Mouse.stopPropagation(e)
       if SimulationSystem.isAutoPilotActive() {
           SimulationSystem.stopAutoPilot(true)
       } else {
           SimulationSystem.startAutoPilot()
       }
       setSimActive(_ => !simActive)
  }

  let handleCatClick = (e) => {
       JsxEvent.Mouse.stopPropagation(e)
       let activeIdx = state.activeIndex
       if activeIdx >= 0 {
           let scenes = state.scenes
           let current = switch Belt.Array.get(scenes, activeIdx) {
           | Some(s) => if s.category == "" { "indoor" } else { s.category }
           | None => "indoor"
           }
            let newCat = if current == "indoor" { "outdoor" } else { "indoor" }
            Store.store.updateSceneMetadata(activeIdx, (Obj.magic({"category": newCat})))
            ReBindings.Notification.notify(
                if newCat == "indoor" { "Category: INDOOR" } else { "Category: OUTDOOR" },
                if newCat == "indoor" { "warning" } else { "success" }
            )
       }
  }

  let handleLabelClick = (e) => {
     JsxEvent.Mouse.stopPropagation(e)
     switch Nullable.toOption(labelBtnRef.current) {
     | Some(el) => LabelMenu.toggleLabelMenu(el)
     | None => ()
     }
  }

  let handleReturnPromptClick = (e) => {
      JsxEvent.Mouse.stopPropagation(e)
      let v = Nullable.toOption(ReBindings.Viewer.instance)
      let incoming = Navigation.getIncomingLink()
      
      switch (v, incoming) {
      | (Some(viewer), Some(inc)) =>
          let prevScene = Belt.Array.get(state.scenes, inc.sceneIndex)
          switch prevScene {
          | Some(scene) =>
              let currentYaw = ReBindings.Viewer.getYaw(viewer)
              ReBindings.Viewer.setYawWithDuration(viewer, currentYaw +. 180.0, 1000)
              Navigation.setPendingReturnSceneName(Some(scene.name))
              ReBindings.Notification.notify("Turned around! NOW click '+' to place the link.", "success")
              
              // Use ReBindings.Dom for manipulation
              switch ReBindings.Dom.getElementById("return-link-prompt") {
              | Nullable.Value(el) => ReBindings.Dom.classList(el)["remove"]("visible")
              | _ => ()
              }
          | None => ()
          }
      | _ => ()
      }
  }

  let handleFloorClick = (fid, label, e) => {
      JsxEvent.Mouse.stopPropagation(e)
      let activeIdx = state.activeIndex
      if activeIdx >= 0 {
          Store.store.updateSceneMetadata(activeIdx, (Obj.magic({"floor": fid})))
          ReBindings.Notification.notify("Floor: " ++ label, "success")
      }
  }

  // Derived state for display
  let currentCategory = 
    if state.activeIndex >= 0 {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(s) => if s.category == "" { "indoor" } else { s.category }
      | None => "indoor"
      }
    } else { "indoor" }

  let currentFloor = 
    if state.activeIndex >= 0 {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(s) => if s.floor == "" { "ground" } else { s.floor }
      | None => "ground"
      }
    } else { "" }

  // Render
  <>
// Static Elements managed by JS
    // Static Elements managed by JS
    <MemoStaticDiv.make id="viewer-snapshot-overlay" className="absolute inset-0 bg-center bg-no-repeat z-[5000] pointer-events-none opacity-0 transition-opacity duration-300 ease-in-out" />
    
    // Logic for disabling buttons
    {
      let scenesLoaded = Belt.Array.length(state.scenes) > 0
      let viewerBarClass = "absolute top-6 left-5 z-[5002] flex flex-col gap-2 items-start bg-transparent" ++ (if !scenesLoaded { " opacity-50 pointer-events-none grayscale" } else { "" })
      
      <div id="viewer-utility-bar" className={viewerBarClass}>
        <button id="btn-add-link-fab" 
                className="w-[32px] h-[32px] text-white rounded-full font-ui text-[20px] font-bold flex items-center justify-center btn-viewer-pop leading-none pb-0.5"
                style={makeStyle({"backgroundColor": if state.isLinking { "#ffcc00" } else { "#dc3545" }, "color": if state.isLinking { "black" } else { "white" }})}
                onClick={handleFabClick}
                disabled={!scenesLoaded}
                title="Add Link: Create a transition to another scene">
             {React.string("+")}
        </button>

        <button id="v-scene-sim-toggle"
                className="w-[32px] h-[32px] text-white rounded-full font-ui flex items-center justify-center btn-viewer-pop"
                style={makeStyle({
                    "backgroundColor": if simActive { "#dc3545" } else { "#10b981" }
                })}
                onClick={handleSimClick}
                disabled={!scenesLoaded}
                title={if simActive { "Stop Auto-Pilot Simulation" } else { "Start Auto-Pilot Simulation" }}>
             <span className="material-icons" style={makeStyle({"fontSize": "18px", "color": "white"})}>
                {React.string(if simActive { "stop" } else { "play_arrow" })}
             </span>
        </button>

        <button id="v-scene-cat-toggle"
                className="w-[32px] h-[32px] text-white rounded-full flex items-center justify-center btn-viewer-pop"
                style={makeStyle({
                    "backgroundColor": 
                        if state.activeIndex >= 0 {
                            switch Belt.Array.get(state.scenes, state.activeIndex) {
                            | Some(s) => 
                                if s.categorySet {
                                     if s.category == "outdoor" { "#15803d" } else { "#c2410c" }
                                } else {
                                     "#dc3545"
                                }
                            | None => "#dc3545"
                            }
                        } else { "#dc3545" }
                })}
                onClick={handleCatClick}
                disabled={!scenesLoaded}
                title="Toggle Category: Indoor vs Outdoor">
              <span className="material-icons" style={makeStyle({"fontSize": "18px", "color": "white"})}>
                  {React.string(if currentCategory == "indoor" { "home" } else { "park" })} 
              </span>
        </button>

        <button id="v-scene-label-btn"
                ref={ReactDOM.Ref.domRef(labelBtnRef)}
                className="w-[32px] h-[32px] text-white rounded-full font-ui text-[18px] font-bold flex items-center justify-center btn-viewer-pop relative z-[6000] pointer-events-auto"
                style={makeStyle({"backgroundColor": "#dc3545"})}
                onClick={handleLabelClick}
                disabled={!scenesLoaded}
                title="Scene Label: Tag this scene (e.g., Living Room)">
             {React.string("#")}
        </button>
    </div>
    }

    <div id="v-scene-persistent-label" className="hidden absolute top-6 left-1/2 -translate-x-1/2 z-[6005] text-white px-3 py-0.5 rounded-md text-[12px] font-black uppercase shadow-lg items-center justify-center transition-all duration-300 pointer-events-none border border-white/20 opacity-0 -translate-y-2 scale-95 tracking-wider"
         style={makeStyle({"backgroundColor": "#2563eb"})}></div>

    <div id="v-scene-quality-indicator" className="hidden absolute top-6 right-6 z-[6005] flex items-center gap-2 pointer-events-none transition-all duration-300 opacity-0 translate-x-2 scale-95"></div>
    
    <div id="viewer-logo" 
         className="absolute bottom-6 right-6 z-[5002] bg-white rounded-xl shadow-xl p-[4px] flex items-center justify-center max-w-[120px] max-h-[60px] border border-black/5 overflow-hidden"
         style={makeStyle({"WebkitMaskImage": "-webkit-radial-gradient(white, black)"})}>
         <img src="images/logo.png" alt="Logo" className="w-full h-auto object-contain block" />
    </div>

    <div id="linking-cancel-hint" 
         style={makeStyle({
             "position": "absolute",
             "bottom": "40px", 
             "left": "50%",
             "transform": "translateX(-50%) translateY(8px)",
             "zIndex": "9999",
             "color": "white",
             "fontFamily": "var(--font-ui, 'Inter', system-ui, sans-serif)",
             "fontSize": "11px",
             "fontWeight": "800",
             "textTransform": "uppercase",
             "letterSpacing": "0.25em",
             "opacity": if state.isLinking { "1" } else { "0" },
             "pointerEvents": "none",
             "transition": "opacity 0.4s ease, transform 0.4s ease",
             "textShadow": "0 2px 8px rgba(0, 0, 0, 0.6)",
             "whiteSpace": "nowrap",
             "textAlign": "center"
         })}>
         {React.string("ESC to Cancel")}
         <br/>
         <span style={makeStyle({"fontSize": "10px", "opacity": "0.8"})}>{React.string("ENTER to Finish")}</span>
    </div>

{
    let scenesLoaded = Belt.Array.length(state.scenes) > 0
    let floorNavClass = "absolute bottom-6 left-5 z-[5002] flex flex-col-reverse gap-2 items-center" ++ (if !scenesLoaded { " opacity-50 pointer-events-none grayscale" } else { "" })

    <div id="viewer-floor-nav" className={floorNavClass}>
        {floorLevels->Belt.Array.map(f => {
            let isSelected = f.id == currentFloor
            let className = if isSelected { 
                "floor-circle w-[32px] h-[32px] rounded-full flex items-center justify-center font-ui text-[13px] font-bold text-white cursor-pointer transition-all scale-110 z-10"
            } else {
                "floor-circle w-[32px] h-[32px] rounded-full border-2 border-transparent flex items-center justify-center font-ui text-[13px] font-bold text-white cursor-pointer transition-all hover:border-[#ffcc00]"
            }

            <div key={f.id}
                 className={className}
                 style={makeStyle({
                    "backgroundColor": if isSelected { "#003da5" } else { "#001a4d" },
                    "border": if isSelected { "2px solid #ffcc00" } else { "2px solid transparent" },
                    "boxShadow": if isSelected { "0 0 12px rgba(0, 61, 165, 0.5)" } else { "1px 1px 1px #000" }
                 })}
                 title={f.label}
                 onClick={e => handleFloorClick(f.id, f.label, e)}>
                 {
                     if f.suffix != "" {
                         <>
                            {React.string(f.short)}
                            <sup style={makeStyle({"fontSize": "10px", "marginLeft": "1px"})}>{React.string(f.suffix)}</sup>
                         </>
                     } else {
                         React.string(f.short)
                     }
                 }
            </div>
        })->React.array}
    </div>
}

    <div id="return-link-prompt" 
         className="hidden fixed bottom-24 left-1/2 -translate-x-1/2 glass-panel rounded-full px-5 py-2.5 items-center gap-3 shadow-2xl z-[4000] border border-remax-gold/20 cursor-pointer transition-all hover:scale-105 active:scale-95 animate-fade-in-centered"
         onClick={handleReturnPromptClick}>
         <div className="w-6 h-6 bg-remax-gold rounded-full flex items-center justify-center text-black font-black text-xs shadow-sm">{React.string("↩")}</div>
         <div className="return-link-text font-ui text-[13px] font-bold text-white">{React.string("Add Return Link")}</div>
    </div>
    
    <MemoStaticDiv.make 
        id="viewer-center-indicator"
        style={makeStyle({
             "position": "absolute",
            "top": "50%",
            "left": "50%",
            "width": "10px",
            "height": "10px",
            "backgroundColor": "white",
            "border": "2px solid #ff0000",
            "borderRadius": "50%",
            "transform": "translate(-50%, -50%)",
            "zIndex": "5001",
            "pointerEvents": "none",
            "display": "none"
         })} 
    />

    <MemoStaticSvg.make 
        id="viewer-hotspot-lines"
        style={makeStyle({
            "position": "absolute",
            "inset": "0",
            "width": "100%",
            "height": "100%",
            "zIndex": "5000",
            "pointerEvents": "none"
         })}
    />
  </>
}
