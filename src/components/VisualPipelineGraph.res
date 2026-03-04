open Types

type node = {
  id: string,
  timelineId: option<string>,
  representedSceneId: string,
  sourceSceneId: string,
  linkId: string,
  order: int,
  floorId: string,
}

type edgeKind =
  | Forward
  | Return

type edge = {
  id: string,
  fromNodeId: string,
  toNodeId: string,
  fromSceneId: string,
  toSceneId: string,
  kind: edgeKind,
  isCrossFloor: bool,
}

type graph = {
  nodes: array<node>,
  edges: array<edge>,
}

type traversalEdge = {
  fromSceneId: string,
  toSceneId: string,
}

type traversal = {
  sceneOrder: array<string>,
  edges: array<traversalEdge>,
}

let nodeIdForScene = (sceneId: string): string => "scene_" ++ sceneId

let floorOrGround = (sceneOpt: option<scene>): string =>
  switch sceneOpt {
  | Some(scene) => scene.floor == "" ? "ground" : scene.floor
  | None => "ground"
  }

let resolveSceneId = (~scenes: array<scene>, refValue: option<string>): option<string> =>
  refValue
  ->Belt.Option.flatMap(value => scenes->Belt.Array.getBy(s => s.id == value)->Option.map(s => s.id))
  ->Option.orElse(
    refValue->Belt.Option.flatMap(value =>
      scenes->Belt.Array.getBy(s => s.name == value)->Option.map(s => s.id)
    ),
  )

let resolveTargetSceneId = (~scenes: array<scene>, ~item: timelineItem): option<string> => {
  let timelineRef = item.targetScene != "" ? Some(item.targetScene) : None
  let sourceScene = scenes->Belt.Array.getBy(s => s.id == item.sceneId)
  let sourceHotspot =
    sourceScene->Option.flatMap(s => s.hotspots->Belt.Array.getBy(h => h.linkId == item.linkId))

  switch sourceHotspot {
  | Some(hotspot) =>
    hotspot.targetSceneId->Option.orElse(resolveSceneId(~scenes, timelineRef))
  | None => None
  }
}

let deriveTraversal = (~state: state, ~maxSteps: int=400): traversal => {
  let _ = maxSteps
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, 0) {
  | None => {sceneOrder: [], edges: []}
  | Some(startScene) =>
    let seenSceneIds = Belt.MutableSet.String.make()
    let sceneOrderQueue = Belt.MutableQueue.make()
    let edgeQueue = Belt.MutableQueue.make()

    let addSceneOnce = (sceneId: string) => {
      if !(seenSceneIds->Belt.MutableSet.String.has(sceneId)) {
        seenSceneIds->Belt.MutableSet.String.add(sceneId)
        sceneOrderQueue->Belt.MutableQueue.add(sceneId)
      }
    }

    addSceneOnce(startScene.id)
    let orderedHotspots = HotspotSequence.deriveOrderedHotspots(~state)
    orderedHotspots->Belt.Array.forEach(item => {
      addSceneOnce(item.sceneId)
      addSceneOnce(item.targetSceneId)
      if item.sceneId != item.targetSceneId {
        edgeQueue->Belt.MutableQueue.add({
          fromSceneId: item.sceneId,
          toSceneId: item.targetSceneId,
        })
      }
    })

    {
      sceneOrder: sceneOrderQueue->Belt.MutableQueue.toArray,
      edges: edgeQueue->Belt.MutableQueue.toArray,
    }
  }
}

