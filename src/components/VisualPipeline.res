/* src/components/VisualPipeline.res - Visual Pipeline V3: Scalable Floor-Grouped Squares */

open ReBindings
open VisualPipelineNavigation

type hoverPreview = {thumbUrl: string, sceneName: string}
type displayNode = VisualPipelineGraph.node
type scenePoint = {x: float, y: float}
type sceneEdgePath = {id: string, d: string, className: string, clipId: option<string>}
type sceneEdgeClip = {id: string, x: float, y: float, width: float, height: float}
type clusterInfo = {hubSceneId: string, rank: int, branchCount: int}
type floorBand = {yTop: float, yBottom: float}
let nodePitchPx = 18.0
let branchRisePx = 14.0
let branchYOffsetForRank = (rank: int): float => {
  let level = rank / 2 + 1
  let dir = if rank % 2 == 0 {
    1.0
  } else {
    -1.0
  }
  dir *. (level->Int.toFloat *. branchRisePx)
}
let injectStyles = () => {
  VisualPipelineStyles.inject()
}

@react.component
let make = () => {
  PerfUtils.useRenderBudget("VisualPipeline")
  injectStyles()

  let state = AppContext.useAppState()
  let pipelineSlice = AppContext.usePipelineSlice()
  let uiSlice = AppContext.useUiSlice()
  let dispatch = AppContext.useAppDispatch()
  let isSystemLocked = Capability.useIsSystemLocked()

  let canonicalTraversal = React.useMemo1(
    () => VisualPipelineGraph.deriveTraversal(~state),
    [state.structuralRevision],
  )
  let graph = React.useMemo3(
    () =>
      VisualPipelineGraph.build(
        ~scenes=pipelineSlice.scenes,
        ~timeline=pipelineSlice.timeline,
        ~traversal=Some(canonicalTraversal),
      ),
    (pipelineSlice.timeline, pipelineSlice.scenes, canonicalTraversal),
  )
  let displayNodes = graph.nodes
  let sceneOrderIndex = React.useMemo1(() => {
    displayNodes->Belt.Array.reduce(Belt.Map.String.empty, (acc, node) => {
      if acc->Belt.Map.String.get(node.representedSceneId)->Option.isSome {
        acc
      } else {
        Belt.Map.String.set(acc, node.representedSceneId, node.order)
      }
    })
  }, [displayNodes])
  let parentByScene = React.useMemo3(() => {
    let incomingByScene = Belt.MutableMap.String.make()
    graph.edges->Belt.Array.forEach(edge => {
      let existing = incomingByScene->Belt.MutableMap.String.get(edge.toSceneId)->Option.getOr([])
      if !(existing->Belt.Array.some(sourceId => sourceId == edge.fromSceneId)) {
        incomingByScene->Belt.MutableMap.String.set(
          edge.toSceneId,
          Belt.Array.concat(existing, [edge.fromSceneId]),
        )
      }
    })

    let parents = Belt.MutableMap.String.make()
    displayNodes->Belt.Array.forEach(node => {
      let sceneId = node.representedSceneId
      let sceneRank = sceneOrderIndex->Belt.Map.String.get(sceneId)->Option.getOr(10000)
      let sources = incomingByScene->Belt.MutableMap.String.get(sceneId)->Option.getOr([])
      let beforeSources =
        sources->Belt.Array.keep(
          src => sceneOrderIndex->Belt.Map.String.get(src)->Option.getOr(10000) < sceneRank,
        )

      let parentOpt = if Belt.Array.length(beforeSources) > 0 {
        beforeSources
        ->Belt.Array.reduce(
          (None: option<(string, int)>),
          (acc, src) => {
            let rank = sceneOrderIndex->Belt.Map.String.get(src)->Option.getOr(10000)
            switch acc {
            | Some((_bestSceneId, bestRank)) if rank <= bestRank => acc
            | _ => Some((src, rank))
            }
          },
        )
        ->Option.map(((sceneId, _rank)) => sceneId)
      } else {
        sources
        ->Belt.Array.reduce(
          (None: option<(string, int)>),
          (acc, src) => {
            let rank = sceneOrderIndex->Belt.Map.String.get(src)->Option.getOr(10000)
            switch acc {
            | Some((_bestSceneId, bestRank)) if rank >= bestRank => acc
            | _ => Some((src, rank))
            }
          },
        )
        ->Option.map(((sceneId, _rank)) => sceneId)
      }

      switch parentOpt {
      | Some(parentId) => parents->Belt.MutableMap.String.set(sceneId, parentId)
      | None => ()
      }
    })
    parents
  }, (graph, displayNodes, sceneOrderIndex))
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
    displayNodes->Belt.Array.forEach((item: displayNode) => {
      let floorId = switch pipelineSlice.scenes->Belt.Array.getBy(
        s => s.id == item.representedSceneId,
      ) {
      | Some(s) => s.floor == "" ? "ground" : s.floor
      | None => "ground"
      }
      let existing = groups->Belt.MutableMap.String.get(floorId)->Option.getOr([])
      groups->Belt.MutableMap.String.set(floorId, Belt.Array.concat(existing, [item]))
    })

    groups
    ->Belt.MutableMap.String.keysToArray
    ->Belt.Array.forEach(fid => {
      let items = groups->Belt.MutableMap.String.get(fid)->Option.getOr([])
      let sorted = items->Belt.SortArray.stableSortBy(
        (a, b) => {
          let sceneRankA =
            sceneOrderIndex->Belt.Map.String.get(a.representedSceneId)->Option.getOr(10000)
          let sceneRankB =
            sceneOrderIndex->Belt.Map.String.get(b.representedSceneId)->Option.getOr(10000)
          sceneRankA - sceneRankB
        },
      )
      groups->Belt.MutableMap.String.set(fid, sorted)
    })

    groups
  }, (displayNodes, pipelineSlice.scenes))

  let stableHubTargetClusters = React.useMemo4(() => {
    let outgoingTargets = Belt.MutableMap.String.make()
    let hubTargetEdgeRank = Belt.MutableMap.String.make()
    graph.edges->Belt.Array.forEachWithIndex((idx, edge) => {
      let existing = outgoingTargets->Belt.MutableMap.String.get(edge.fromSceneId)->Option.getOr([])
      if !(existing->Belt.Array.some(targetId => targetId == edge.toSceneId)) {
        outgoingTargets->Belt.MutableMap.String.set(
          edge.fromSceneId,
          Belt.Array.concat(existing, [edge.toSceneId]),
        )
      }
      let edgeKey = edge.fromSceneId ++ "->" ++ edge.toSceneId
      switch hubTargetEdgeRank->Belt.MutableMap.String.get(edgeKey) {
      | Some(_) => ()
      | None => hubTargetEdgeRank->Belt.MutableMap.String.set(edgeKey, idx)
      }
    })

    let clusters = Belt.MutableMap.String.make()
    outgoingTargets
    ->Belt.MutableMap.String.keysToArray
    ->Belt.Array.forEach(hubSceneId => {
      let targets = outgoingTargets->Belt.MutableMap.String.get(hubSceneId)->Option.getOr([])
      let branchTargets = switch parentByScene->Belt.MutableMap.String.get(hubSceneId) {
      | Some(parentId) => targets->Belt.Array.keep(targetId => targetId != parentId)
      | None => targets
      }
      let hubFloor =
        pipelineSlice.scenes
        ->Belt.Array.getBy(scene => scene.id == hubSceneId)
        ->Option.map(scene => scene.floor == "" ? "ground" : scene.floor)
        ->Option.getOr("ground")
      let sameFloorTargets = branchTargets->Belt.Array.keep(
        targetSceneId =>
          pipelineSlice.scenes
          ->Belt.Array.getBy(scene => scene.id == targetSceneId)
          ->Option.map(scene => scene.floor == "" ? "ground" : scene.floor)
          ->Option.getOr("ground") == hubFloor,
      )

      // Hub qualification rule:
      // 2+ same-floor branch targets (parent/exit-back already excluded above).
      if Belt.Array.length(sameFloorTargets) >= 2 {
        let sortedTargets = sameFloorTargets->Belt.SortArray.stableSortBy(
          (a, b) => {
            let edgeRankA =
              hubTargetEdgeRank
              ->Belt.MutableMap.String.get(hubSceneId ++ "->" ++ a)
              ->Option.getOr(100000)
            let edgeRankB =
              hubTargetEdgeRank
              ->Belt.MutableMap.String.get(hubSceneId ++ "->" ++ b)
              ->Option.getOr(100000)
            if edgeRankA != edgeRankB {
              edgeRankA - edgeRankB
            } else {
              let ra = sceneOrderIndex->Belt.Map.String.get(a)->Option.getOr(10000)
              let rb = sceneOrderIndex->Belt.Map.String.get(b)->Option.getOr(10000)
              ra - rb
            }
          },
        )
        let branchCount = Belt.Array.length(sortedTargets)
        sortedTargets->Belt.Array.forEachWithIndex(
          (rank, targetSceneId) => {
            switch clusters->Belt.MutableMap.String.get(targetSceneId) {
            | Some(_) => ()
            | None =>
              clusters->Belt.MutableMap.String.set(targetSceneId, {hubSceneId, rank, branchCount})
            }
          },
        )
      }
    })
    clusters
  }, (graph, pipelineSlice.scenes, sceneOrderIndex, parentByScene))

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
  let wrapperRef = React.useRef(Nullable.null)
  let (sceneEdgePaths, setSceneEdgePaths) = React.useState((): array<sceneEdgePath> => [])
  let (sceneEdgeClips, setSceneEdgeClips) = React.useState((): array<sceneEdgeClip> => [])
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

  React.useLayoutEffect6(() => {
    if uiSlice.isTeasing {
      None
    } else {
      let paths = Dict.make()
      let missingAnchors = ref(false)
      activeFloors->Belt.Array.forEachWithIndex((_idx, fid) => {
        let btn = Dom.getElementById("floor-nav-button-" ++ fid)
        let anchor =
          groupedItems
          ->Belt.MutableMap.String.get(fid)
          ->Option.flatMap(items => Belt.Array.get(items, 0))
          ->Option.map(item => Dom.getElementById("pipeline-node-wrap-" ++ item.id))
          ->Option.getOr(Nullable.null)
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
        | _ => missingAnchors := true
        }
      })
      setLinePaths(prev => {
        let encodeDict = JsonCombinators.Json.Encode.dict(JsonCombinators.Json.Encode.string)
        let prevStr = JsonCombinators.Json.stringify(encodeDict(prev))
        let nextStr = JsonCombinators.Json.stringify(encodeDict(paths))
        let isNextEmpty = nextStr == "{}"
        if missingAnchors.contents && isNextEmpty && prevStr != "{}" {
          // Keep previously measured connector geometry when anchors are transiently unavailable.
          prev
        } else if prevStr == nextStr {
          prev
        } else {
          paths
        }
      })
      None
    }
  }, (
    activeFloors,
    displayNodes,
    groupedItems,
    uiSlice.isLinking,
    uiSlice.isTeasing,
    isSystemLocked,
  ))

  React.useLayoutEffect7(() => {
    if uiSlice.isTeasing || uiSlice.isLinking {
      setSceneEdgePaths(_ => [])
      setSceneEdgeClips(_ => [])
      None
    } else {
      switch wrapperRef.current->Nullable.toOption {
      | None => None
      | Some(wrapper) =>
        let wrapperRect = wrapper->Dom.getBoundingClientRect
        let centers = Belt.MutableMap.String.make()
        let floorByScene = Belt.MutableMap.String.make()
        displayNodes->Belt.Array.forEach(node =>
          floorByScene->Belt.MutableMap.String.set(node.representedSceneId, node.floorId)
        )

        let floorBands = Belt.MutableMap.String.make()
        let floorClipIds = Belt.MutableMap.String.make()
        activeFloors->Belt.Array.forEachWithIndex((idx, floorId) => {
          floorClipIds->Belt.MutableMap.String.set(
            floorId,
            "pipeline-floor-clip-" ++ Int.toString(idx),
          )
          switch Dom.getElementById("pipeline-track-" ++ floorId)->Nullable.toOption {
          | Some(trackEl) =>
            let trackRect = trackEl->Dom.getBoundingClientRect
            let yTop = trackRect.top -. wrapperRect.top
            let yBottom = trackRect.bottom -. wrapperRect.top
            floorBands->Belt.MutableMap.String.set(floorId, {yTop, yBottom})
          | None => ()
          }
        })
        let clipDefs = activeFloors->Belt.Array.keepMap(floorId =>
          switch (
            floorClipIds->Belt.MutableMap.String.get(floorId),
            floorBands->Belt.MutableMap.String.get(floorId),
          ) {
          | (Some(clipId), Some(band)) =>
            Some({
              id: clipId,
              x: 0.0,
              y: band.yTop,
              width: wrapperRect.width,
              height: band.yBottom -. band.yTop,
            })
          | _ => None
          }
        )
        setSceneEdgeClips(_ => clipDefs)

        let sameFloorOutgoing = Belt.MutableMap.String.make()
        graph.edges->Belt.Array.forEach(edge => {
          let fromFloor = floorByScene->Belt.MutableMap.String.get(edge.fromSceneId)
          let toFloor = floorByScene->Belt.MutableMap.String.get(edge.toSceneId)
          if fromFloor == toFloor {
            let existing =
              sameFloorOutgoing->Belt.MutableMap.String.get(edge.fromSceneId)->Option.getOr([])
            if !(existing->Belt.Array.some(targetId => targetId == edge.toSceneId)) {
              sameFloorOutgoing->Belt.MutableMap.String.set(
                edge.fromSceneId,
                Belt.Array.concat(existing, [edge.toSceneId]),
              )
            }
          }
        })

        displayNodes->Belt.Array.forEach(node => {
          switch Dom.getElementById("pipeline-node-wrap-" ++ node.id)->Nullable.toOption {
          | Some(el) =>
            let rect = el->Dom.getBoundingClientRect
            let x = rect.left -. wrapperRect.left +. rect.width /. 2.0
            let y = rect.top -. wrapperRect.top +. rect.height /. 2.0
            let center: scenePoint = {x, y}
            centers->Belt.MutableMap.String.set(node.id, center)
          | None => ()
          }
        })

        let hasNodeCollisionOnHorizontal = (
          ~floorId: string,
          ~fromNodeId: string,
          ~toNodeId: string,
          ~lineY: float,
          ~xA: float,
          ~xB: float,
        ): bool => {
          let xMin = Math.min(xA, xB)
          let xMax = Math.max(xA, xB)
          displayNodes->Belt.Array.some(node => {
            if node.floorId != floorId || node.id == fromNodeId || node.id == toNodeId {
              false
            } else {
              switch centers->Belt.MutableMap.String.get(node.id) {
              | Some(point) =>
                point.x > xMin +. 4.0 && point.x < xMax -. 4.0 && Math.abs(point.y -. lineY) < 9.0
              | None => false
              }
            }
          })
        }

        let pairEdgeCandidates = Belt.MutableMap.String.make()
        let pairOrder = Belt.MutableQueue.make()
        graph.edges->Belt.Array.forEach(edge => {
          let a = edge.fromSceneId
          let b = edge.toSceneId
          let pairKey = if a <= b {
            a ++ "<->" ++ b
          } else {
            b ++ "<->" ++ a
          }
          switch pairEdgeCandidates->Belt.MutableMap.String.get(pairKey) {
          | Some(existing) =>
            pairEdgeCandidates->Belt.MutableMap.String.set(
              pairKey,
              Belt.Array.concat(existing, [edge]),
            )
          | None =>
            pairEdgeCandidates->Belt.MutableMap.String.set(pairKey, [edge])
            pairOrder->Belt.MutableQueue.add(pairKey)
          }
        })

        let chooseDirectedEdge = (candidates: array<VisualPipelineGraph.edge>): option<
          VisualPipelineGraph.edge,
        > =>
          candidates
          ->Belt.Array.reduce((None: option<(VisualPipelineGraph.edge, int)>), (best, edge) => {
            let hubForward =
              stableHubTargetClusters
              ->Belt.MutableMap.String.get(edge.toSceneId)
              ->Option.map(cluster => cluster.hubSceneId == edge.fromSceneId)
              ->Option.getOr(false)
            let fromRank =
              sceneOrderIndex->Belt.Map.String.get(edge.fromSceneId)->Option.getOr(100000)
            let toRank = sceneOrderIndex->Belt.Map.String.get(edge.toSceneId)->Option.getOr(100000)
            let chronological = fromRank <= toRank
            let score =
              (edge.kind == Forward ? 400 : 0) +
              (hubForward ? 250 : 0) +
              (chronological ? 80 : 0) + (edge.isCrossFloor ? 0 : 20)
            switch best {
            | Some((_bestEdge, bestScore)) if bestScore >= score => best
            | _ => Some((edge, score))
            }
          })
          ->Option.map(((edge, _score)) => edge)

        let uniqueEdges =
          pairOrder
          ->Belt.MutableQueue.toArray
          ->Belt.Array.keepMap(pairKey =>
            pairEdgeCandidates
            ->Belt.MutableMap.String.get(pairKey)
            ->Option.flatMap(candidates => chooseDirectedEdge(candidates))
          )
          ->Belt.Array.keep(edge => edge.kind == Forward)

        let nextPaths = uniqueEdges->Belt.Array.keepMap(edge => {
          switch (
            centers->Belt.MutableMap.String.get(edge.fromNodeId),
            centers->Belt.MutableMap.String.get(edge.toNodeId),
          ) {
          | (Some(fromPoint), Some(toPoint)) =>
            let fromFloor = floorByScene->Belt.MutableMap.String.get(edge.fromSceneId)
            let toFloor = floorByScene->Belt.MutableMap.String.get(edge.toSceneId)
            let sameFloor = fromFloor == toFloor
            if !sameFloor {
              // Inter-floor linkage is intentionally hidden in the pipeline.
              // Users infer floor transitions from sequence + floor rows.
              None
            } else {
              let clipId = switch fromFloor {
              | Some(floorId) => floorClipIds->Belt.MutableMap.String.get(floorId)
              | _ => None
              }
              let isHubFanout =
                sameFloorOutgoing
                ->Belt.MutableMap.String.get(edge.fromSceneId)
                ->Option.map(targets => Belt.Array.length(targets) >= 2)
                ->Option.getOr(false)
              let hubClusterForTarget =
                stableHubTargetClusters->Belt.MutableMap.String.get(edge.toSceneId)
              let d = if (
                isHubFanout &&
                hubClusterForTarget
                ->Option.map(cluster => cluster.hubSceneId == edge.fromSceneId)
                ->Option.getOr(false)
              ) {
                // Hub fanout uses a deterministic fork trunk.
                // Branches start from hub center, then vertical, then horizontal.
                "M " ++
                fromPoint.x->Float.toString ++
                " " ++
                fromPoint.y->Float.toString ++
                " L " ++
                fromPoint.x->Float.toString ++
                " " ++
                toPoint.y->Float.toString ++
                " L " ++
                toPoint.x->Float.toString ++
                " " ++
                toPoint.y->Float.toString
              } else if Math.abs(fromPoint.y -. toPoint.y) < 0.6 {
                let floorId = fromFloor->Option.getOr("ground")
                let hasCollision = hasNodeCollisionOnHorizontal(
                  ~floorId,
                  ~fromNodeId=edge.fromNodeId,
                  ~toNodeId=edge.toNodeId,
                  ~lineY=fromPoint.y,
                  ~xA=fromPoint.x,
                  ~xB=toPoint.x,
                )
                if !hasCollision {
                  "M " ++
                  fromPoint.x->Float.toString ++
                  " " ++
                  fromPoint.y->Float.toString ++
                  " L " ++
                  toPoint.x->Float.toString ++
                  " " ++
                  toPoint.y->Float.toString
                } else {
                  let lane = 12.0
                  let detourUp = fromPoint.y -. lane
                  let detourDown = fromPoint.y +. lane
                  let upCollision = hasNodeCollisionOnHorizontal(
                    ~floorId,
                    ~fromNodeId=edge.fromNodeId,
                    ~toNodeId=edge.toNodeId,
                    ~lineY=detourUp,
                    ~xA=fromPoint.x,
                    ~xB=toPoint.x,
                  )
                  let chosenY = if !upCollision {
                    detourUp
                  } else {
                    detourDown
                  }
                  let exitX = if toPoint.x >= fromPoint.x {
                    fromPoint.x +. 8.0
                  } else {
                    fromPoint.x -. 8.0
                  }
                  "M " ++
                  fromPoint.x->Float.toString ++
                  " " ++
                  fromPoint.y->Float.toString ++
                  " L " ++
                  exitX->Float.toString ++
                  " " ++
                  fromPoint.y->Float.toString ++
                  " L " ++
                  exitX->Float.toString ++
                  " " ++
                  chosenY->Float.toString ++
                  " L " ++
                  toPoint.x->Float.toString ++
                  " " ++
                  chosenY->Float.toString ++
                  " L " ++
                  toPoint.x->Float.toString ++
                  " " ++
                  toPoint.y->Float.toString
                }
              } else {
                let elbowX = if toPoint.x >= fromPoint.x {
                  fromPoint.x +. 10.0
                } else {
                  fromPoint.x -. 10.0
                }
                "M " ++
                fromPoint.x->Float.toString ++
                " " ++
                fromPoint.y->Float.toString ++
                " L " ++
                elbowX->Float.toString ++
                " " ++
                fromPoint.y->Float.toString ++
                " L " ++
                elbowX->Float.toString ++
                " " ++
                toPoint.y->Float.toString ++
                " L " ++
                toPoint.x->Float.toString ++
                " " ++
                toPoint.y->Float.toString
              }

              Some({
                id: edge.id,
                d,
                className: "pipeline-edge-line",
                clipId,
              })
            }
          | _ => None
          }
        })
        let sameFloorPairKeys = Belt.MutableSet.String.make()
        nextPaths->Belt.Array.forEach(path => {
          let edgeOpt = uniqueEdges->Belt.Array.getBy(edge => edge.id == path.id)
          switch edgeOpt {
          | Some(edge) =>
            let a = edge.fromSceneId
            let b = edge.toSceneId
            let key = if a <= b {
              a ++ "<->" ++ b
            } else {
              b ++ "<->" ++ a
            }
            sameFloorPairKeys->Belt.MutableSet.String.add(key)
          | None => ()
          }
        })
        let continuityPathsQueue = Belt.MutableQueue.make()
        activeFloors->Belt.Array.forEach(fid => {
          let rowItems = groupedItems->Belt.MutableMap.String.get(fid)->Option.getOr([])
          let rowCount = Belt.Array.length(rowItems)
          if rowCount >= 2 {
            let fromIdx = rowCount - 2
            let toIdx = rowCount - 1
            switch (Belt.Array.get(rowItems, fromIdx), Belt.Array.get(rowItems, toIdx)) {
            | (Some(node), Some(nextNode)) =>
              let fromIsBranch =
                stableHubTargetClusters
                ->Belt.MutableMap.String.get(node.representedSceneId)
                ->Option.isSome
              let toIsBranch =
                stableHubTargetClusters
                ->Belt.MutableMap.String.get(nextNode.representedSceneId)
                ->Option.isSome
              if !(fromIsBranch || toIsBranch) {
                let a = node.representedSceneId
                let b = nextNode.representedSceneId
                let pairKey = if a <= b {
                  a ++ "<->" ++ b
                } else {
                  b ++ "<->" ++ a
                }
                if !(sameFloorPairKeys->Belt.MutableSet.String.has(pairKey)) {
                  switch (
                    centers->Belt.MutableMap.String.get(node.id),
                    centers->Belt.MutableMap.String.get(nextNode.id),
                  ) {
                  | (Some(fromPoint), Some(toPoint)) =>
                    let clipId = floorClipIds->Belt.MutableMap.String.get(fid)
                    let d = if Math.abs(fromPoint.y -. toPoint.y) < 0.6 {
                      "M " ++
                      fromPoint.x->Float.toString ++
                      " " ++
                      fromPoint.y->Float.toString ++
                      " L " ++
                      toPoint.x->Float.toString ++
                      " " ++
                      toPoint.y->Float.toString
                    } else {
                      let elbowX = fromPoint.x +. 10.0
                      "M " ++
                      fromPoint.x->Float.toString ++
                      " " ++
                      fromPoint.y->Float.toString ++
                      " L " ++
                      elbowX->Float.toString ++
                      " " ++
                      fromPoint.y->Float.toString ++
                      " L " ++
                      elbowX->Float.toString ++
                      " " ++
                      toPoint.y->Float.toString ++
                      " L " ++
                      toPoint.x->Float.toString ++
                      " " ++
                      toPoint.y->Float.toString
                    }
                    continuityPathsQueue->Belt.MutableQueue.add({
                      id: "row-link-" ++ fid ++ "-" ++ node.id ++ "-" ++ nextNode.id,
                      d,
                      className: "pipeline-edge-line",
                      clipId,
                    })
                  | _ => ()
                  }
                }
              }
            | _ => ()
            }
          }
        })
        let continuityPaths = continuityPathsQueue->Belt.MutableQueue.toArray
        let mergedPaths = Belt.Array.concat(nextPaths, continuityPaths)
        setSceneEdgePaths(_ => mergedPaths)
        None
      }
    }
  }, (
    graph,
    displayNodes,
    groupedItems,
    activeFloors,
    uiSlice.isTeasing,
    uiSlice.isLinking,
    stableHubTargetClusters,
  ))

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

      <div
        className="visual-pipeline-wrapper"
        style={ReBindings.makeStyle({"pointerEvents": "none"})}
        ref={wrapperRef->ReactDOM.Ref.domRef}
      >
        <svg className="pipeline-scene-svg-overlay">
          <defs>
            {sceneEdgeClips
            ->Belt.Array.map(clip =>
              <clipPath key={"scene-edge-clip-" ++ clip.id} id={clip.id}>
                <rect
                  x={clip.x->Float.toString}
                  y={clip.y->Float.toString}
                  width={clip.width->Float.toString}
                  height={clip.height->Float.toString}
                />
              </clipPath>
            )
            ->React.array}
          </defs>
          {sceneEdgePaths
          ->Belt.Array.map(edge =>
            switch edge.clipId {
            | Some(clipId) =>
              <path
                key={"scene-edge-" ++ edge.id}
                d={edge.d}
                className={edge.className}
                clipPath={"url(#" ++ clipId ++ ")"}
              />
            | None => <path key={"scene-edge-" ++ edge.id} d={edge.d} className={edge.className} />
            }
          )
          ->React.array}
        </svg>

        /* Floor Tracks */
        {activeFloors
        ->Belt.Array.map(fid => {
          let items = groupedItems->Belt.MutableMap.String.get(fid)->Option.getOr([])
          let maxUpStepsRef = ref(0)
          let maxDownStepsRef = ref(0)
          items->Belt.Array.forEach(rowNode => {
            switch stableHubTargetClusters->Belt.MutableMap.String.get(rowNode.representedSceneId) {
            | Some(cluster) =>
              let level = cluster.rank / 2 + 1
              if cluster.rank % 2 == 0 {
                if level > maxDownStepsRef.contents {
                  maxDownStepsRef := level
                }
              } else if level > maxUpStepsRef.contents {
                maxUpStepsRef := level
              }
            | None => ()
            }
          })
          let laneTopPaddingPx = 6.0 +. maxUpStepsRef.contents->Int.toFloat *. branchRisePx
          let laneBottomPaddingPx = 6.0 +. maxDownStepsRef.contents->Int.toFloat *. branchRisePx
          let laneMinHeightPx = 12.0 +. laneTopPaddingPx +. laneBottomPaddingPx
          let trackStyle = ReBindings.makeStyle({
            "paddingTop": laneTopPaddingPx->Float.toString ++ "px",
            "paddingBottom": laneBottomPaddingPx->Float.toString ++ "px",
            "minHeight": laneMinHeightPx->Float.toString ++ "px",
          })
          let sceneIndexInRow = Belt.MutableMap.String.make()
          items->Belt.Array.forEachWithIndex((rowIdx, rowNode) => {
            sceneIndexInRow->Belt.MutableMap.String.set(rowNode.representedSceneId, rowIdx)
          })
          <div
            id={"pipeline-track-" ++ fid}
            key={"track-" ++ fid}
            className="pipeline-track"
            style={trackStyle}
          >
            {items
            ->Belt.Array.mapWithIndex((idx, node) => {
              let isActive =
                effectiveActiveNodeId
                ->Option.map(activeId => activeId == node.id)
                ->Option.getOr(false)

              let sourceScene =
                pipelineSlice.scenes->Belt.Array.getBy(s => s.id == node.sourceSceneId)
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
              let (sx, sy) = switch stableHubTargetClusters->Belt.MutableMap.String.get(
                node.representedSceneId,
              ) {
              | Some(cluster) =>
                switch sceneIndexInRow->Belt.MutableMap.String.get(cluster.hubSceneId) {
                | Some(hubRowIdx) =>
                  let stackColumn = hubRowIdx + 1
                  let delta = stackColumn - idx
                  let dx = nodePitchPx *. delta->Int.toFloat
                  let dy = branchYOffsetForRank(cluster.rank)
                  (dx, dy)
                | None => (0.0, 0.0)
                }
              | None => (0.0, 0.0)
              }
              let nodeShiftStyle = ReBindings.makeStyle({
                "transform": "translate(" ++
                sx->Float.toString ++
                "px, " ++
                sy->Float.toString ++ "px)",
              })

              <div id={"pipeline-node-wrap-" ++ node.id} key={node.id} style={nodeShiftStyle}>
                <VisualPipelineNode
                  item
                  nodeDomId={"pipeline-node-" ++ node.id}
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
