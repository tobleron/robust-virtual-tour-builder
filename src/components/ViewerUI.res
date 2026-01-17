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
    <div id ?className ?style> {children->Option.getOr(React.null)} </div>
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
    <svg id ?className ?style> {children->Option.getOr(React.null)} </svg>
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
        LabelMenu.syncLabelMenu(Logger.castToJson({"label": s.label, "category": s.category}))
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
          LabelMenu.syncLabelMenu(Logger.castToJson({"label": s.label, "category": s.category}))
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

    EventBus.dispatch(
      ShowNotification(
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
      ),
    )
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
      dispatch(Actions.UpdateSceneMetadata(activeIdx, Logger.castToJson({"category": newCat})))

      EventBus.dispatch(
        ShowNotification(
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
        ),
      )
    }
  }

  let processReturnPrompt = () => {
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
        EventBus.dispatch(
          ShowNotification("Turned around! NOW click '+' to place the link.", #Success),
        )

        // Use ReBindings.Dom for manipulation
        switch ReBindings.Dom.getElementById("return-link-prompt") {
        | Nullable.Value(el) =>
          ReBindings.Dom.classList(el)->ReBindings.Dom.ClassList.remove("visible")
        | _ => ()
        }
      | None => ()
      }
    | _ => ()
    }
  }

  let handleReturnPromptClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    processReturnPrompt()
  }

  let handleReturnPromptKeyDown = e => {
    if JsxEvent.Keyboard.key(e) == "Enter" {
      JsxEvent.Keyboard.stopPropagation(e)
      processReturnPrompt()
    }
  }

  let handleFloorClick = (fid, label, e) => {
    JsxEvent.Mouse.stopPropagation(e)
    let activeIdx = state.activeIndex
    if activeIdx >= 0 {
      dispatch(Actions.UpdateSceneMetadata(activeIdx, Logger.castToJson({"floor": fid})))
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
      let utilBarClass =
        "absolute top-6 left-6 z-[5002] flex flex-col gap-2 transition-all duration-300 " ++ if (
          !scenesLoaded
        ) {
          "grayscale opacity-60 pointer-events-none"
        } else {
          ""
        }

      <div id="viewer-utility-bar" className={utilBarClass}>
        <button
          id="btn-add-link-fab"
          className="w-[32px] h-[32px] rounded-full flex items-center justify-center transition-all bg-primary text-white hover:bg-primary-light shadow-md"
          style={makeStyle({
            "backgroundColor": if state.isLinking {
              "#ffcc00"
            } else {
              "#dc3545"
            },
            "color": if state.isLinking {
              "black"
            } else {
              "white"
            },
            "fontSize": "20px",
            "fontWeight": "bold",
          })}
          onClick={handleFabClick}
          ariaLabel="Add Link"
          title="Add Link"
        >
          {React.string(
            if state.isLinking {
              "×"
            } else {
              "+"
            },
          )}
        </button>

        <button
          id="v-scene-sim-toggle"
          className="w-[32px] h-[32px] text-white rounded-full font-ui flex items-center justify-center shadow-md"
          style={makeStyle({
            "backgroundColor": if simActive {
              "#dc3545"
            } else {
              "#10b981"
            },
          })}
          onClick={handleSimClick}
          ariaLabel="Auto-Pilot"
          title={if simActive {
            "Stop Auto-Pilot"
          } else {
            "Start Auto-Pilot"
          }}
        >
          <span
            className="material-icons" style={makeStyle({"fontSize": "18px", "color": "white"})}
          >
            {React.string(
              if simActive {
                "stop"
              } else {
                "play_arrow"
              },
            )}
          </span>
        </button>

        <button
          id="v-scene-cat-toggle"
          className="w-[32px] h-[32px] text-white rounded-full flex items-center justify-center shadow-md"
          style={makeStyle({
            "backgroundColor": if state.activeIndex >= 0 {
              switch Belt.Array.get(state.scenes, state.activeIndex) {
              | Some(s) =>
                if s.categorySet {
                  if s.category == "outdoor" {
                    "#15803d"
                  } else {
                    "#c2410c"
                  }
                } else {
                  "#dc3545"
                }
              | None => "#dc3545"
              }
            } else {
              "#dc3545"
            },
          })}
          onClick={handleCatClick}
          ariaLabel="Toggle Category"
          title="Toggle Category"
        >
          <span
            className="material-icons" style={makeStyle({"fontSize": "18px", "color": "white"})}
          >
            {React.string(
              if currentCategory == "indoor" {
                "home"
              } else {
                "park"
              },
            )}
          </span>
        </button>

        <button
          id="v-scene-label-btn"
          ref={ReactDOM.Ref.domRef(labelBtnRef)}
          className="w-[32px] h-[32px] text-white rounded-full font-ui text-[18px] font-bold flex items-center justify-center relative z-[6000] pointer-events-auto shadow-md"
          style={makeStyle({"backgroundColor": "#dc3545"})}
          ariaLabel="Scene Label"
          title="Scene Label"
        >
          {React.string("#")}
        </button>
      </div>
    }

    /* HUD Labels */
    {
      let currentLabel = if state.activeIndex >= 0 {
        switch Belt.Array.get(state.scenes, state.activeIndex) {
        | Some(s) => s.label
        | None => ""
        }
      } else {
        ""
      }

      <div
        id="v-scene-persistent-label"
        className={"absolute top-8 left-1/2 -translate-x-1/2 z-[6005] bg-blue-600/80 backdrop-blur-md text-white px-3 py-1.5 rounded-2xl text-[12px] font-black uppercase shadow-2xl flex items-center justify-center transition-all duration-500 pointer-events-none border border-white/10 tracking-widest " ++ if (
          currentLabel != ""
        ) {
          "opacity-100 translate-y-0 scale-100"
        } else {
          "opacity-0 -translate-y-4 scale-90 hidden"
        }}
      >
        {React.string("#" ++ currentLabel)}
      </div>
    }

    {
      let quality = if state.activeIndex >= 0 {
        switch Belt.Array.get(state.scenes, state.activeIndex) {
        | Some(s) => s.quality
        | None => None
        }
      } else {
        None
      }

      let badges = switch quality {
      | Some(qJson) =>
        let q: SharedTypes.qualityAnalysis = Obj.magic(qJson)
        let b = []
        if q.isBlurry {
          let _ = Js.Array.push({"text": "BLURRY", "bg": "#dc2626"}, b)
        } else if q.isSoft {
          let _ = Js.Array.push({"text": "SOFT", "bg": "#d97706"}, b)
        }
        if q.isSeverelyDark {
          let _ = Js.Array.push({"text": "DARK", "bg": "#0f172a"}, b)
        } else if q.isDim {
          let _ = Js.Array.push({"text": "DIM", "bg": "#64748b"}, b)
        }
        b
      | None => []
      }

      <div
        id="v-scene-quality-indicator"
        className={"absolute top-6 right-6 z-[6005] flex items-center gap-2 pointer-events-none transition-all duration-300 " ++ if (
          Array.length(badges) > 0
        ) {
          "opacity-100 translate-x-2 scale-95"
        } else {
          "opacity-0 translate-x-4 scale-90 hidden"
        }}
      >
        {badges
        ->Belt.Array.map(b => {
          <span
            key={b["text"]}
            className="text-white text-[10px] font-bold px-2 py-0.5 rounded shadow-sm opacity-90"
            style={makeStyle({"background": b["bg"]})}
          >
            {React.string(b["text"])}
          </span>
        })
        ->React.array}
      </div>
    }

    /* Viewer Logo */
    <div
      id="viewer-logo"
      className="absolute bottom-6 right-6 z-[5002] bg-white rounded-xl shadow-xl p-[4px] flex items-center justify-center max-w-[120px] max-h-[60px] border border-black/5 overflow-hidden"
      style={makeStyle({"webkitMaskImage": "-webkit-radial-gradient(white, black)"})}
    >
      <img src="images/logo.png" alt="Logo" className="w-full h-auto object-contain block" />
    </div>

    /* Linking Hint */
    /* Linking Hint */
    <div
      id="linking-cancel-hint"
      className={"absolute bottom-10 left-1/2 -translate-x-1/2 translate-y-2 z-[9999] flex flex-col items-center gap-1 transition-all duration-400 text-center pointer-events-none " ++ if (
        state.isLinking
      ) {
        "opacity-100 translate-y-2"
      } else {
        "opacity-0 translate-y-4 hidden"
      }}
      style={makeStyle({
        "fontFamily": "var(--font-ui, 'Inter', system-ui, sans-serif)",
        "fontSize": "11px",
        "fontWeight": "800",
        "textTransform": "uppercase",
        "letterSpacing": "0.25em",
        "textShadow": "0 2px 8px rgba(0, 0, 0, 0.6)",
        "color": "white",
      })}
    >
      <span> {React.string("ESC to Cancel")} </span>
      <span style={makeStyle({"fontSize": "10px", "opacity": "0.8"})}>
        {React.string("ENTER to Finish")}
      </span>
    </div>

    /* Floor Navigation */
    /* Floor Navigation */
    {
      let scenesLoaded = Belt.Array.length(state.scenes) > 0
      let floorNavClass =
        "absolute bottom-6 left-5 z-[5002] flex flex-col-reverse gap-2 items-center transition-all duration-500" ++ if (
          !scenesLoaded
        ) {
          " grayscale opacity-60 pointer-events-none"
        } else {
          ""
        }

      <div id="viewer-floor-nav" className={floorNavClass}>
        {floorLevels
        ->Belt.Array.map(f => {
          let isSelected = f.id == currentFloor

          <div
            key={f.id}
            className={"floor-circle w-[32px] h-[32px] rounded-full border-2 border-transparent flex items-center justify-center font-ui text-[13px] font-bold cursor-pointer transition-all " ++ if (
              isSelected
            ) {
              "bg-floor-active text-white bg-primary scale-110 z-10"
            } else {
              "bg-floor-default text-white hover:text-white"
            }}
            style={makeStyle({
              "boxShadow": if isSelected {
                "0 0 12px rgba(0, 61, 165, 0.5)"
              } else {
                "1px 1px 1px #000"
              },
            })}
            onClick={e => handleFloorClick(f.id, f.label, e)}
            title={f.label}
          >
            {React.string(f.short)}
            {if f.suffix != "" {
              <sup style={makeStyle({"fontSize": "9px", "marginLeft": "1px"})}>
                {React.string(f.suffix)}
              </sup>
            } else {
              React.null
            }}
          </div>
        })
        ->React.array}
      </div>
    }

    /* Return Link Prompt */
    /* Return Link Prompt */
    <div
      id="return-link-prompt"
      className="hidden fixed bottom-24 left-1/2 -translate-x-1/2 glass-panel rounded-full px-5 py-2.5 items-center gap-3 shadow-2xl z-[4000] border border-remax-gold/20 cursor-pointer transition-all hover:scale-105 active:scale-95 animate-fade-in-centered"
      onClick={handleReturnPromptClick}
      role="button"
      tabIndex=0
      onKeyDown={handleReturnPromptKeyDown}
    >
      <div
        className="w-6 h-6 bg-remax-gold rounded-full flex items-center justify-center text-black font-black text-xs shadow-sm"
      >
        {React.string("↩")}
      </div>
      <div className="return-link-text font-ui text-[13px] font-bold text-white">
        {React.string("Add Return Link")}
      </div>
    </div>

    // Legacy Markers
    <MemoStaticDiv.make
      id="viewer-center-indicator"
      className="absolute top-1/2 left-1/2 w-3 h-3 -translate-x-1/2 -translate-y-1/2 border-2 border-remax-gold rounded-full z-[5001] pointer-events-none hidden"
    />

    <MemoStaticSvg.make
      id="viewer-hotspot-lines"
      className="absolute inset-0 w-full h-full z-[5000] pointer-events-none"
    />
  </>
}
