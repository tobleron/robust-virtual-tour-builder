type clusterInfo = {hubSceneId: string, rank: int, branchCount: int}

let floorIdForScene = (scenes: array<Types.scene>, sceneId: string): string =>
  scenes
  ->Belt.Array.getBy(scene => scene.id == sceneId)
  ->Option.map(scene => scene.floor == "" ? "ground" : scene.floor)
  ->Option.getOr("ground")

let sceneRank = (
  sceneOrderIndex: Belt.Map.String.t<int>,
  sceneId: string,
  ~fallback: int=10000,
): int => sceneOrderIndex->Belt.Map.String.get(sceneId)->Option.getOr(fallback)

let buildSceneOrderIndex = (displayNodes: array<VisualPipelineGraph.node>): Belt.Map.String.t<
  int,
> =>
  displayNodes->Belt.Array.reduce(Belt.Map.String.empty, (acc, node) => {
    if acc->Belt.Map.String.get(node.representedSceneId)->Option.isSome {
      acc
    } else {
      Belt.Map.String.set(acc, node.representedSceneId, node.order)
    }
  })

let reduceBestParent = (
  sources: array<string>,
  sceneOrderIndex: Belt.Map.String.t<int>,
  ~preferHigherRank: bool,
): option<string> =>
  sources
  ->Belt.Array.reduce((None: option<(string, int)>), (acc, src) => {
    let rank = sceneRank(sceneOrderIndex, src)
    let keepExisting = switch acc {
    | Some((_bestSceneId, bestRank)) => preferHigherRank ? rank >= bestRank : rank <= bestRank
    | None => false
    }
    switch acc {
    | Some(_) if keepExisting => acc
    | _ => Some((src, rank))
    }
  })
  ->Option.map(((sceneId, _rank)) => sceneId)

let buildParentByScene = (
  ~graph: VisualPipelineGraph.graph,
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~sceneOrderIndex: Belt.Map.String.t<int>,
) => {
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
    let sources = incomingByScene->Belt.MutableMap.String.get(sceneId)->Option.getOr([])
    let currentRank = sceneRank(sceneOrderIndex, sceneId)
    let earlierSources =
      sources->Belt.Array.keep(src => sceneRank(sceneOrderIndex, src) < currentRank)
    let parentOpt = if Belt.Array.length(earlierSources) > 0 {
      reduceBestParent(earlierSources, sceneOrderIndex, ~preferHigherRank=true)
    } else {
      reduceBestParent(sources, sceneOrderIndex, ~preferHigherRank=false)
    }

    switch parentOpt {
    | Some(parentId) => parents->Belt.MutableMap.String.set(sceneId, parentId)
    | None => ()
    }
  })
  parents
}

let groupItemsByFloor = (
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~scenes: array<Types.scene>,
  ~sceneOrderIndex: Belt.Map.String.t<int>,
) => {
  let groups = Belt.MutableMap.String.make()
  displayNodes->Belt.Array.forEach(node => {
    let floorId = floorIdForScene(scenes, node.representedSceneId)
    let existing = groups->Belt.MutableMap.String.get(floorId)->Option.getOr([])
    groups->Belt.MutableMap.String.set(floorId, Belt.Array.concat(existing, [node]))
  })

  groups
  ->Belt.MutableMap.String.keysToArray
  ->Belt.Array.forEach(floorId => {
    let items = groups->Belt.MutableMap.String.get(floorId)->Option.getOr([])
    let sorted =
      items->Belt.SortArray.stableSortBy((a, b) =>
        sceneRank(sceneOrderIndex, a.representedSceneId) -
        sceneRank(sceneOrderIndex, b.representedSceneId)
      )
    groups->Belt.MutableMap.String.set(floorId, sorted)
  })

  groups
}

let buildStableHubTargetClusters = (
  ~graph: VisualPipelineGraph.graph,
  ~scenes: array<Types.scene>,
  ~sceneOrderIndex: Belt.Map.String.t<int>,
  ~parentByScene,
) => {
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
    let hubFloor = floorIdForScene(scenes, hubSceneId)
    let sameFloorTargets =
      branchTargets->Belt.Array.keep(targetSceneId =>
        floorIdForScene(scenes, targetSceneId) == hubFloor
      )

    if Belt.Array.length(sameFloorTargets) >= 2 {
      let sortedTargets = sameFloorTargets->Belt.SortArray.stableSortBy((a, b) => {
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
          sceneRank(sceneOrderIndex, a) - sceneRank(sceneOrderIndex, b)
        }
      })
      let branchCount = Belt.Array.length(sortedTargets)
      sortedTargets->Belt.Array.forEachWithIndex((rank, targetSceneId) => {
        switch clusters->Belt.MutableMap.String.get(targetSceneId) {
        | Some(_) => ()
        | None =>
          clusters->Belt.MutableMap.String.set(targetSceneId, {hubSceneId, rank, branchCount})
        }
      })
    }
  })
  clusters
}

let sortActiveFloors = groupedItems =>
  groupedItems
  ->Belt.MutableMap.String.keysToArray
  ->Belt.Array.keep(fid => groupedItems->Belt.MutableMap.String.get(fid)->Option.isSome)
  ->Belt.SortArray.stableSortBy((a, b) => {
    let idxA = Constants.Scene.floorLevels->Belt.Array.getIndexBy(f => f.id == a)->Option.getOr(0)
    let idxB = Constants.Scene.floorLevels->Belt.Array.getIndexBy(f => f.id == b)->Option.getOr(0)
    idxA - idxB
  })
