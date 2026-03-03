open VisualPipelineGraph

type point = {x: float, y: float}

type layout = {
  positions: Belt.Map.String.t<point>,
  floorRows: Belt.Map.String.t<int>,
  width: float,
  height: float,
}

type metrics = {
  nodeSize: float,
  nodeGap: float,
  rowGap: float,
  leftPadding: float,
  rightPadding: float,
  topPadding: float,
  bottomPadding: float,
}

let defaultMetrics: metrics = {
  nodeSize: 12.0,
  nodeGap: 6.0,
  rowGap: 28.0,
  leftPadding: 10.0,
  rightPadding: 16.0,
  topPadding: 12.0,
  bottomPadding: 12.0,
}

let floorSortIndex = (floorId: string): int =>
  Constants.Scene.floorLevels
  ->Belt.Array.getIndexBy(level => level.id == floorId)
  ->Option.getOr(Constants.Scene.floorLevels->Belt.Array.length)

let sortedFloors = (graph: graph): array<string> => {
  let floors = Belt.MutableSet.String.make()
  graph.nodes->Belt.Array.forEach(node => floors->Belt.MutableSet.String.add(node.floorId))
  floors
  ->Belt.MutableSet.String.toArray
  ->Belt.SortArray.stableSortBy((a, b) => floorSortIndex(a) - floorSortIndex(b))
}

let compute = (~graph: graph, ~metrics: metrics=defaultMetrics, ()): layout => {
  let floors = sortedFloors(graph)
  let floorRows =
    floors
    ->Belt.Array.reduce(Belt.Map.String.empty, (acc, floorId) => {
      let row = Belt.Map.String.size(acc)
      Belt.Map.String.set(acc, floorId, row)
    })

  let countsByFloor = Belt.MutableMap.String.make()
  graph.nodes->Belt.Array.forEach(node => {
    let count = countsByFloor->Belt.MutableMap.String.get(node.floorId)->Option.getOr(0)
    countsByFloor->Belt.MutableMap.String.set(node.floorId, count + 1)
  })

  let maxColumns =
    floors
    ->Belt.Array.reduce(0, (acc, floorId) => {
      let count = countsByFloor->Belt.MutableMap.String.get(floorId)->Option.getOr(0)
      acc > count ? acc : count
    })

  let width =
    metrics.leftPadding +.
    metrics.rightPadding +.
    (maxColumns->Int.toFloat *. (metrics.nodeSize +. metrics.nodeGap))
  let height =
    metrics.topPadding +.
    metrics.bottomPadding +.
    (Belt.Array.length(floors)->Int.toFloat *. metrics.rowGap)

  let colByFloor = Belt.MutableMap.String.make()
  let positions =
    graph.nodes
    ->Belt.Array.reduce(Belt.Map.String.empty, (acc, node) => {
      let column = colByFloor->Belt.MutableMap.String.get(node.floorId)->Option.getOr(0)
      colByFloor->Belt.MutableMap.String.set(node.floorId, column + 1)
      let row = floorRows->Belt.Map.String.get(node.floorId)->Option.getOr(0)

      let x = metrics.leftPadding +. (column->Int.toFloat *. (metrics.nodeSize +. metrics.nodeGap)) +. (metrics.nodeSize /. 2.0)
      let y =
        height -.
        metrics.bottomPadding -.
        (row->Int.toFloat *. metrics.rowGap) -.
        (metrics.nodeSize /. 2.0)
      Belt.Map.String.set(acc, node.id, {x, y})
    })

  {
    positions,
    floorRows,
    width,
    height,
  }
}

let getPoint = (layout: layout, nodeId: string): option<point> =>
  layout.positions->Belt.Map.String.get(nodeId)
