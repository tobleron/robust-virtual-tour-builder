/* src/components/VisualPipeline.res - Visual Pipeline V3: Scalable Floor-Grouped Squares */

open ReBindings
open VisualPipelineNavigation

type hoverPreview = {thumbUrl: string, sceneName: string}
type displayNode = {
  id: string,
  timelineId: option<string>,
  representedSceneId: string,
  sourceSceneId: string,
  linkId: string,
}
let injectStyles = () => {
  VisualPipelineStyles.inject()
}

@react.component
let make = () => {
  PerfUtils.useRenderBudget("VisualPipeline")
  injectStyles()

  let pipelineSlice = AppContext.usePipelineSlice()
  let uiSlice = AppContext.useUiSlice()
  let dispatch = AppContext.useAppDispatch()
  let isSystemLocked = Capability.useIsSystemLocked()
  let resolveSceneId = (refValue: option<string>) =>
    refValue
    ->Belt.Option.flatMap(value =>
      pipelineSlice.scenes
      ->Belt.Array.getBy(s => s.id == value)
      ->Option.map(s => s.id),
    )
    ->Option.orElse(
      refValue
      ->Belt.Option.flatMap(value =>
        pipelineSlice.scenes
        ->Belt.Array.getBy(s => s.name == value)
        ->Option.map(s => s.id),
      ),
    )

  let displayNodes = React.useMemo2(() => {
    let homeNode = switch Belt.Array.get(pipelineSlice.scenes, 0) {
    | Some(scene) =>
      [{
        id: "home_" ++ scene.id,
        timelineId: None,
        representedSceneId: scene.id,
        sourceSceneId: scene.id,
        linkId: "__home__",
      }]
    | None => []
    }

    let linkedNodes =
      pipelineSlice.timeline
      ->Belt.Array.map(item => {
        let timelineRef = if item.targetScene != "" { Some(item.targetScene) } else { None }
        let sourceScene = pipelineSlice.scenes->Belt.Array.getBy(s => s.id == item.sceneId)
        let sourceHotspot = sourceScene->Option.flatMap(s => s.hotspots->Belt.Array.getBy(h =>
          h.linkId == item.linkId
        ))
        let representedSceneId =
          sourceHotspot
          ->Option.flatMap(h => h.targetSceneId)
          ->Option.orElse(resolveSceneId(timelineRef))
          ->Option.getOr(item.sceneId)

        {
          id: item.id,
          timelineId: Some(item.id),
          representedSceneId,
          sourceSceneId: item.sceneId,
          linkId: item.linkId,
        }
      })

    Belt.Array.concat(homeNode, linkedNodes)
  }, (pipelineSlice.timeline, pipelineSlice.scenes))

  let handleNodeActivate = (itemId: string) => {
    if isSystemLocked {
      ()
    } else {
      let nodeOpt = displayNodes->Belt.Array.getBy(node => node.id == itemId)
      switch nodeOpt {
      | Some(node) =>
        dispatch(Actions.SetActiveTimelineStep(node.timelineId))
        Logger.debug(
          ~module_="VisualPipeline",
          ~message="ACTIVATE_NODE",
          ~data=Some({
            "id": itemId,
            "timelineId": node.timelineId->Option.getOr(""),
            "targetSceneId": node.representedSceneId,
            "sourceSceneId": node.sourceSceneId,
          }),
          (),
        )
        goToScene(node.representedSceneId)
      | None =>
        Logger.warn(
          ~module_="VisualPipeline",
          ~message="ACTIVATE_NODE_UNKNOWN_STEP",
          ~data=Some({"id": itemId}),
          (),
        )
      }
    }
  }

  let handleNodeRemove = (itemId: string) => {
    if isSystemLocked {
      ()
    } else {
      switch displayNodes->Belt.Array.getBy(node => node.id == itemId) {
      | Some({timelineId: Some(timelineId)}) =>
        Logger.info(
          ~module_="VisualPipeline",
          ~message="REMOVE_STEP",
          ~data=Some({"id": itemId, "timelineId": timelineId}),
          (),
        )
        dispatch(RemoveFromTimeline(timelineId))
      | _ => ()
      }
    }
  }

  // --- Multi-Row Logic ---

  // 1. Group items by floor
  let groupedItems = React.useMemo2(() => {
    let groups = Belt.MutableMap.String.make()
    displayNodes->Belt.Array.forEach(item => {
      let floorId = switch pipelineSlice.scenes->Belt.Array.getBy(s => s.id == item.representedSceneId) {
      | Some(s) => s.floor == "" ? "ground" : s.floor
      | None => "ground"
      }
      let existing = groups->Belt.MutableMap.String.get(floorId)->Option.getOr([])
      groups->Belt.MutableMap.String.set(floorId, Belt.Array.concat(existing, [item]))
    })
    groups
  }, (displayNodes, pipelineSlice.scenes))

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
  let effectiveActiveNodeId = React.useMemo2(() => {
    let currentSceneId =
      Belt.Array.get(pipelineSlice.scenes, pipelineSlice.activeIndex)->Option.map(scene => scene.id)

    currentSceneId->Option.flatMap(sceneId =>
      displayNodes
      ->Belt.Array.getBy(node => node.representedSceneId == sceneId)
      ->Option.map(node => node.id)
    )
  }, (pipelineSlice.activeIndex, displayNodes))

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
      let encodeDict = JsonCombinators.Json.Encode.dict(JsonCombinators.Json.Encode.string)
      let prevStr = JsonCombinators.Json.stringify(encodeDict(prev))
      let nextStr = JsonCombinators.Json.stringify(encodeDict(paths))
      if prevStr == nextStr {
        prev
      } else {
        paths
      }
    })
    None
  }, (activeFloors, displayNodes, uiSlice.isLinking))

  if uiSlice.isLinking || uiSlice.isTeasing || activeFloors->Belt.Array.length == 0 {
    React.null
  } else {
      <div
        id="visual-pipeline-container"
        className={"visual-pipeline-container" ++ if isSystemLocked {
          " pipeline-locked"
        } else {
          ""
        }}
        style={ReBindings.makeStyle({"pointerEvents": "none"})}
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

      <div className="visual-pipeline-wrapper" style={ReBindings.makeStyle({"pointerEvents": "none"})}>
        /* Floor Tracks */
        {activeFloors
        ->Belt.Array.map(fid => {
          let items = groupedItems->Belt.MutableMap.String.get(fid)->Option.getOr([])
          <div key={"track-" ++ fid} className="pipeline-track">
            {items
            ->Belt.Array.mapWithIndex((idx, node) => {
              let isActive =
                effectiveActiveNodeId
                ->Option.map(activeId => activeId == node.id)
                ->Option.getOr(false)

              let sourceScene = pipelineSlice.scenes->Belt.Array.getBy(s => s.id == node.sourceSceneId)
              let representedScene =
                pipelineSlice.scenes->Belt.Array.getBy(s => s.id == node.representedSceneId)
              let isAutoForward = switch sourceScene {
              | Some(s) =>
                s.hotspots
                ->Belt.Array.getBy(h => h.linkId == node.linkId)
                ->Option.flatMap(h => h.isAutoForward)
                ->Option.getOr(false)
              | None => false
              }
              let item: VisualPipelineNode.nodeItem = {nodeId: node.id, linkId: node.linkId}

              <div id={idx == 0 ? "track-anchor-" ++ fid : ""} key={node.id}>
                <VisualPipelineNode
                  item
                  isActive
                  interactionDisabled=isSystemLocked
                  scene=representedScene
                  isAutoForward
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