let build = (
  ~scenes: array<scene>,
  ~timeline: array<timelineItem>,
  ~traversal: option<traversal>=None,
): graph => {
  let includedSceneIds = Belt.MutableSet.String.make()
  scenes->Belt.Array.forEach(scene => {
    if Belt.Array.length(scene.hotspots) > 0 {
      includedSceneIds->Belt.MutableSet.String.add(scene.id)
    }
  })

  let timelineOrder = Belt.MutableMap.String.make()
  timeline->Belt.Array.forEachWithIndex((idx, item) => {
    switch timelineOrder->Belt.MutableMap.String.get(item.sceneId) {
    | Some(_) => ()
    | None => timelineOrder->Belt.MutableMap.String.set(item.sceneId, idx)
    }
  })

  let traversalOrder = Belt.MutableMap.String.make()
  switch traversal {
  | Some(trace) =>
    trace.sceneOrder->Belt.Array.forEachWithIndex((idx, sceneId) => {
      switch traversalOrder->Belt.MutableMap.String.get(sceneId) {
      | Some(_) => ()
      | None => traversalOrder->Belt.MutableMap.String.set(sceneId, idx)
      }
    })
  | None => ()
  }

  let rankForScene = (s: scene): int =>
    switch traversalOrder->Belt.MutableMap.String.get(s.id) {
    | Some(rank) => rank
    | None => timelineOrder->Belt.MutableMap.String.get(s.id)->Option.getOr(100000 + s.sequenceId)
    }

  let orderedScenes =
    scenes
    ->Belt.SortArray.stableSortBy((a, b) => {
      let rankA = rankForScene(a)
      let rankB = rankForScene(b)
      if rankA != rankB {
        rankA - rankB
      } else {
        a.sequenceId - b.sequenceId
      }
    })

  let nodes =
    orderedScenes
    ->Belt.Array.keep(scene => includedSceneIds->Belt.MutableSet.String.has(scene.id))
    ->Belt.Array.mapWithIndex((idx, scene) => {
      {
        id: nodeIdForScene(scene.id),
        timelineId: None,
        representedSceneId: scene.id,
        sourceSceneId: scene.id,
        linkId: scene.id,
        order: idx,
        floorId: floorOrGround(Some(scene)),
      }
    })

  let seenVisit = Belt.MutableSet.String.make()
  let seenEdges = Belt.MutableSet.String.make()
  let edgesQueue = Belt.MutableQueue.make()

  let addEdge = (~id: string, ~fromSceneId: string, ~toSceneId: string, ()) => {
    let includeFrom = includedSceneIds->Belt.MutableSet.String.has(fromSceneId)
    let includeTo = includedSceneIds->Belt.MutableSet.String.has(toSceneId)
    if fromSceneId != toSceneId && includeFrom && includeTo {
      let key = fromSceneId ++ "->" ++ toSceneId
      if !(seenEdges->Belt.MutableSet.String.has(key)) {
        seenEdges->Belt.MutableSet.String.add(key)
        let kind = if seenVisit->Belt.MutableSet.String.has(toSceneId) { Return } else { Forward }
        edgesQueue->Belt.MutableQueue.add({
          id,
          fromNodeId: nodeIdForScene(fromSceneId),
          toNodeId: nodeIdForScene(toSceneId),
          fromSceneId,
          toSceneId,
          kind,
          isCrossFloor:
            floorOrGround(scenes->Belt.Array.getBy(s => s.id == fromSceneId)) !=
            floorOrGround(scenes->Belt.Array.getBy(s => s.id == toSceneId)),
        })
      }
      seenVisit->Belt.MutableSet.String.add(fromSceneId)
      seenVisit->Belt.MutableSet.String.add(toSceneId)
    }
  }

  switch traversal {
  | Some(trace) =>
    trace.edges->Belt.Array.forEachWithIndex((idx, edge) => {
      addEdge(
        ~id="trace_" ++ Int.toString(idx),
        ~fromSceneId=edge.fromSceneId,
        ~toSceneId=edge.toSceneId,
        (),
      )
    })
  | None => ()
  }

  timeline->Belt.Array.forEach(item => {
    switch resolveTargetSceneId(~scenes, ~item) {
    | Some(targetSceneId) =>
      addEdge(~id=item.id, ~fromSceneId=item.sceneId, ~toSceneId=targetSceneId, ())
    | None => ()
    }
  })

  scenes->Belt.Array.forEach(scene => {
    scene.hotspots->Belt.Array.forEachWithIndex((idx, hotspot) => {
      let fallbackRef = hotspot.target == "" ? None : Some(hotspot.target)
      let targetSceneId =
        hotspot.targetSceneId->Option.orElse(resolveSceneId(~scenes, fallbackRef))
      switch targetSceneId {
      | Some(targetId) =>
        addEdge(
          ~id="hotspot_" ++ scene.id ++ "_" ++ hotspot.linkId ++ "_" ++ Int.toString(idx),
          ~fromSceneId=scene.id,
          ~toSceneId=targetId,
          (),
        )
      | None => ()
      }
    })
  })

  let edges = edgesQueue->Belt.MutableQueue.toArray

  {nodes, edges}
}
