/* src/components/VisualPipeline/VisualPipelineLogic.res */

open ReBindings
open VisualPipelineTypes

let handleDragStart = (pipeline: t, e: Dom.event) => {
  let node = Dom.closest(Dom.target(e), ".pipeline-node")
  switch Nullable.toOption(node) {
  | Some(n) =>
    let id = Dict.get(Dom.dataset(n), "id")->Option.getOr("")
    Logger.debug(~module_="VisualPipeline", ~message="DRAG_START", ~data=Some({"id": id}), ())
    pipeline.dragSourceId = Nullable.make(id)
    Dom.add(n, "is-dragging")
    Dom.add(pipeline.wrapper, "dragging-active")

    let dt = Dom.dataTransfer(e)
    Dom.setEffectAllowed(dt, "move")
    Dom.setData(dt, "text/plain", id)
  | None => ()
  }
}

let handleDragEnd = (pipeline: t, e: Dom.event) => {
  let node = Dom.closest(Dom.target(e), ".pipeline-node")
  switch Nullable.toOption(node) {
  | Some(n) => Dom.remove(n, "is-dragging")
  | None => ()
  }
  Dom.remove(pipeline.wrapper, "dragging-active")

  let zones = JsHelpers.from(Dom.querySelectorAll(pipeline.wrapper, ".drop-zone"))
  Belt.Array.forEach(zones, z => Dom.remove(z, "drag-over"))

  pipeline.dragSourceId = Nullable.null
}

let handleDragOver = (e: Dom.event) => {
  Dom.preventDefault(e)
  Dom.setDropEffect(Dom.dataTransfer(e), "move")
  let zone = Dom.closest(Dom.target(e), ".drop-zone")
  switch Nullable.toOption(zone) {
  | Some(z) => Dom.add(z, "drag-over")
  | None => ()
  }
  ()
  false
}

let handleDragEnter = (e: Dom.event) => {
  Dom.preventDefault(e)
  let zone = Dom.closest(Dom.target(e), ".drop-zone")
  switch Nullable.toOption(zone) {
  | Some(z) => Dom.add(z, "drag-over")
  | None => ()
  }
}

let handleDragLeave = (e: Dom.event) => {
  let zone = Dom.closest(Dom.target(e), ".drop-zone")
  switch Nullable.toOption(zone) {
  | Some(z) => Dom.remove(z, "drag-over")
  | None => ()
  }
}

let handleDrop = (pipeline: t, e: Dom.event) => {
  Dom.preventDefault(e)
  let zone = Dom.closest(Dom.target(e), ".drop-zone")
  switch (Nullable.toOption(zone), Nullable.toOption(pipeline.dragSourceId)) {
  | (Some(z), Some(sourceId)) =>
    let dropIndex =
      Belt.Int.fromString(Dict.get(Dom.dataset(z), "index")->Option.getOr(""))->Option.getOr(0)
    let state = GlobalStateBridge.getState()
    let sourceIndex = state.timeline->Belt.Array.getIndexBy(t => t.id == sourceId)->Option.getOr(-1)

    if sourceIndex != -1 {
      let finalIndex = if dropIndex > sourceIndex {
        dropIndex - 1
      } else {
        dropIndex
      }
      if finalIndex != sourceIndex {
        Logger.info(~module_="VisualPipeline", ~message="REORDER_TIMELINE", ~data=Some({"from": sourceIndex, "to": finalIndex}), ())
        GlobalStateBridge.dispatch(ReorderTimeline(sourceIndex, finalIndex))
      }
    }
  | _ => ()
  }
  handleDragEnd(pipeline, e)
}

let createDropZone = (pipeline: t, index: int) => {
  let zone = Dom.createElement("div")
  Dom.setClassName(zone, "drop-zone")
  Dict.set(Dom.dataset(zone), "index", Belt.Int.toString(index))

  Dom.addEventListener(zone, "dragover", e => {
    let _ = handleDragOver(e)
  })
  Dom.addEventListener(zone, "dragenter", handleDragEnter)
  Dom.addEventListener(zone, "dragleave", handleDragLeave)
  Dom.addEventListener(zone, "drop", e => handleDrop(pipeline, e))
  zone
}
