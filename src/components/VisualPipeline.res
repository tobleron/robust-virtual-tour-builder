/* src/components/VisualPipeline.res - Visual Pipeline V3: Scalable Floor-Grouped Squares */

open ReBindings
module Styles = VisualPipelineLogic.Styles

let injectStyles = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  let style = switch Nullable.toOption(existing) {
  | Some(el) => el
  | None =>
    let el = Dom.createElement("style")
    Dom.setId(el, "visual-pipeline-styles")
    Dom.appendChild(Dom.head, el)
    el
  }
  Dom.setTextContent(style, Styles.styles)
}

type hoverPreview = {thumbUrl: string, sceneName: string}

module PipelineNode = {
  @react.component
  let make = (
    ~item: Types.timelineItem,
    ~isActive: bool,
    ~interactionDisabled: bool,
    ~scene: option<Types.scene>,
    ~targetScene: option<Types.scene>,
    ~onActivate: string => unit,
    ~onRemove: string => unit,
    ~onHoverStart: (option<Types.scene>, string) => unit,
    ~onHoverEnd: unit => unit,
  ) => {
    let handleClick = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      if !interactionDisabled {
        onActivate(item.id)
      }
    }

    let handleKeyDown = (e: ReactEvent.Keyboard.t) => {
      let key = ReactEvent.Keyboard.key(e)
      if !interactionDisabled && (key == "Enter" || key == " ") {
        ReactEvent.Keyboard.preventDefault(e)
        onActivate(item.id)
      }
    }

    let handleContextMenu = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      if !interactionDisabled {
        onRemove(item.id)
      }
    }

    let handleMouseEnter = (_e: ReactEvent.Mouse.t) =>
      if !interactionDisabled {
        onHoverStart(scene, item.linkId)
      }
    let handleMouseLeave = (_e: ReactEvent.Mouse.t) => onHoverEnd()
    let handleFocus = (_e: ReactEvent.Focus.t) =>
      if !interactionDisabled {
        onHoverStart(scene, item.linkId)
      }
    let handleBlur = (_e: ReactEvent.Focus.t) => onHoverEnd()

    let (linkIdVisible, setLinkIdVisible) = React.useState(_ => false)
    let linkIdTimerRef = React.useRef((None: option<int>))

    React.useEffect2(() => {
      // isActive is used here as a proxy for "is being hovered/focused"
      // based on the parent component's onHoverStart/End calls if we wanted to sync,
      // but simpler to just use local hover state if we want it local to the node.
      None
    }, (isActive, interactionDisabled))

    // Local hover/timer management for the 3s LinkID requirement
    let startLinkIdTimer = () => {
      switch linkIdTimerRef.current {
      | Some(id) => ReBindings.Window.clearTimeout(id)
      | None => ()
      }
      linkIdTimerRef.current = Some(ReBindings.Window.setTimeout(() => {
          setLinkIdVisible(_ => true)
        }, 3000))
    }

    let stopLinkIdTimer = () => {
      switch linkIdTimerRef.current {
      | Some(id) => ReBindings.Window.clearTimeout(id)
      | None => ()
      }
      linkIdTimerRef.current = None
      setLinkIdVisible(_ => false)
    }

    let localHandleMouseEnter = e => {
      if !interactionDisabled {
        startLinkIdTimer()
        handleMouseEnter(e)
      }
    }

    let localHandleMouseLeave = e => {
      stopLinkIdTimer()
      handleMouseLeave(e)
    }

    let isAutoForward = switch scene {
    | Some(s) =>
      let hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == item.linkId)
      switch hotspot {
      | Some(h) =>
        switch h.isAutoForward {
        | Some(true) => true
        | _ => false
        }
      | None => false
      }
    | None => false
    }

    let color = if isAutoForward {
      "var(--success)" // Emerald for Auto-Forward
    } else {
      switch scene {
      | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
      | None => "var(--primary-ui-blue)"
      }
    }

    let style = ReBindings.makeStyle({"--node-color": color})
    let className =
      "pipeline-node" ++ (isActive ? " active" : "") ++ (interactionDisabled ? " disabled" : "")

    <div
      className
      role="button"
      tabIndex={interactionDisabled ? -1 : 0}
      ariaDisabled=interactionDisabled
      ariaLabel={"Timeline step: " ++
      targetScene->Option.map(ts => ts.name)->Option.getOr("Unknown")}
      onClick=handleClick
      onKeyDown=handleKeyDown
      onContextMenu=handleContextMenu
      onMouseEnter=localHandleMouseEnter
      onMouseLeave=localHandleMouseLeave
      onFocus=handleFocus
      onBlur=handleBlur
      style
    >
      {linkIdVisible
        ? <div className="pipeline-node-tooltip">
            <span className="tooltip-label"> {React.string("ID")} </span>
            <span className="tooltip-value"> {React.string(item.linkId)} </span>
          </div>
        : React.null}
    </div>
  }
}

