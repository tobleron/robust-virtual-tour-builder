/* src/components/ViewerUI.res */

// Do not open ReBindings globally to avoid Dom conflict
// open ReBindings
open EventBus

module SimulationSystem = {
  @module("../systems/SimulationSystem.bs.js")
  external startAutoPilot: unit => unit = "startAutoPilot"
  @module("../systems/SimulationSystem.bs.js")
  external stopAutoPilot: bool => unit = "stopAutoPilot"
  @module("../systems/SimulationSystem.bs.js")
  external isAutoPilotActive: unit => bool = "isAutoPilotActive"
}

module LabelMenu = {
  @module("./LabelMenu.bs.js")
  external toggleLabelMenu: Dom.element => unit = "toggleLabelMenu"
  @module("./LabelMenu.bs.js")
  external createLabelMenu: (Nullable.t<Dom.element>, Dom.element) => unit = "createLabelMenu"
  @module("./LabelMenu.bs.js")
  external syncLabelMenu: 'a => unit = "syncLabelMenu"
}

// Floor Levels
type floorLevel = {
  id: string,
  label: string,
  short: string,
  suffix: string,
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
    <div id ?className ?style> {children->Belt.Option.getWithDefault(React.null)} </div>
  }
}

@module("react")
external memoCustom: (
  React.component<'props>,
  ('props, 'props) => bool,
) => React.component<'props> = "memo"

// Memoize with 'true' to never re-render after mount
let staticDivComp = memoCustom(StaticDiv.make, (_, _) => true)
module MemoStaticDiv = {
  let make = staticDivComp
}

