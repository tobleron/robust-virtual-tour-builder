open VisualPipelineGraph
open VisualPipelineLayout

type routedEdge = {
  id: string,
  kind: edgeKind,
  path: string,
  isCrossFloor: bool,
  laneKey: string,
}

type routeBundle = {routedEdges: array<routedEdge>}

let minf = (a: float, b: float): float => a <= b ? a : b
let maxf = (a: float, b: float): float => a >= b ? a : b

let laneForKey = (~key: string, ~lanes: Belt.MutableMap.String.t<int>): int => {
  switch lanes->Belt.MutableMap.String.get(key) {
  | Some(idx) => idx
  | None =>
    let idx = Belt.MutableMap.String.size(lanes)
    lanes->Belt.MutableMap.String.set(key, idx)
    idx
  }
}

let laneKeyForEdge = (~edge: edge): string =>
  switch edge.kind {
  | Return => "return:" ++ edge.toSceneId
  | Forward => "forward:" ++ edge.id
  }

let routeEdge = (~edge: edge, ~layout: layout, ~laneIdx: int, ~laneKey: string): option<
  routedEdge,
> => {
  switch (getPoint(layout, edge.fromNodeId), getPoint(layout, edge.toNodeId)) {
  | (Some(fromPoint), Some(toPoint)) =>
    let laneSpacing = 8.0
    let elbow = 10.0
    let laneFloat = laneIdx->Int.toFloat
    let isForwardX = toPoint.x >= fromPoint.x

    let busX = if edge.kind == Return {
      toPoint.x -. 20.0 -. laneFloat *. laneSpacing
    } else if isForwardX {
      maxf(fromPoint.x, toPoint.x) +. 20.0 +. laneFloat *. laneSpacing
    } else {
      minf(fromPoint.x, toPoint.x) -. 20.0 -. laneFloat *. laneSpacing
    }

    let exitX = if busX >= fromPoint.x {
      fromPoint.x +. elbow
    } else {
      fromPoint.x -. elbow
    }

    let entryX = if busX >= toPoint.x {
      toPoint.x +. elbow
    } else {
      toPoint.x -. elbow
    }

    let path =
      "M " ++
      fromPoint.x->Float.toString ++
      " " ++
      fromPoint.y->Float.toString ++
      " L " ++
      exitX->Float.toString ++
      " " ++
      fromPoint.y->Float.toString ++
      " L " ++
      busX->Float.toString ++
      " " ++
      fromPoint.y->Float.toString ++
      " L " ++
      busX->Float.toString ++
      " " ++
      toPoint.y->Float.toString ++
      " L " ++
      entryX->Float.toString ++
      " " ++
      toPoint.y->Float.toString ++
      " L " ++
      toPoint.x->Float.toString ++
      " " ++
      toPoint.y->Float.toString

    Some({id: edge.id, kind: edge.kind, path, isCrossFloor: edge.isCrossFloor, laneKey})
  | _ => None
  }
}

let compute = (~graph: graph, ~layout: layout): routeBundle => {
  let lanes = Belt.MutableMap.String.make()
  let routedEdges = graph.edges->Belt.Array.keepMap(edge => {
    let laneKey = laneKeyForEdge(~edge)
    let laneIdx = laneForKey(~key=laneKey, ~lanes)
    routeEdge(~edge, ~layout, ~laneIdx, ~laneKey)
  })

  {routedEdges: routedEdges}
}