@react.component
let make = () => {
  PerfUtils.useRenderBudget("VisualPipeline")
  injectStyles()

  let pipelineSlice = AppContext.usePipelineSlice()
  let uiSlice = AppContext.useUiSlice()
  let dispatch = AppContext.useAppDispatch()
  let isSystemLocked = Capability.useIsSystemLocked()

  let handleNodeActivate = (itemId: string) => {
    if isSystemLocked {
      ()
    } else {
      Logger.debug(
        ~module_="VisualPipeline",
        ~message="ACTIVATE_NODE",
        ~data=Some({"id": itemId}),
        (),
      )
      dispatch(Actions.SetActiveTimelineStep(Some(itemId)))

      let item = pipelineSlice.timeline->Belt.Array.getBy(t => t.id == itemId)
      switch item {
      | Some(t) =>
        let sceneIdx =
          pipelineSlice.scenes->Belt.Array.getIndexBy(s => s.id == t.sceneId)->Option.getOr(-1)
        if sceneIdx != -1 {
          let scene = Belt.Array.get(pipelineSlice.scenes, sceneIdx)
          switch scene {
          | Some(s) =>
            let hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == t.linkId)
            switch hotspot {
            | Some(h) => dispatch(SetActiveScene(sceneIdx, h.yaw, h.pitch, None))
            | None => dispatch(SetActiveScene(sceneIdx, 0.0, 0.0, None))
            }
          | None => ()
          }
        }
      | None => ()
      }
    }
  }

  let handleNodeRemove = (itemId: string) => {
    if isSystemLocked {
      ()
    } else {
      Logger.info(~module_="VisualPipeline", ~message="REMOVE_STEP", ~data=Some({"id": itemId}), ())
      dispatch(RemoveFromTimeline(itemId))
    }
  }

  // --- Multi-Row Logic ---

  // 1. Group items by floor
  let groupedItems = React.useMemo2(() => {
    let groups = Belt.MutableMap.String.make()
    pipelineSlice.timeline->Belt.Array.forEach(item => {
      let floorId = switch pipelineSlice.scenes->Belt.Array.getBy(s => s.id == item.sceneId) {
      | Some(s) => s.floor == "" ? "ground" : s.floor
      | None => "ground"
      }
      let existing = groups->Belt.MutableMap.String.get(floorId)->Option.getOr([])
      groups->Belt.MutableMap.String.set(floorId, Belt.Array.concat(existing, [item]))
    })
    groups
  }, (pipelineSlice.timeline, pipelineSlice.scenes))

  // 3. Filter and sort floors that have items (Strict Basement-to-Roof order)
  let activeFloors = React.useMemo2(() => {
    let arr =
      groupedItems
      ->Belt.MutableMap.String.keysToArray
      ->Belt.Array.keep(fid => groupedItems->Belt.MutableMap.String.get(fid)->Option.isSome)

    arr->Belt.SortArray.stableSortBy((a, b) => {
      let idxA = Constants.Scene.floorLevels->Belt.Array.getIndexBy(f => f.id == a)->Option.getOr(0)
      let idxB = Constants.Scene.floorLevels->Belt.Array.getIndexBy(f => f.id == b)->Option.getOr(0)
      idxA - idxB
    })
  }, (groupedItems, Constants.Scene.floorLevels))

  // Determine the active step to highlight.
  // If the explicit active timeline step does not belong to the current scene,
  // fall back to the current scene step so highlight updates immediately on scene switch.
  let effectiveActiveStepId = React.useMemo3(() => {
    let currentSceneId =
      Belt.Array.get(pipelineSlice.scenes, pipelineSlice.activeIndex)->Option.map(scene => scene.id)

    let currentSceneStepId = currentSceneId->Option.flatMap(sceneId =>
      pipelineSlice.timeline
      ->Belt.Array.getBy(step => step.sceneId == sceneId)
      ->Option.map(step => step.id)
    )

    switch pipelineSlice.activeTimelineStepId {
    | Some(stepId) =>
      switch currentSceneId {
      | Some(sceneId) =>
        switch pipelineSlice.timeline->Belt.Array.getBy(step => step.id == stepId) {
        | Some(step) if step.sceneId == sceneId => Some(stepId)
        | _ => currentSceneStepId
        }
      | None => Some(stepId)
      }
    | None => currentSceneStepId
    }
  }, (pipelineSlice.activeTimelineStepId, pipelineSlice.activeIndex, pipelineSlice.timeline))

  // --- Deterministic Measurement Logic ---
  let (linePaths, setLinePaths) = React.useState(_ => Dict.make())
  let containerRef = React.useRef(Nullable.null)
  let (hoverPreview, setHoverPreview) = React.useState((): option<hoverPreview> => None)
  let hoverTimerRef = React.useRef((None: option<int>))
  let activePreviewUrlRef = React.useRef("")

  let clearHoverTimer = () => {
    switch hoverTimerRef.current {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    hoverTimerRef.current = None
  }

  let hideHoverPreview = () => {
    clearHoverTimer()
    let prevUrl = activePreviewUrlRef.current
    if prevUrl != "" {
      UrlUtils.revokeUrl(prevUrl)
      activePreviewUrlRef.current = ""
    }
    setHoverPreview(_ => None)
  }

  let showHoverPreview = (sceneOpt: option<Types.scene>, _linkId: string) => {
    if isSystemLocked {
      hideHoverPreview()
      ()
    } else {
      clearHoverTimer()
      hoverTimerRef.current = Some(ReBindings.Window.setTimeout(() => {
          switch sceneOpt {
          | Some(scene) =>
            switch scene.tinyFile {
            | Some(Blob(_) as tiny) | Some(File(_) as tiny) =>
              let nextUrl = UrlUtils.fileToUrl(tiny)
              if nextUrl == "" {
                hideHoverPreview()
              } else {
                let prevUrl = activePreviewUrlRef.current
                if prevUrl != "" && prevUrl != nextUrl {
                  UrlUtils.revokeUrl(prevUrl)
                }
                activePreviewUrlRef.current = nextUrl
                setHoverPreview(_ => Some({thumbUrl: nextUrl, sceneName: scene.name}))
              }
            | _ => hideHoverPreview()
            }
          | None => hideHoverPreview()
          }
        }, 50))
    }
  }

  React.useEffect1(() => {
    if isSystemLocked {
      hideHoverPreview()
    }
    None
  }, [isSystemLocked])

  React.useEffect0(() => {
    Some(
      () => {
        clearHoverTimer()
        let prevUrl = activePreviewUrlRef.current
        if prevUrl != "" {
          UrlUtils.revokeUrl(prevUrl)
        }
      },
    )
  })

  React.useLayoutEffect3(() => {
    let paths = Dict.make()
    activeFloors->Belt.Array.forEachWithIndex((_idx, fid) => {
      let btn = Dom.getElementById("floor-nav-button-" ++ fid)
      let anchor = Dom.getElementById("track-anchor-" ++ fid)
      let container = containerRef.current->Nullable.toOption

      switch (Nullable.toOption(btn), Nullable.toOption(anchor), container) {
      | (Some(b), Some(a), Some(c)) =>
        let bRect = b->Dom.getBoundingClientRect
        let aRect = a->Dom.getBoundingClientRect
        let cRect = c->Dom.getBoundingClientRect

        // Calculate Y relative to container bottom (since container is bottom-aligned)
        let yFrom = cRect.bottom -. (bRect.top +. bRect.height /. 2.0)
        let yTo = cRect.bottom -. (aRect.top +. aRect.height /. 2.0)

        // Maps to SVG Y (SVG Height is matching container height)
        let vYFrom = 400.0 -. yFrom
        let vYTo = 400.0 -. yTo

        /* Route line edge-to-edge:
           - Start at floor button right edge
           - End at first pipeline node left edge
           This prevents crossing through controls and makes contact exact. */
        let xStart = bRect.right -. cRect.left
        let xEnd = aRect.left -. cRect.left

        // Calculate vertical delta for slant
        let slantWidth = Math.abs(vYTo -. vYFrom)
        let deltaX = xEnd -. xStart
        let d = if deltaX <= 2.0 {
          "M " ++
          xStart->Float.toString ++
          " " ++
          vYFrom->Float.toString ++
          " L " ++
          xEnd->Float.toString ++
          " " ++
          vYTo->Float.toString
        } else {
          let xCorridor = xStart +. Math.min(14.0, deltaX *. 0.25)
          let xSlantEnd = xStart +. Math.min(44.0, deltaX *. 0.7)
          // Slant starts at xSlantEnd - slantWidth, clamped so it never backtracks.
          let vXSlantStart = Math.max(xCorridor, xSlantEnd -. slantWidth)
          "M " ++
          xStart->Float.toString ++
          " " ++
          vYFrom->Float.toString ++
          " L " ++
          xCorridor->Float.toString ++
          " " ++
          vYFrom->Float.toString ++
          " L " ++
          vXSlantStart->Float.toString ++
          " " ++
          vYFrom->Float.toString ++
          " L " ++
          xSlantEnd->Float.toString ++
          " " ++
          vYTo->Float.toString ++
          " L " ++
          xEnd->Float.toString ++
          " " ++
          vYTo->Float.toString
        }

        paths->Dict.set(fid, d)
      | _ => ()
      }
    })
    setLinePaths(prev => {
      let prevStr = JSON.stringifyAny(prev)
      let nextStr = JSON.stringifyAny(paths)
      if prevStr == nextStr {
        prev
      } else {
        paths
      }
    })
    None
  }, (activeFloors, pipelineSlice.timeline, uiSlice.isLinking))

  if uiSlice.isLinking || uiSlice.isTeasing || activeFloors->Belt.Array.length == 0 {
    React.null
  } else {
    <div
      id="visual-pipeline-container"
      className={"pointer-events-none" ++ if isSystemLocked {
        " pipeline-locked"
      } else {
        ""
      }}
      ref={containerRef->ReactDOM.Ref.domRef}
    >
      /* PCB-style Lines: Deterministic DOM-based Mapping */
      <svg
        className="pipeline-svg-overlay"
        style={ReBindings.makeStyle({
          "height": "400px",
          "width": "100%",
          "top": "auto",
          "bottom": "0",
          "zIndex": "5",
        })}
      >
        {activeFloors
        ->Belt.Array.map(fid => {
          switch linePaths->Dict.get(fid) {
          | Some(d) => <path key={"line-" ++ fid} d className="pipeline-floor-line" />
          | None => React.null
          }
        })
        ->React.array}
      </svg>

      <div className="visual-pipeline-wrapper">
        /* Floor Tracks */
        {activeFloors
        ->Belt.Array.map(fid => {
          let items = groupedItems->Belt.MutableMap.String.get(fid)->Option.getOr([])
          <div key={"track-" ++ fid} className="pipeline-track">
            {items
            ->Belt.Array.mapWithIndex((idx, item) => {
              let isActive =
                effectiveActiveStepId
                ->Option.map(activeId => activeId == item.id)
                ->Option.getOr(false)

              let scene = pipelineSlice.scenes->Belt.Array.getBy(s => s.id == item.sceneId)
              let targetScene =
                pipelineSlice.scenes
                ->Belt.Array.getBy(s => s.id == item.targetScene)
                ->Option.orElse(
                  pipelineSlice.scenes->Belt.Array.getBy(s => s.name == item.targetScene),
                )

              <div id={idx == 0 ? "track-anchor-" ++ fid : ""} key={item.id}>
                <PipelineNode
                  item
                  isActive
                  interactionDisabled=isSystemLocked
                  scene
                  targetScene
                  onActivate=handleNodeActivate
                  onRemove=handleNodeRemove
                  onHoverStart=showHoverPreview
                  onHoverEnd=hideHoverPreview
                />
              </div>
            })
            ->React.array}
          </div>
        })
        ->React.array}
      </div>

      {switch (hoverPreview, isSystemLocked) {
      | (_, true) => React.null
      | (Some(preview), false) =>
        <div className="pipeline-global-tooltip visible">
          <img
            src={preview.thumbUrl} className="tooltip-thumb" alt={preview.sceneName ++ " preview"}
          />
        </div>
      | (None, false) => React.null
      }}
    </div>
  }
}
