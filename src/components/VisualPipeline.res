/* src/components/VisualPipeline.res - Visual Pipeline V3: Scalable Floor-Grouped Squares */

type hoverPreview = VisualPipelineHover.hoverPreview
type sceneEdgePath = VisualPipelineEdgeTypes.sceneEdgePath
type sceneEdgeClip = VisualPipelineEdgeTypes.sceneEdgeClip
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
let injectStyles = () => VisualPipelineStyles.inject()

let renderTracks = (
  ~activeFloors,
  ~groupedItems,
  ~stableHubTargetClusters,
  ~effectiveActiveNodeId,
  ~pipelineScenes,
  ~isSystemLocked,
  ~handleNodeActivate,
  ~handleNodeRemove,
  ~showHoverPreview,
  ~hideHoverPreview,
) =>
  <VisualPipelineTracks
    activeFloors
    groupedItems
    stableHubTargetClusters
    branchRisePx
    nodePitchPx
    effectiveActiveNodeId
    pipelineScenes
    isSystemLocked
    branchYOffsetForRank
    handleNodeActivate
    handleNodeRemove
    showHoverPreview
    hideHoverPreview
  />

let renderChrome = (
  ~isSystemLocked,
  ~activeFloors,
  ~linePaths,
  ~wrapperRef,
  ~sceneEdgeClips,
  ~sceneEdgePaths,
  ~tracks,
  ~hoverPreview,
) =>
  <VisualPipelineChrome
    isSystemLocked
    activeFloors
    linePaths
    wrapperRef
    sceneEdgeClips
    sceneEdgePaths
    tracks
    hoverPreview
  />

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
  let sceneOrderIndex = React.useMemo1(
    () => VisualPipelineData.buildSceneOrderIndex(displayNodes),
    [displayNodes],
  )
  let parentByScene = React.useMemo3(
    () => VisualPipelineData.buildParentByScene(~graph, ~displayNodes, ~sceneOrderIndex),
    (graph, displayNodes, sceneOrderIndex),
  )
  let handleNodeActivate = (itemId: string) =>
    VisualPipelineActions.handleNodeActivate(~isSystemLocked, ~displayNodes, ~dispatch, itemId)

  let handleNodeRemove = (itemId: string) =>
    VisualPipelineActions.handleNodeRemove(~isSystemLocked, ~displayNodes, ~dispatch, itemId)

  let groupedItems = React.useMemo3(
    () =>
      VisualPipelineData.groupItemsByFloor(
        ~displayNodes,
        ~scenes=pipelineSlice.scenes,
        ~sceneOrderIndex,
      ),
    (displayNodes, pipelineSlice.scenes, sceneOrderIndex),
  )

  let stableHubTargetClusters = React.useMemo4(
    () =>
      VisualPipelineData.buildStableHubTargetClusters(
        ~graph,
        ~scenes=pipelineSlice.scenes,
        ~sceneOrderIndex,
        ~parentByScene,
      ),
    (graph, pipelineSlice.scenes, sceneOrderIndex, parentByScene),
  )

  let activeFloors = React.useMemo1(
    () => VisualPipelineData.sortActiveFloors(groupedItems),
    [groupedItems],
  )

  let effectiveActiveNodeId = React.useMemo2(() => {
    let currentSceneId =
      Belt.Array.get(pipelineSlice.scenes, pipelineSlice.activeIndex)->Option.map(scene => scene.id)
    currentSceneId->Option.flatMap(sceneId =>
      displayNodes
      ->Belt.Array.getBy(node => node.representedSceneId == sceneId)
      ->Option.map(node => node.id)
    )
  }, (pipelineSlice.activeIndex, displayNodes))

  let (linePaths, setLinePaths) = React.useState(_ => Dict.make())
  let containerRef = React.useRef(Nullable.null)
  let wrapperRef = React.useRef(Nullable.null)
  let (sceneEdgePaths, setSceneEdgePaths) = React.useState((): array<sceneEdgePath> => [])
  let (sceneEdgeClips, setSceneEdgeClips) = React.useState((): array<sceneEdgeClip> => [])
  let (hoverPreview, setHoverPreview) = React.useState((): option<hoverPreview> => None)
  let hoverTimerRef = React.useRef((None: option<int>))
  let activePreviewUrlRef = React.useRef("")

  let hideHoverPreview = () =>
    VisualPipelineHover.hideHoverPreview(~hoverTimerRef, ~activePreviewUrlRef, ~setHoverPreview)

  let showHoverPreview = (sceneOpt: option<Types.scene>, _linkId: string) =>
    VisualPipelineHover.showHoverPreview(
      ~isSystemLocked,
      ~hoverTimerRef,
      ~activePreviewUrlRef,
      ~setHoverPreview,
      ~sceneOpt,
    )

  React.useEffect1(() => {
    if isSystemLocked {
      hideHoverPreview()
    }
    None
  }, [isSystemLocked])
  VisualPipelineHooks.useHoverPreviewCleanup(~hoverTimerRef, ~activePreviewUrlRef)
  VisualPipelineHooks.useFloorConnectorPaths(
    ~activeFloors,
    ~groupedItems,
    ~containerRef,
    ~setLinePaths,
    ~uiSlice=(uiSlice :> VisualPipelineHooks.uiSliceFlags),
  )
  VisualPipelineHooks.useSceneEdgeGeometry(
    ~graph,
    ~displayNodes,
    ~groupedItems,
    ~activeFloors,
    ~sceneOrderIndex,
    ~stableHubTargetClusters,
    ~wrapperRef,
    ~setSceneEdgePaths,
    ~setSceneEdgeClips,
    ~uiSlice=(uiSlice :> VisualPipelineHooks.uiSliceFlags),
  )

  if uiSlice.isLinking || uiSlice.isTeasing || activeFloors->Belt.Array.length == 0 {
    React.null
  } else {
    let tracks = renderTracks(
      ~activeFloors,
      ~groupedItems,
      ~stableHubTargetClusters,
      ~effectiveActiveNodeId,
      ~pipelineScenes=pipelineSlice.scenes,
      ~isSystemLocked,
      ~handleNodeActivate,
      ~handleNodeRemove,
      ~showHoverPreview,
      ~hideHoverPreview,
    )
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
      {renderChrome(
        ~isSystemLocked,
        ~activeFloors,
        ~linePaths,
        ~wrapperRef,
        ~sceneEdgeClips,
        ~sceneEdgePaths,
        ~tracks,
        ~hoverPreview,
      )}
    </div>
  }
}
