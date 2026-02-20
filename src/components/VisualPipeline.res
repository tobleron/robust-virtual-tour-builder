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

module PipelineNode = {
  @react.component
  let make = (
    ~item: Types.timelineItem,
    ~isActive: bool,
    ~scene: option<Types.scene>,
    ~targetScene: option<Types.scene>,
    ~onActivate: string => unit,
    ~onRemove: string => unit,
  ) => {
    let (thumbUrl, setThumbUrl) = React.useState(_ => "")

    React.useEffect1(() => {
      switch scene {
      | Some(s) =>
        let file = s.tinyFile->Option.getOr(s.file)
        let url = UrlUtils.fileToUrl(file)
        if url != thumbUrl {
          setThumbUrl(_ => url)
        }
        Some(() => UrlUtils.revokeUrl(url))
      | None =>
        setThumbUrl(_ => "")
        None
      }
    }, [scene])

    let handleClick = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      onActivate(item.id)
    }

    let handleKeyDown = (e: ReactEvent.Keyboard.t) => {
      let key = ReactEvent.Keyboard.key(e)
      if key == "Enter" || key == " " {
        ReactEvent.Keyboard.preventDefault(e)
        onActivate(item.id)
      }
    }

    let handleContextMenu = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      onRemove(item.id)
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
      "#4B0082" // Deep Indigo for Auto-Forward
    } else {
      switch scene {
      | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
      | None => "var(--primary-ui-blue)"
      }
    }

    let style = ReBindings.makeStyle({"--node-color": color})
    let className = "pipeline-node" ++ (isActive ? " active" : "")

    <div
      className
      role="button"
      tabIndex=0
      ariaLabel={"Timeline step: " ++
      targetScene->Option.map(ts => ts.name)->Option.getOr("Unknown")}
      onClick=handleClick
      onKeyDown=handleKeyDown
      onContextMenu=handleContextMenu
      style
    >
      <div className="node-tooltip">
        {if thumbUrl != "" {
          <img
            src=thumbUrl
            className="tooltip-thumb"
            alt={scene->Option.map(s => s.name)->Option.getOr("Unknown Scene") ++ " preview"}
          />
        } else {
          React.null
        }}
        <div className="tooltip-footer">
          <span className="tooltip-text">
            {React.string(scene->Option.map(s => s.name)->Option.getOr("Unknown Scene"))}
          </span>
        </div>
      </div>
    </div>
  }
}

@react.component
let make = () => {
  PerfUtils.useRenderBudget("VisualPipeline")
  injectStyles()

  let pipelineSlice = AppContext.usePipelineSlice()
  let dispatch = AppContext.useAppDispatch()

  let handleNodeActivate = React.useCallback1((itemId: string) => {
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
  }, [pipelineSlice])

  let handleNodeRemove = React.useCallback1((itemId: string) => {
    Logger.info(~module_="VisualPipeline", ~message="REMOVE_STEP", ~data=Some({"id": itemId}), ())
    dispatch(RemoveFromTimeline(itemId))
  }, [dispatch])

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

  // --- Deterministic Measurement Logic ---
  let (linePaths, setLinePaths) = React.useState(_ => Dict.make())
  let containerRef = React.useRef(Nullable.null)

  React.useLayoutEffect2(() => {
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

        let xStart = bRect.left +. bRect.width /. 2.0 -. cRect.left
        let xCorridor = 46.0 // Convergence happens almost immediately
        let xSlantEnd = 86.0 // Termination earlier
        let xEnd = aRect.left -. cRect.left

        // Calculate vertical delta for slant
        let slantWidth = Math.abs(vYTo -. vYFrom)

        // Parallel Bus Geometry:
        // Slant ends at xSlantEnd. It starts at xSlantEnd - slantWidth (limited by corridor start).
        let vXSlantStart = Math.max(xCorridor, xSlantEnd -. slantWidth)

        let d =
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

        paths->Dict.set(fid, d)
      | _ => ()
      }
    })
    setLinePaths(_ => paths)
    None
  }, (activeFloors, pipelineSlice.timeline))

  if activeFloors->Belt.Array.length == 0 {
    React.null
  } else {
    <div id="visual-pipeline-container" ref={containerRef->ReactDOM.Ref.domRef}>
      /* PCB-style Lines: Deterministic DOM-based Mapping */
      <svg
        className="pipeline-svg-overlay"
        style={ReBindings.makeStyle({
          "height": "400px",
          "width": "100%",
          "top": "auto",
          "bottom": "0",
          "zIndex": "9500",
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
              let isActive = switch pipelineSlice.activeTimelineStepId {
              | Some(id) => id == item.id
              | None =>
                switch Belt.Array.get(pipelineSlice.scenes, pipelineSlice.activeIndex) {
                | Some(currentScene) =>
                  let firstMatchId =
                    pipelineSlice.timeline
                    ->Belt.Array.getIndexBy(t => t.sceneId == currentScene.id)
                    ->Option.map(idx => pipelineSlice.timeline[idx]->Option.map(t => t.id))
                    ->Option.flatMap(x => x)
                    ->Option.getOr("")
                  item.id == firstMatchId
                | None => false
                }
              }

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
                  scene
                  targetScene
                  onActivate=handleNodeActivate
                  onRemove=handleNodeRemove
                />
              </div>
            })
            ->React.array}
          </div>
        })
        ->React.array}
      </div>
    </div>
  }
}
