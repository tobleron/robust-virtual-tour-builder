open VisualPipelineGraph

type hubInfo = {
  isHub: bool,
  branchCount: int,
  returnCount: int,
}

type hubMap = Belt.Map.String.t<hubInfo>

let emptyInfo = {isHub: false, branchCount: 0, returnCount: 0}

let detect = (graph: graph): hubMap => {
  let outgoingTargets = Belt.MutableMap.String.make()
  let returnCounts = Belt.MutableMap.String.make()

  graph.edges->Belt.Array.forEach(edge => {
    let existingTargets =
      outgoingTargets->Belt.MutableMap.String.get(edge.fromSceneId)->Option.getOr([])
    if !(existingTargets->Belt.Array.some(targetId => targetId == edge.toSceneId)) {
      outgoingTargets->Belt.MutableMap.String.set(
        edge.fromSceneId,
        Belt.Array.concat(existingTargets, [edge.toSceneId]),
      )
    }

    switch edge.kind {
    | Return =>
      let existingCount = returnCounts->Belt.MutableMap.String.get(edge.toSceneId)->Option.getOr(0)
      returnCounts->Belt.MutableMap.String.set(edge.toSceneId, existingCount + 1)
    | Forward => ()
    }
  })

  let map = Belt.Map.String.empty
  graph.nodes->Belt.Array.reduce(map, (acc, node) => {
    let branchCount =
      outgoingTargets
      ->Belt.MutableMap.String.get(node.representedSceneId)
      ->Option.map(Belt.Array.length)
      ->Option.getOr(0)
    let returnCount =
      returnCounts->Belt.MutableMap.String.get(node.representedSceneId)->Option.getOr(0)
    let info: hubInfo = {
      isHub: branchCount >= 2,
      branchCount,
      returnCount,
    }
    Belt.Map.String.set(acc, node.representedSceneId, info)
  })
}

let getInfo = (map: hubMap, sceneId: string): hubInfo =>
  map->Belt.Map.String.get(sceneId)->Option.getOr(emptyInfo)
