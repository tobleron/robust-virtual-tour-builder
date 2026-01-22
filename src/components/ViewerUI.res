/* src/components/ViewerUI.res */

// Do not open ReBindings globally to avoid Dom conflict
// open ReBindings
open EventBus

// Removed SimulationSystem direct binding
// module SimulationSystem = ...

// Obsolete legacy bindings removed

// Floor Levels

// Floor Levels
type floorLevel = {
  id: string,
  label: string,
  short: string,
  suffix: string,
}

type hotspotMenuInfo = {
  anchor: Dom.element,
  hotspot: Types.hotspot,
  index: int,
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
  let simActive = state.simulation.status == Running

  // Derived state for display
  let currentCategory = if state.activeIndex >= 0 {
    switch Belt.Array.get(state.scenes, state.activeIndex) {
    | Some(s) =>
      if s.category == "" {
        "outdoor"
      } else {
        s.category
      }
    | None => "outdoor"
    }
  } else {
    "outdoor"
  }

  let currentFloor = if state.activeIndex >= 0 {
    switch Belt.Array.get(state.scenes, state.activeIndex) {
    | Some(s) =>
      if s.floor == "" {
        "ground"
      } else {
        s.floor
      }
    | None => ""
    }
  } else {
    ""
  }

  let (labelMenuOpen, setLabelMenuOpen) = React.useState(_ => false)

  let (hotspotMenu, setHotspotMenu) = React.useState(_ => None)

  // Processing UI state
  let (_procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "",
      "phase": "",
      "error": false,
    }
  )
  let hideTimerRef = React.useRef(Nullable.null)

  // Subscribe to processing updates
  React.useEffect0(() => {
    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | UpdateProcessing(payload) =>
        // Clear any existing hide timer
        switch Nullable.toOption(hideTimerRef.current) {
        | Some(timerId) =>
          clearTimeout(timerId)
          hideTimerRef.current = Nullable.null
        | None => ()
        }

        setProcState(_ => payload)

        // If progress is complete, start auto-hide timer
        if payload["progress"] >= 100.0 && payload["active"] {
          let timerId = setTimeout(
            () => {
              setProcState(
                prev => {
                  let next = Object.assign(Object.make(), prev)
                  next["active"] = false
                  next
                },
              )
              hideTimerRef.current = Nullable.null
            },
            3000,
          ) // 3 seconds delay for floating UI
          hideTimerRef.current = Nullable.fromOption(Some(timerId))
        }
      | OpenHotspotMenu(payload) =>
        setHotspotMenu(
          _ => Some({
            anchor: payload["anchor"],
            hotspot: payload["hotspot"],
            index: payload["index"],
          }),
        )
      | _ => ()
      }
    })

    Some(
      () => {
        unsubscribe()
      },
    )
  })

  // Sync Label Menu state when activeIndex changes
  React.useEffect1(() => {
    // LabelMenu internal state syncs with currentScene label
    setHotspotMenu(_ => None)
    None
  }, [state.activeIndex])

  // Poll for simulation status (or we could dispatch actions when simulation changes, assuming simulation updates store)
  // For now, keep simple interval check or verify if store triggers.
  // SimulationSystem is likely external.
  // We can use an effect with interval or hook into navigation updates if possible.
  // Original code updated on store subscription. Store had notify() called often?
  // Let's rely on re-renders for now, but simulation state might need polling if it doesn't dispatch.
  // Removed simulation polling
  // Simulation status is now in state.simulation.status

  React.useEffect0(() => {
    None
  })

  // Handlers
  let handleFabClick = e => {
    JsxEvent.Mouse.stopPropagation(e)

    if state.isLinking {
      ViewerState.state.linkingStartPoint = Nullable.null
      dispatch(Actions.StopLinking)
      EventBus.dispatch(ShowNotification("Link Mode: OFF", #Warning))
    } else {
      let cx = JsxEvent.Mouse.clientX(e)
      let cy = JsxEvent.Mouse.clientY(e)
      ViewerState.state.linkingStartPoint = Nullable.make({
        "x": Belt.Int.toFloat(cx),
        "y": Belt.Int.toFloat(cy),
      })

      let v = Nullable.toOption(ReBindings.Viewer.instance)
      switch v {
      | Some(_viewer) =>
        dispatch(Actions.StartLinking(None))
        EventBus.dispatch(ShowNotification("Link Mode: ACTIVE", #Success))
      | None => EventBus.dispatch(ShowNotification("Viewer not initialized", #Error))
      }
    }
  }

  let handleSimClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    if simActive {
      dispatch(Actions.StopAutoPilot)
    } else {
      // Start AutoPilot with journeyId from state or new
      dispatch(Actions.StartAutoPilot(state.currentJourneyId, false))
    }
  }

  let handleCatClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    let activeIdx = state.activeIndex
    if activeIdx >= 0 {
      let newCat = if currentCategory == "indoor" {
        "outdoor"
      } else {
        "indoor"
      }
      dispatch(Actions.UpdateSceneMetadata(activeIdx, Logger.castToJson({"category": newCat})))

      EventBus.dispatch(
        ShowNotification(
          if newCat == "indoor" {
            "Category: INDOOR"
          } else {
            "Category: OUTDOOR"
          },
          #Warning,
        ),
      )
    }
  }

  let handleLabelClick = e => {
    JsxEvent.Mouse.stopPropagation(e)
    setLabelMenuOpen(prev => !prev)
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
        <Tooltip
          alignment=#Right
          content={if state.isLinking {
            "Close Link Mode"
          } else {
            "Add Link"
          }}
        >
          <Shadcn.Button
            size="icon"
            variant={if !scenesLoaded {
              "secondary"
            } else if state.isLinking {
              "accent"
            } else {
              "destructive"
            }}
            className="w-[32px] h-[32px] rounded-full text-[20px] font-bold"
            onClick={handleFabClick}
          >
            {if state.isLinking {
              <LucideIcons.X size=20 strokeWidth=3 />
            } else {
              <LucideIcons.Plus size=20 strokeWidth=3 />
            }}
          </Shadcn.Button>
        </Tooltip>

        <Tooltip
          alignment=#Right
          content={if simActive {
            "Stop Auto-Pilot"
          } else {
            "Start Auto-Pilot"
          }}
        >
          <Shadcn.Button
            size="icon"
            variant={if !scenesLoaded {
              "secondary"
            } else {
              "destructive"
            }}
            className="w-[32px] h-[32px] rounded-full"
            onClick={handleSimClick}
          >
            {if simActive {
              <LucideIcons.Square size=18 strokeWidth=3 />
            } else {
              <LucideIcons.Play size=18 strokeWidth=3 />
            }}
          </Shadcn.Button>
        </Tooltip>

        <Tooltip content="Toggle Category" alignment=#Right>
          <Shadcn.Button
            size="icon"
            variant={if !scenesLoaded {
              "secondary"
            } else {
              "destructive"
            }}
            className="w-[32px] h-[32px] rounded-full"
            onClick={handleCatClick}
          >
            {if currentCategory == "indoor" {
              <LucideIcons.Home size=18 strokeWidth=3 />
            } else {
              <LucideIcons.Sun size=18 strokeWidth=3 />
            }}
          </Shadcn.Button>
        </Tooltip>

        <Shadcn.Popover
          open_={labelMenuOpen} onOpenChange={isOpen => setLabelMenuOpen(_ => isOpen)}
        >
          <Shadcn.Popover.Trigger asChild=true>
            <Tooltip content="Scene Label Preset" alignment=#Right>
              <Shadcn.Button
                size="icon"
                variant={if !scenesLoaded {
                  "secondary"
                } else {
                  "destructive"
                }}
                className="w-[32px] h-[32px] rounded-full text-[18px] font-bold"
                onClick={handleLabelClick}
              >
                <LucideIcons.Hash size=18 strokeWidth=3 />
              </Shadcn.Button>
            </Tooltip>
          </Shadcn.Popover.Trigger>
          <Shadcn.Popover.Content
            side="right"
            sideOffset=12
            className="p-0 bg-white rounded-2xl shadow-2xl border border-slate-200 z-[10000]"
          >
            <LabelMenu onClose={() => setLabelMenuOpen(_ => false)} />
          </Shadcn.Popover.Content>
        </Shadcn.Popover>

        {switch hotspotMenu {
        | Some(menu) =>
          <Shadcn.Popover
            open_={true}
            onOpenChange={isOpen =>
              if !isOpen {
                setHotspotMenu(_ => None)
              }}
          >
            <Shadcn.Popover.Anchor virtualRef={menu.anchor} />
            <Shadcn.Popover.Content
              side="top" sideOffset=12 className="p-0 border-none shadow-none"
            >
              <HotspotActionMenu
                hotspot={menu.hotspot} index={menu.index} onClose={() => setHotspotMenu(_ => None)}
              />
            </Shadcn.Popover.Content>
          </Shadcn.Popover>
        | None => React.null
        }}
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
        className={"viewer-persistent-label " ++ if currentLabel != "" {
          "state-visible"
        } else {
          "state-hidden"
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
          let _ = Js.Array.push({"text": "BLURRY", "cls": "q-blurry"}, b)
        } else if q.isSoft {
          let _ = Js.Array.push({"text": "SOFT", "cls": "q-soft"}, b)
        }
        if q.isSeverelyDark {
          let _ = Js.Array.push({"text": "DARK", "cls": "q-dark"}, b)
        } else if q.isDim {
          let _ = Js.Array.push({"text": "DIM", "cls": "q-dim"}, b)
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
          <span key={b["text"]} className={`quality-badge ${b["cls"]}`}>
            {React.string(b["text"])}
          </span>
        })
        ->React.array}
      </div>
    }

    /* Viewer Logo */
    <div
      id="viewer-logo"
      className="absolute bottom-6 right-6 z-[5002] bg-white rounded-xl shadow-xl p-[4px] flex items-center justify-center max-w-[120px] max-h-[60px] border border-black/5 overflow-hidden viewer-logo-masked"
    >
      <img src="images/logo.png" alt="Logo" className="w-full h-auto object-contain block" />
    </div>

    /* Linking Hint */
    /* Linking Hint */
    <div
      id="linking-cancel-hint"
      className={"absolute bottom-10 left-1/2 -translate-x-1/2 translate-y-2 z-[9999] flex flex-col items-center gap-1 transition-all duration-400 text-center pointer-events-none linking-hint-text " ++ if (
        state.isLinking
      ) {
        "opacity-100 translate-y-2"
      } else {
        "opacity-0 translate-y-4 hidden"
      }}
    >
      <span> {React.string("ESC to Cancel")} </span>
      <span className="linking-hint-subtext"> {React.string("ENTER to Finish")} </span>
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
          let isSelected = scenesLoaded && f.id == currentFloor

          <Tooltip key={f.id} content={f.label} alignment=#Right>
            <Shadcn.Button
              size="icon"
              variant="ghost"
              className={"w-8 h-8 min-w-8 min-h-8 rounded-full text-[15px] font-medium opacity-100 transition-all " ++ if (
                isSelected
              ) {
                "border-2 border-danger bg-[#0e2d52] text-white hover:bg-[#0e2d52] hover:text-white"
              } else {
                "border border-white/20 hover:border-2 hover:border-danger bg-[#0e2d52]/80 text-white hover:bg-[#0e2d52] hover:text-white"
              }}
              onClick={e => handleFloorClick(f.id, f.label, e)}
            >
              {React.string(f.short)}
              {if f.suffix != "" {
                <sup className="text-[10px] -ml-1"> {React.string(f.suffix)} </sup>
              } else {
                React.null
              }}
            </Shadcn.Button>
          </Tooltip>
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