module StaticSvg = {
  @react.component
  let make = (~id, ~className=?, ~style=?, ~children=?) => {
    <svg id ?className ?style> {children->Belt.Option.getWithDefault(React.null)} </svg>
  }
}
let staticSvgComp = memoCustom(StaticSvg.make, (_, _) => true)
module MemoStaticSvg = {
  let make = staticSvgComp
}

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let (simActive, setSimActive) = React.useState(_ => SimulationSystem.isAutoPilotActive())

  // Standard Dom.element ref
  let labelBtnRef = React.useRef(Nullable.null)

  // Sync Label Menu when activeIndex changes
  React.useEffect1(() => {
    if state.activeIndex >= 0 {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(s) =>
        let jsScene = Obj.magic({"label": s.label, "category": s.category})
        LabelMenu.syncLabelMenu(jsScene)
      | None => ()
      }
    }
    None
  }, [state.activeIndex])

  // Poll for simulation status (or we could dispatch actions when simulation changes, assuming simulation updates store)
  // For now, keep simple interval check or verify if store triggers.
  // SimulationSystem is likely external.
  // We can use an effect with interval or hook into navigation updates if possible.
  // Original code updated on store subscription. Store had notify() called often?
  // Let's rely on re-renders for now, but simulation state might need polling if it doesn't dispatch.
  React.useEffect0(() => {
    let interval = setInterval(() => {
      setSimActive(_ => SimulationSystem.isAutoPilotActive())
    }, 500)
    Some(() => clearInterval(interval))
  })

  React.useEffect0(() => {
    // Initialize Label Menu if ref exists
    switch Nullable.toOption(labelBtnRef.current) {
    | Some(el) =>
      LabelMenu.createLabelMenu(Nullable.null, el)

      // Initial Sync
      if state.activeIndex >= 0 {
        switch Belt.Array.get(state.scenes, state.activeIndex) {
        | Some(s) =>
          let jsScene = Obj.magic({"label": s.label, "category": s.category})
          LabelMenu.syncLabelMenu(jsScene)
        | None => ()
        }
      }
    | None => ()
    }
    None
  })

  // Handlers
  let handleFabClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    let newLinking = !state.isLinking
    dispatch(Actions.SetIsLinking(newLinking))

    EventBus.dispatch(ShowNotification(
      if newLinking {
        "Link Mode: ACTIVE"
      } else {
        "Link Mode: OFF"
      },
      if newLinking {
        #Success
      } else {
        #Warning
      },
    ))
  }

  let handleSimClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    if SimulationSystem.isAutoPilotActive() {
      SimulationSystem.stopAutoPilot(true)
    } else {
      SimulationSystem.startAutoPilot()
    }
    setSimActive(_ => !simActive)
  }

  let handleCatClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    let activeIdx = state.activeIndex
    if activeIdx >= 0 {
      let scenes = state.scenes
      let current = switch Belt.Array.get(scenes, activeIdx) {
      | Some(s) =>
        if s.category == "" {
          "indoor"
        } else {
          s.category
        }
      | None => "indoor"
      }
      let newCat = if current == "indoor" {
        "outdoor"
      } else {
        "indoor"
      }
      // Store.store.updateSceneMetadata(activeIdx, Obj.magic({"category": newCat}))
      dispatch(Actions.UpdateSceneMetadata(activeIdx, Obj.magic({"category": newCat})))

      EventBus.dispatch(ShowNotification(
        if newCat == "indoor" {
          "Category: INDOOR"
        } else {
          "Category: OUTDOOR"
        },
        if newCat == "indoor" {
          #Warning
        } else {
          #Success
        },
      ))
    }
  }

  let handleReturnPromptClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    let v = Nullable.toOption(ReBindings.Viewer.instance)
    let incoming = state.incomingLink

    switch (v, incoming) {
    | (Some(viewer), Some(inc)) =>
      let prevScene = Belt.Array.get(state.scenes, inc.sceneIndex)
      switch prevScene {
      | Some(scene) =>
        let currentYaw = ReBindings.Viewer.getYaw(viewer)
        ReBindings.Viewer.setYawWithDuration(viewer, currentYaw +. 180.0, 1000)
        dispatch(Actions.SetPendingReturnSceneName(Some(scene.name)))
        EventBus.dispatch(ShowNotification("Turned around! NOW click '+' to place the link.", #Success))

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
      dispatch(Actions.UpdateSceneMetadata(activeIdx, Obj.magic({"floor": fid})))
      EventBus.dispatch(ShowNotification("Floor: " ++ label, #Success))
    }
  }

  // Derived state for display
  let currentCategory = if state.activeIndex >= 0 {
    switch Belt.Array.get(state.scenes, state.activeIndex) {
    | Some(s) =>
      if s.category == "" {
        "indoor"
      } else {
        s.category
      }
    | None => "indoor"
    }
  } else {
    "indoor"
  }

  let currentFloor = if state.activeIndex >= 0 {
    switch Belt.Array.get(state.scenes, state.activeIndex) {
    | Some(s) =>
      if s.floor == "" {
        "ground"
      } else {
        s.floor
      }
    | None => "ground"
    }
  } else {
    ""
  }

  // Render
  <>
    // Static Elements managed by JS
    <MemoStaticDiv.make
      id="viewer-snapshot-overlay"
      className="absolute inset-0 bg-center bg-no-repeat z-[5000] pointer-events-none opacity-0 transition-opacity duration-300 ease-in-out"
    />

    {
      let scenesLoaded = Belt.Array.length(state.scenes) > 0
      let viewerBarClass =
        "absolute top-6 left-6 z-[5002] flex flex-col gap-4 items-start bg-transparent transition-all duration-500" ++ if (
          !scenesLoaded
        ) {
          " opacity-0 pointer-events-none -translate-x-4"
        } else {
          " opacity-100 translate-x-0"
        }

      <div id="viewer-utility-bar" className={viewerBarClass}>
        /* Main Action Strip */
        <div className="flex flex-col gap-3 p-1.5 premium-glass rounded-2xl border border-white/10 shadow-2xl backdrop-blur-xl">
          <button
            id="btn-add-link-fab"
            className={"app-btn-icon w-10 h-10 rounded-xl flex items-center justify-center transition-all active:scale-95 group relative focus-visible:ring-2 focus-visible:ring-white/50 focus-visible:outline-none " ++ (
              if state.isLinking { "bg-warning text-slate-900 shadow-lg shadow-warning/20" } else { "bg-primary text-white hover:bg-primary-light" }
            )}
            onClick={handleFabClick}
            ariaLabel="Add Link"
          >
            <span className="material-icons text-xl" ariaHidden=true> 
              {React.string(state.isLinking ? "close" : "add")} 
            </span>
            {if state.isLinking {
              <div className="absolute -right-1 -top-1 w-3 h-3 bg-white rounded-full animate-ping" />
            } else { React.null }}
          </button>

          <button
            id="v-scene-sim-toggle"
            className={"app-btn-icon w-10 h-10 rounded-xl flex items-center justify-center transition-all active:scale-95 focus-visible:ring-2 focus-visible:ring-white/50 focus-visible:outline-none " ++ (
              if simActive { "bg-danger text-white hover:bg-danger-light" } else { "bg-slate-800/50 text-white/70 hover:bg-slate-700 hover:text-white" }
            )}
            onClick={handleSimClick}
            ariaLabel="Auto-Pilot"
          >
            <span className="material-icons text-xl" ariaHidden=true>
              {React.string(if simActive { "stop" } else { "play_arrow" })}
            </span>
          </button>

          <div className="h-px bg-white/10 mx-2" />

          <button
            id="v-scene-cat-toggle"
            className={"app-btn-icon w-10 h-10 rounded-xl flex items-center justify-center transition-all active:scale-95 bg-slate-800/50 text-white/70 hover:bg-slate-700 hover:text-white focus-visible:ring-2 focus-visible:ring-white/50 focus-visible:outline-none"}
            onClick={handleCatClick}
            ariaLabel="Toggle Category"
          >
            <span className="material-icons text-xl" ariaHidden=true>
              {React.string(if currentCategory == "indoor" { "home" } else { "park" })}
            </span>
          </button>

          <button
            id="v-scene-label-btn"
            ref={ReactDOM.Ref.domRef(labelBtnRef)}
            className="app-btn-icon w-10 h-10 rounded-xl bg-slate-800/50 text-white/70 hover:bg-slate-700 hover:text-white flex items-center justify-center transition-all active:scale-95 focus-visible:ring-2 focus-visible:ring-white/50 focus-visible:outline-none"
            ariaLabel="Scene Label"
          >
            <span className="material-icons text-xl" ariaHidden=true> {React.string("label_important")} </span>
          </button>
        </div>
      </div>
    }

    /* HUD Labels */
    <div
      id="v-scene-persistent-label"
      className="hidden absolute top-8 left-1/2 -translate-x-1/2 z-[6005] bg-slate-950/80 backdrop-blur-md text-white px-5 py-2 rounded-2xl text-[12px] font-black uppercase shadow-2xl items-center justify-center transition-all duration-500 pointer-events-none border border-white/10 opacity-0 -translate-y-4 tracking-widest scale-90"
    >
    </div>

    <div
      id="v-scene-quality-indicator"
      className="hidden absolute top-8 right-8 z-[6005] flex items-center gap-3 pointer-events-none transition-all duration-500 opacity-0 translate-x-4 scale-90"
    >
    </div>

    /* Viewer Logo */
    <div
      id="viewer-logo"
      className="absolute bottom-6 right-6 z-[5002] premium-glass rounded-2xl p-2 flex items-center justify-center max-w-[140px] border border-white/10 shadow-2xl hover:scale-105 transition-transform duration-300"
    >
      <img src="images/logo.png" alt="Remax Virtual Tour Builder Logo" className="w-full h-auto object-contain block opacity-90" />
    </div>

    /* Linking Hint */
    <div
      id="linking-cancel-hint"
      className={"absolute bottom-32 left-1/2 -translate-x-1/2 z-[6010] flex flex-col items-center gap-2 transition-all duration-500 " ++ (
        if state.isLinking { "opacity-100 translate-y-0" } else { "opacity-0 translate-y-4" }
      )}
    >
      <div className="px-6 py-2 premium-glass rounded-full border border-warning/30 shadow-xl shadow-warning/10">
        <span className="text-[11px] font-black text-warning uppercase tracking-[0.2em] animate-pulse">
          {React.string("Linking Active")}
        </span>
      </div>
      <div className="flex gap-4 text-[9px] font-bold text-white/40 uppercase tracking-widest bg-slate-950/40 backdrop-blur-sm px-4 py-1.5 rounded-full border border-white/5">
        <span className="flex items-center gap-1.5">
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 text-white/80"> {React.string("ESC")} </kbd>
          {React.string("Cancel")}
        </span>
        <span className="flex items-center gap-1.5">
          <kbd className="px-1.5 py-0.5 rounded bg-white/10 text-white/80"> {React.string("ENTER")} </kbd>
          {React.string("Finish")}
        </span>
      </div>
    </div>

    /* Floor Navigation */
    {
      let scenesLoaded = Belt.Array.length(state.scenes) > 0
      let floorNavClass =
        "absolute bottom-6 left-6 z-[5002] flex flex-col-reverse gap-3 items-center transition-all duration-500" ++ if (
          !scenesLoaded
        ) {
          " opacity-0 pointer-events-none translate-y-4"
        } else {
          " opacity-100 translate-y-0"
        }

      <div id="viewer-floor-nav" className={floorNavClass}>
        <div className="flex flex-col-reverse gap-2 p-1.5 premium-glass rounded-2xl border border-white/10 shadow-2xl">
          {floorLevels
          ->Belt.Array.map(f => {
            let isSelected = f.id == currentFloor
            
            <button
              key={f.id}
              className={"w-10 h-10 rounded-xl flex flex-col items-center justify-center transition-all hover:scale-105 active:scale-90 focus-visible:ring-2 focus-visible:ring-white/50 focus-visible:outline-none " ++ (
                if isSelected {
                  "bg-primary text-white shadow-lg shadow-primary/20 scale-110 z-10 border border-white/20"
                } else {
                  "hover:bg-white/10 text-white/60 hover:text-white"
                }
              )}
              onClick={e => handleFloorClick(f.id, f.label, e)}
              ariaLabel={f.label}
            >
              <span className="text-[13px] font-black tracking-tighter relative">
                {React.string(f.short)}
                {if f.suffix != "" {
                  <sup className="text-[8px] opacity-70 ml-0.5"> {React.string(f.suffix)} </sup>
                } else { React.null }}
              </span>
            </button>
          })
          ->React.array}
        </div>
      </div>
    }

    /* Return Link Prompt */
    <div
      id="return-link-prompt"
      className="hidden absolute bottom-32 left-1/2 -translate-x-1/2 premium-glass rounded-full pl-2 pr-6 py-2 items-center gap-4 shadow-2xl z-[4000] border border-primary/30 cursor-pointer transition-all hover:scale-105 active:scale-95 animate-fade-in group"
      onClick={handleReturnPromptClick}
      role="button"
      tabIndex=0
      onKeyDown={e => {
        if JsxEvent.Keyboard.key(e) == "Enter" {
          handleReturnPromptClick(Obj.magic(e))
        }
      }}
    >
      <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center text-white shadow-lg shadow-primary/20 group-hover:rotate-[-45deg] transition-transform duration-500">
        <span className="material-icons text-xl"> {React.string("reply")} </span>
      </div>
      <div className="flex flex-col">
        <span className="text-[12px] font-black text-white uppercase tracking-widest">
          {React.string("Add Return Link")}
        </span>
        <span className="text-[9px] font-bold text-primary-light uppercase tracking-tighter opacity-70">
          {React.string("Quick link back to previous scene")}
        </span>
      </div>
    </div>

    // Legacy Markers
    <MemoStaticDiv.make
      id="viewer-center-indicator"
      className="absolute top-1/2 left-1/2 w-3 h-3 -translate-x-1/2 -translate-y-1/2 border-2 border-danger rounded-full z-[5001] pointer-events-none hidden"
    />

    <MemoStaticSvg.make
      id="viewer-hotspot-lines"
      className="absolute inset-0 w-full h-full z-[5000] pointer-events-none"
    />
  </>
}
