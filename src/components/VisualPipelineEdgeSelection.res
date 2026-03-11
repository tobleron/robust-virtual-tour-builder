type clusterInfo = VisualPipelineData.clusterInfo

let floorPairKey = (a: string, b: string): string =>
  if a <= b {
    a ++ "<->" ++ b
  } else {
    b ++ "<->" ++ a
  }

let chooseDirectedEdge = (
  ~sceneOrderIndex: Belt.Map.String.t<int>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  candidates: array<VisualPipelineGraph.edge>,
): option<VisualPipelineGraph.edge> =>
  candidates
  ->Belt.Array.reduce((None: option<(VisualPipelineGraph.edge, int)>), (best, edge) => {
    let hubForward =
      stableHubTargetClusters
      ->Belt.MutableMap.String.get(edge.toSceneId)
      ->Option.map(cluster => cluster.hubSceneId == edge.fromSceneId)
      ->Option.getOr(false)
    let fromRank = sceneOrderIndex->Belt.Map.String.get(edge.fromSceneId)->Option.getOr(100000)
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

let buildUniqueForwardEdges = (
  ~graph: VisualPipelineGraph.graph,
  ~sceneOrderIndex: Belt.Map.String.t<int>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
) => {
  let pairEdgeCandidates = Belt.MutableMap.String.make()
  let pairOrder = Belt.MutableQueue.make()
  graph.edges->Belt.Array.forEach(edge => {
    let pairKey = floorPairKey(edge.fromSceneId, edge.toSceneId)
    switch pairEdgeCandidates->Belt.MutableMap.String.get(pairKey) {
    | Some(existing) =>
      pairEdgeCandidates->Belt.MutableMap.String.set(pairKey, Belt.Array.concat(existing, [edge]))
    | None =>
      pairEdgeCandidates->Belt.MutableMap.String.set(pairKey, [edge])
      pairOrder->Belt.MutableQueue.add(pairKey)
    }
  })

  pairOrder
  ->Belt.MutableQueue.toArray
  ->Belt.Array.keepMap(pairKey =>
    pairEdgeCandidates
    ->Belt.MutableMap.String.get(pairKey)
    ->Option.flatMap(candidates =>
      chooseDirectedEdge(~sceneOrderIndex, ~stableHubTargetClusters, candidates)
    )
  )
  ->Belt.Array.keep(edge => edge.kind == Forward)
}
