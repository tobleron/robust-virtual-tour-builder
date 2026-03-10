type scenePoint = VisualPipelineEdgeTypes.scenePoint
type sceneEdgePath = VisualPipelineEdgeTypes.sceneEdgePath
type clusterInfo = VisualPipelineData.clusterInfo

let hasNodeCollisionOnHorizontal = (
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~centers: Belt.MutableMap.String.t<scenePoint>,
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

let edgePathForPair = (
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~centers: Belt.MutableMap.String.t<scenePoint>,
  ~floorClipIds: Belt.MutableMap.String.t<string>,
  ~floorByScene: Belt.MutableMap.String.t<string>,
  ~sameFloorOutgoing: Belt.MutableMap.String.t<array<string>>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  edge: VisualPipelineGraph.edge,
): option<sceneEdgePath> => {
  switch (
    centers->Belt.MutableMap.String.get(edge.fromNodeId),
    centers->Belt.MutableMap.String.get(edge.toNodeId),
  ) {
  | (Some(fromPoint), Some(toPoint)) =>
    let fromFloor = floorByScene->Belt.MutableMap.String.get(edge.fromSceneId)
    let toFloor = floorByScene->Belt.MutableMap.String.get(edge.toSceneId)
    if fromFloor != toFloor {
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
      let hubClusterForTarget = stableHubTargetClusters->Belt.MutableMap.String.get(edge.toSceneId)
      let d = if (
        isHubFanout &&
        hubClusterForTarget
        ->Option.map(cluster => cluster.hubSceneId == edge.fromSceneId)
        ->Option.getOr(false)
      ) {
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
          ~displayNodes,
          ~centers,
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
            ~displayNodes,
            ~centers,
            ~floorId,
            ~fromNodeId=edge.fromNodeId,
            ~toNodeId=edge.toNodeId,
            ~lineY=detourUp,
            ~xA=fromPoint.x,
            ~xB=toPoint.x,
          )
          let chosenY = if !upCollision {detourUp} else {detourDown}
          let exitX = if toPoint.x >= fromPoint.x {fromPoint.x +. 8.0} else {fromPoint.x -. 8.0}
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
        let elbowX = if toPoint.x >= fromPoint.x {fromPoint.x +. 10.0} else {fromPoint.x -. 10.0}
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

      Some({id: edge.id, d, className: "pipeline-edge-line", clipId})
    }
  | _ => None
  }
}

let buildContinuityPaths = (
  ~activeFloors: array<string>,
  ~groupedItems,
  ~centers: Belt.MutableMap.String.t<scenePoint>,
  ~floorClipIds: Belt.MutableMap.String.t<string>,
  ~stableHubTargetClusters: Belt.MutableMap.String.t<clusterInfo>,
  ~sameFloorPairKeys: Belt.MutableSet.String.t,
) => {
  let continuityPathsQueue = Belt.MutableQueue.make()
  activeFloors->Belt.Array.forEach(fid => {
    let rowItems = groupedItems->Belt.MutableMap.String.get(fid)->Option.getOr([])
    let rowCount = Belt.Array.length(rowItems)
    if rowCount >= 2 {
      let fromIdx = rowCount - 2
      let toIdx = rowCount - 1
      switch (Belt.Array.get(rowItems, fromIdx), Belt.Array.get(rowItems, toIdx)) {
      | (Some((node: VisualPipelineGraph.node)), Some((nextNode: VisualPipelineGraph.node))) =>
        let fromIsBranch =
          stableHubTargetClusters
          ->Belt.MutableMap.String.get(node.representedSceneId)
          ->Option.isSome
        let toIsBranch =
          stableHubTargetClusters
          ->Belt.MutableMap.String.get(nextNode.representedSceneId)
          ->Option.isSome
        if !(fromIsBranch || toIsBranch) {
          let pairKey =
            VisualPipelineEdgeSelection.floorPairKey(
              node.representedSceneId,
              nextNode.representedSceneId,
            )
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
              continuityPathsQueue->Belt.MutableQueue.add(({
                id: "row-link-" ++ fid ++ "-" ++ node.id ++ "-" ++ nextNode.id,
                d,
                className: "pipeline-edge-line",
                clipId,
              }: sceneEdgePath))
            | _ => ()
            }
          }
        }
      | _ => ()
      }
    }
  })
  continuityPathsQueue->Belt.MutableQueue.toArray
}
