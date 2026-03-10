open ReBindings

type measurement = {paths: Dict.t<string>, missingAnchors: bool}

let buildConnectorPath = (
  ~buttonRect: Dom.rect,
  ~anchorRect: Dom.rect,
  ~containerRect: Dom.rect,
): string => {
  let yFrom = containerRect.bottom -. (buttonRect.top +. buttonRect.height /. 2.0)
  let yTo = containerRect.bottom -. (anchorRect.top +. anchorRect.height /. 2.0)
  let vYFrom = 400.0 -. yFrom
  let vYTo = 400.0 -. yTo
  let xStart = buttonRect.right -. containerRect.left
  let xEnd = anchorRect.left -. containerRect.left
  let slantWidth = Math.abs(vYTo -. vYFrom)
  let deltaX = xEnd -. xStart

  if deltaX <= 2.0 {
    "M " ++
    xStart->Float.toString ++
    " " ++
    vYFrom->Float.toString ++
    " L " ++
    xEnd->Float.toString ++
    " " ++
    vYTo->Float.toString
  } else {
    let xCorridor = xStart +. Math.min(14.0, deltaX *. 0.25)
    let xSlantEnd = xStart +. Math.min(44.0, deltaX *. 0.7)
    let vXSlantStart = Math.max(xCorridor, xSlantEnd -. slantWidth)
    "M " ++
    xStart->Float.toString ++
    " " ++
    vYFrom->Float.toString ++
    " L " ++
    xCorridor->Float.toString ++
    " " ++
    vYFrom->Float.toString ++
    " L " ++
    vXSlantStart->Float.toString ++
    " " ++
    vYFrom->Float.toString ++
    " L " ++
    xSlantEnd->Float.toString ++
    " " ++
    vYTo->Float.toString ++
    " L " ++
    xEnd->Float.toString ++
    " " ++
    vYTo->Float.toString
  }
}

let measureFloorConnectorPaths = (~activeFloors, ~groupedItems, ~containerEl): measurement => {
  let paths = Dict.make()
  let missingAnchors = ref(false)

  activeFloors->Belt.Array.forEachWithIndex((_idx, floorId) => {
    let buttonOpt = Dom.getElementById("floor-nav-button-" ++ floorId)->Nullable.toOption
    let anchorOpt =
      groupedItems
      ->Belt.MutableMap.String.get(floorId)
      ->Option.flatMap(items => Belt.Array.get(items, 0))
      ->Option.map((item: VisualPipelineGraph.node) => Dom.getElementById("pipeline-node-wrap-" ++ item.id))
      ->Option.flatMap(Nullable.toOption)

    switch (buttonOpt, anchorOpt) {
    | (Some(buttonEl), Some(anchorEl)) =>
      let d = buildConnectorPath(
        ~buttonRect=buttonEl->Dom.getBoundingClientRect,
        ~anchorRect=anchorEl->Dom.getBoundingClientRect,
        ~containerRect=containerEl->Dom.getBoundingClientRect,
      )
      paths->Dict.set(floorId, d)
    | _ => missingAnchors := true
    }
  })

  {paths, missingAnchors: missingAnchors.contents}
}

let reconcileMeasuredPaths = (~prev, ~next, ~missingAnchors) => {
  let encodeDict = JsonCombinators.Json.Encode.dict(JsonCombinators.Json.Encode.string)
  let prevStr = JsonCombinators.Json.stringify(encodeDict(prev))
  let nextStr = JsonCombinators.Json.stringify(encodeDict(next))
  let isNextEmpty = nextStr == "{}"

  if missingAnchors && isNextEmpty && prevStr != "{}" {
    prev
  } else if prevStr == nextStr {
    prev
  } else {
    next
  }
}
