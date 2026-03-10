open ReBindings

type scenePoint = VisualPipelineEdgeTypes.scenePoint
type sceneEdgeClip = VisualPipelineEdgeTypes.sceneEdgeClip
type floorBand = VisualPipelineEdgeTypes.floorBand

let buildFloorMaps = (
  ~wrapperRect: Dom.rect,
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~activeFloors: array<string>,
): (Belt.MutableMap.String.t<scenePoint>, Belt.MutableMap.String.t<string>, array<sceneEdgeClip>, Belt.MutableMap.String.t<string>) => {
  let centers = Belt.MutableMap.String.make()
  let floorByScene = Belt.MutableMap.String.make()
  displayNodes->Belt.Array.forEach(node =>
    floorByScene->Belt.MutableMap.String.set(node.representedSceneId, node.floorId)
  )

  let floorBands = Belt.MutableMap.String.make()
  let floorClipIds = Belt.MutableMap.String.make()
  activeFloors->Belt.Array.forEachWithIndex((idx, floorId) => {
    floorClipIds->Belt.MutableMap.String.set(floorId, "pipeline-floor-clip-" ++ Int.toString(idx))
    switch Dom.getElementById("pipeline-track-" ++ floorId)->Nullable.toOption {
    | Some(trackEl) =>
      let trackRect = trackEl->Dom.getBoundingClientRect
      let yTop = trackRect.top -. wrapperRect.top
      let yBottom = trackRect.bottom -. wrapperRect.top
      floorBands->Belt.MutableMap.String.set(floorId, ({yTop, yBottom}: floorBand))
    | None => ()
    }
  })

  displayNodes->Belt.Array.forEach(node => {
    switch Dom.getElementById("pipeline-node-wrap-" ++ node.id)->Nullable.toOption {
    | Some(el) =>
      let rect = el->Dom.getBoundingClientRect
      centers->Belt.MutableMap.String.set(
        node.id,
        ({
          x: rect.left -. wrapperRect.left +. rect.width /. 2.0,
          y: rect.top -. wrapperRect.top +. rect.height /. 2.0,
        }: scenePoint),
      )
    | None => ()
    }
  })

  let clipDefs = activeFloors->Belt.Array.keepMap(floorId =>
    switch (
      floorClipIds->Belt.MutableMap.String.get(floorId),
      floorBands->Belt.MutableMap.String.get(floorId),
    ) {
    | (Some(clipId), Some(band)) =>
      Some(({
        id: clipId,
        x: 0.0,
        y: band.yTop,
        width: wrapperRect.width,
        height: band.yBottom -. band.yTop,
      }: sceneEdgeClip))
    | _ => None
    }
  )

  (centers, floorByScene, clipDefs, floorClipIds)
}

let buildSameFloorOutgoing = (
  ~graph: VisualPipelineGraph.graph,
  ~floorByScene: Belt.MutableMap.String.t<string>,
) => {
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
  sameFloorOutgoing
}
