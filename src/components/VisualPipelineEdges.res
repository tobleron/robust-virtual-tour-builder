open ReBindings

type scenePoint = VisualPipelineEdgeTypes.scenePoint
type sceneEdgePath = VisualPipelineEdgeTypes.sceneEdgePath
type sceneEdgeClip = VisualPipelineEdgeTypes.sceneEdgeClip
type clusterInfo = VisualPipelineData.clusterInfo
type floorBand = VisualPipelineEdgeTypes.floorBand

type edgeGeometry = {
  sceneEdgePaths: array<sceneEdgePath>,
  sceneEdgeClips: array<sceneEdgeClip>,
}

let floorPairKey = (a: string, b: string): string => VisualPipelineEdgeSelection.floorPairKey(a, b)

let buildFloorMaps = (
  ~wrapperRect: Dom.rect,
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~activeFloors: array<string>,
): (
  Belt.MutableMap.String.t<scenePoint>,
  Belt.MutableMap.String.t<string>,
  array<sceneEdgeClip>,
  Belt.MutableMap.String.t<string>,
) => VisualPipelineEdgeMaps.buildFloorMaps(~wrapperRect, ~displayNodes, ~activeFloors)

let buildSameFloorOutgoing = (
  ~graph: VisualPipelineGraph.graph,
  ~floorByScene: Belt.MutableMap.String.t<string>,
) => VisualPipelineEdgeMaps.buildSameFloorOutgoing(~graph, ~floorByScene)

let hasNodeCollisionOnHorizontal = (
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~centers: Belt.MutableMap.String.t<scenePoint>,
  ~floorId: string,
  ~fromNodeId: string,
  ~toNodeId: string,
  ~lineY: float,
  ~xA: float,
  ~xB: float,
): bool =>
  VisualPipelineEdgePaths.hasNodeCollisionOnHorizontal(
    ~displayNodes,
    ~centers,
    ~floorId,
    ~fromNodeId,
    ~toNodeId,
    ~lineY,
    ~xA,
    ~xB,
  )

let chooseDirectedEdge = (
  ~sceneOrderIndex: Belt.Map.String.t<int>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  candidates: array<VisualPipelineGraph.edge>,
): option<VisualPipelineGraph.edge> =>
  VisualPipelineEdgeSelection.chooseDirectedEdge(
    ~sceneOrderIndex,
    ~stableHubTargetClusters,
    candidates,
  )

let buildUniqueForwardEdges = (
  ~graph: VisualPipelineGraph.graph,
  ~sceneOrderIndex: Belt.Map.String.t<int>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
) =>
  VisualPipelineEdgeSelection.buildUniqueForwardEdges(
    ~graph,
    ~sceneOrderIndex,
    ~stableHubTargetClusters,
  )

let edgePathForPair = (
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~centers: Belt.MutableMap.String.t<scenePoint>,
  ~floorClipIds: Belt.MutableMap.String.t<string>,
  ~floorByScene: Belt.MutableMap.String.t<string>,
  ~sameFloorOutgoing: Belt.MutableMap.String.t<array<string>>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  edge: VisualPipelineGraph.edge,
): option<sceneEdgePath> =>
  VisualPipelineEdgePaths.edgePathForPair(
    ~displayNodes,
    ~centers,
    ~floorClipIds,
    ~floorByScene,
    ~sameFloorOutgoing,
    ~stableHubTargetClusters,
    edge,
  )

let buildContinuityPaths = (
  ~activeFloors: array<string>,
  ~groupedItems,
  ~centers: Belt.MutableMap.String.t<scenePoint>,
  ~floorClipIds: Belt.MutableMap.String.t<string>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  ~sameFloorPairKeys: Belt.MutableSet.String.t,
) =>
  VisualPipelineEdgePaths.buildContinuityPaths(
    ~activeFloors,
    ~groupedItems,
    ~centers,
    ~floorClipIds,
    ~stableHubTargetClusters,
    ~sameFloorPairKeys,
  )

let buildEdgeGeometry = (
  ~graph: VisualPipelineGraph.graph,
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~groupedItems,
  ~activeFloors: array<string>,
  ~sceneOrderIndex: Belt.Map.String.t<int>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  ~wrapper: Dom.element,
): edgeGeometry => {
  let wrapperRect = wrapper->Dom.getBoundingClientRect
  let (centers, floorByScene, sceneEdgeClips, floorClipIds) = buildFloorMaps(
    ~wrapperRect,
    ~displayNodes,
    ~activeFloors,
  )
  let sameFloorOutgoing = buildSameFloorOutgoing(~graph, ~floorByScene)
  let uniqueEdges = buildUniqueForwardEdges(~graph, ~sceneOrderIndex, ~stableHubTargetClusters)
  let nextPaths =
    uniqueEdges->Belt.Array.keepMap(edge =>
      edgePathForPair(
        ~displayNodes,
        ~centers,
        ~floorClipIds,
        ~floorByScene,
        ~sameFloorOutgoing,
        ~stableHubTargetClusters,
        edge,
      )
    )
  let sameFloorPairKeys = Belt.MutableSet.String.make()
  nextPaths->Belt.Array.forEach(path => {
    let edgeOpt = uniqueEdges->Belt.Array.getBy(edge => edge.id == path.id)
    switch edgeOpt {
    | Some(edge) =>
      sameFloorPairKeys->Belt.MutableSet.String.add(floorPairKey(edge.fromSceneId, edge.toSceneId))
    | None => ()
    }
  })
  let continuityPaths = buildContinuityPaths(
    ~activeFloors,
    ~groupedItems,
    ~centers,
    ~floorClipIds,
    ~stableHubTargetClusters,
    ~sameFloorPairKeys,
  )

  {sceneEdgePaths: Belt.Array.concat(nextPaths, continuityPaths), sceneEdgeClips}
}
