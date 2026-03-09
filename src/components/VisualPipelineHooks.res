type sceneEdgePath = VisualPipelineEdgeTypes.sceneEdgePath
type sceneEdgeClip = VisualPipelineEdgeTypes.sceneEdgeClip
type uiSliceFlags = {isLinking: bool, isTeasing: bool}

let useHoverPreviewCleanup = (
  ~hoverTimerRef: React.ref<option<int>>,
  ~activePreviewUrlRef: React.ref<string>,
) => {
  React.useEffect0(() => {
    Some(
      () => {
        VisualPipelineHover.clearHoverTimer(hoverTimerRef)
        let prevUrl = activePreviewUrlRef.current
        if prevUrl != "" {
          UrlUtils.revokeUrl(prevUrl)
        }
      },
    )
  })
}

let useFloorConnectorPaths = (
  ~activeFloors,
  ~groupedItems,
  ~containerRef: React.ref<Nullable.t<Dom.element>>,
  ~setLinePaths,
  ~uiSlice: uiSliceFlags,
) => {
  React.useLayoutEffect4(() => {
    if uiSlice.isTeasing {
      None
    } else {
      let container = containerRef.current->Nullable.toOption
      let {paths, missingAnchors} = switch container {
      | Some(containerEl) =>
        VisualPipelineFloorLines.measureFloorConnectorPaths(
          ~activeFloors,
          ~groupedItems,
          ~containerEl,
        )
      | None => {paths: Dict.make(), missingAnchors: true}
      }
      setLinePaths(prev =>
        VisualPipelineFloorLines.reconcileMeasuredPaths(~prev, ~next=paths, ~missingAnchors)
      )
      None
    }
  }, (activeFloors, groupedItems, uiSlice.isLinking, uiSlice.isTeasing))
}

let useSceneEdgeGeometry = (
  ~graph,
  ~displayNodes,
  ~groupedItems,
  ~activeFloors,
  ~sceneOrderIndex,
  ~stableHubTargetClusters,
  ~wrapperRef: React.ref<Nullable.t<Dom.element>>,
  ~setSceneEdgePaths,
  ~setSceneEdgeClips,
  ~uiSlice: uiSliceFlags,
) => {
  React.useLayoutEffect6(() => {
    if uiSlice.isTeasing || uiSlice.isLinking {
      setSceneEdgePaths((_): array<sceneEdgePath> => [])
      setSceneEdgeClips((_): array<sceneEdgeClip> => [])
      None
    } else {
      switch wrapperRef.current->Nullable.toOption {
      | None => None
      | Some(wrapper) =>
        let {sceneEdgePaths: nextPaths, sceneEdgeClips: nextClips} =
          VisualPipelineEdges.buildEdgeGeometry(
            ~graph,
            ~displayNodes,
            ~groupedItems,
            ~activeFloors,
            ~sceneOrderIndex,
            ~stableHubTargetClusters,
            ~wrapper,
          )
        setSceneEdgeClips(_ => nextClips)
        setSceneEdgePaths(_ => nextPaths)
        None
      }
    }
  }, (
    graph,
    displayNodes,
    groupedItems,
    activeFloors,
    sceneOrderIndex,
    stableHubTargetClusters,
  ))
}
