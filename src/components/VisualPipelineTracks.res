type clusterInfo = VisualPipelineData.clusterInfo

let buildTrackStyle = (
  ~items: array<VisualPipelineGraph.node>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  ~branchRisePx: float,
) => {
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
  ReBindings.makeStyle({
    "paddingTop": laneTopPaddingPx->Float.toString ++ "px",
    "paddingBottom": laneBottomPaddingPx->Float.toString ++ "px",
    "minHeight": laneMinHeightPx->Float.toString ++ "px",
  })
}

let buildSceneIndexInRow = (items: array<VisualPipelineGraph.node>) => {
  let sceneIndexInRow = Belt.MutableMap.String.make()
  items->Belt.Array.forEachWithIndex((rowIdx, rowNode) => {
    sceneIndexInRow->Belt.MutableMap.String.set(rowNode.representedSceneId, rowIdx)
  })
  sceneIndexInRow
}

let isAutoForward = (~sourceScene: option<Types.scene>, ~linkId: string): bool =>
  switch sourceScene {
  | Some(scene) =>
    scene.hotspots
    ->Belt.Array.getBy(h => h.linkId == linkId)
    ->Option.flatMap(h => h.isAutoForward)
    ->Option.getOr(false)
  | None => false
  }

let nodeShiftStyle = (
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  ~sceneIndexInRow: Belt.MutableMap.String.t<int>,
  ~node: VisualPipelineGraph.node,
  ~idx: int,
  ~nodePitchPx: float,
  ~branchYOffsetForRank: int => float,
) => {
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

  ReBindings.makeStyle({
    "transform": "translate(" ++ sx->Float.toString ++ "px, " ++ sy->Float.toString ++ "px)",
  })
}

@react.component
let make = (
  ~activeFloors: array<string>,
  ~groupedItems,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  ~branchRisePx: float,
  ~nodePitchPx: float,
  ~effectiveActiveNodeId: option<string>,
  ~pipelineScenes: array<Types.scene>,
  ~isSystemLocked: bool,
  ~branchYOffsetForRank: int => float,
  ~handleNodeActivate: string => unit,
  ~handleNodeRemove: string => unit,
  ~showHoverPreview: (option<Types.scene>, string) => unit,
  ~hideHoverPreview: unit => unit,
) => <>
  {activeFloors
  ->Belt.Array.map(fid => {
    let items = groupedItems->Belt.MutableMap.String.get(fid)->Option.getOr([])
    let trackStyle = buildTrackStyle(~items, ~stableHubTargetClusters, ~branchRisePx)
    let sceneIndexInRow = buildSceneIndexInRow(items)
    <div
      id={"pipeline-track-" ++ fid}
      key={"track-" ++ fid}
      className="pipeline-track"
      style={trackStyle}
    >
      {items
      ->Belt.Array.mapWithIndex((idx, node) => {
        let isActive =
          effectiveActiveNodeId->Option.map(activeId => activeId == node.id)->Option.getOr(false)
        let sourceScene = pipelineScenes->Belt.Array.getBy(s => s.id == node.sourceSceneId)
        let representedScene =
          pipelineScenes->Belt.Array.getBy(s => s.id == node.representedSceneId)
        let item: VisualPipelineNode.nodeItem = {nodeId: node.id, linkId: node.linkId}
        let style = nodeShiftStyle(
          ~stableHubTargetClusters,
          ~sceneIndexInRow,
          ~node,
          ~idx,
          ~nodePitchPx,
          ~branchYOffsetForRank,
        )

        <div id={"pipeline-node-wrap-" ++ node.id} key={node.id} style>
          <VisualPipelineNode
            item
            nodeDomId={"pipeline-node-" ++ node.id}
            isActive
            interactionDisabled=isSystemLocked
            scene=representedScene
            isAutoForward={isAutoForward(~sourceScene, ~linkId=node.linkId)}
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
</>
