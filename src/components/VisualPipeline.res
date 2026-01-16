/* src/components/VisualPipeline.res */

open Types
open ReBindings

/* --- TYPES --- */
type t = {
  container: Dom.element,
  wrapper: Dom.element,
  mutable dragSourceId: Nullable.t<string>,
  thumbCache: Dict.t<string>,
}

let nodeSize = 22

let injectStyles = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  switch Nullable.toOption(existing) {
  | Some(_) => ()
  | None =>
    let style = Dom.createElement("style")
    Dom.setId(style, "visual-pipeline-styles")
    Dom.setTextContent(
      style,
      "
          #visual-pipeline-container {
            position: absolute; bottom: 0; left: 0; width: 100%; height: 0; z-index: 1000;
            display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
            padding-left: 70px; padding-right: 160px; box-sizing: border-box;
          }
          .visual-pipeline-wrapper {
            pointer-events: auto; margin-bottom: 20px; display: flex; justify-content: center;
            align-items: center; width: 100%; min-width: 200px; max-width: 800px;
            padding: 6px 12px; background: transparent; user-select: none; flex-wrap: wrap;
          }
          .pipeline-track {
            display: flex; flex-wrap: wrap; justify-content: center; align-items: center;
            position: relative; width: 100%;
          }
          .drop-zone {
            width: 14px; height: 32px; display: flex; align-items: center; justify-content: center;
            position: relative; z-index: 10; margin: 0 -2px;
            transition: width 0.3s cubic-bezier(0.2, 1, 0.2, 1); will-change: width;
          }
          .drop-zone::before {
            content: ''; position: absolute; top: 50%; left: 0; transform: translateY(-50%);
            width: 100%; height: 6px; background: var(--pipe-color, #1e293b); z-index: 10;
            pointer-events: none;
          }
          .drop-zone::after {
            content: ''; position: absolute; width: " ++
      Int.toString(nodeSize) ++
      "px;
            height: " ++
      Int.toString(nodeSize) ++
      "px; border-radius: 50%;
            background: rgba(255, 255, 255, 0.1); border: 2px dashed white; opacity: 0;
            box-shadow: 0 0 12px rgba(255, 255, 255, 0.4); z-index: 15; pointer-events: none;
            transition: all 0.3s cubic-bezier(0.2, 1, 0.2, 1); transform: scale(0.7);
          }
          .drop-zone.drag-over::after { opacity: 1; transform: scale(1); }
          .drop-zone.drag-over { width: 32px; }
          .dragging-active .drop-zone { z-index: 100; cursor: copy; }
          .pipeline-node {
            width: " ++
      Int.toString(nodeSize) ++
      "px; height: " ++
      Int.toString(nodeSize) ++ "px;
            display: flex; align-items: center; justify-content: center; cursor: grab;
            transition: transform 0.2s, opacity 0.2s; position: relative; flex-shrink: 0;
            margin: 3px 0; z-index: 20;
          }
          .pipeline-node.is-dragging { opacity: 0.4; }
          .pipeline-node::after {
            content: ''; position: absolute; inset: 0; background: var(--node-color, #0a7a56);
            border-radius: 50%; z-index: 20; transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 1px 1px 1px #000;
          }
          .pipeline-node:hover::after { transform: scale(1.15); box-shadow: 2px 2px 1px #000; }
          .pipeline-node.active::after { transform: scale(1.2); box-shadow: none; }
          .pipeline-node.active::before {
            content: ''; position: absolute; inset: -3px; border: 3px solid white;
            border-radius: 50%; z-index: 5; transform: scale(1.2); box-shadow: none;
          }
          .pipeline-node:focus-visible {
            outline: 2px solid white; outline-offset: 4px; z-index: 100;
          }
          .node-tooltip {
            position: absolute; bottom: 50px; left: 50%; transform: translateX(-50%) translateY(10px);
            background: #1e293b; border: 1px solid #334155; border-radius: 8px; padding: 4px;
            opacity: 0; pointer-events: none; transition: all 0.2s ease; display: flex;
            flex-direction: column; align-items: center; width: 120px; z-index: 30;
            box-shadow: 0 8px 16px rgba(0,0,0,0.5);
          }
          .pipeline-node:hover .node-tooltip { opacity: 1; transform: translateX(-50%) translateY(0); }
          .tooltip-thumb { 
            width: 112px; height: 63px; object-fit: cover; border-radius: 4px; 
            margin-top: 4px; margin-bottom: 4px; background: #0f172a; 
          }
          .tooltip-text {
            color: white; font-size: 10px; font-weight: 600; text-align: center; 
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 100%;
          }
          .tooltip-link-id { color: #94a3b8; font-size: 9px; font-weight: 700; margin-bottom: 2px; }
          .auto-forward-indicator {
            position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
            z-index: 25; color: white; font-size: 21px; font-weight: 900; line-height: 1;
            pointer-events: none; text-shadow: 0 1px 2px rgba(0,0,0,0.5); padding-bottom: 2px;
            padding-left: 1px;
          }
          .drop-zone.is-endpoint::before { display: none; }
        ",
    )
    Dom.appendChild(Dom.head, style)
  }
}

let handleDragStart = (pipeline: t, e: Dom.event) => {
  let node = Dom.closest(Dom.target(e), ".pipeline-node")
  switch Nullable.toOption(node) {
  | Some(n) =>
    let id = Dict.get(Dom.dataset(n), "id")->Option.getOr("")
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
  () // ensure unit return
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

let render = (pipeline: t, state: Types.state) => {
  if Belt.Array.length(state.timeline) == 0 {
    Dom.setDisplay(pipeline.wrapper, "none")
  } else {
    Dom.setDisplay(pipeline.wrapper, "flex")

    let track = Dom.querySelector(pipeline.wrapper, ".pipeline-track")
    switch Nullable.toOption(track) {
    | Some(t) =>
      let fragment = Dom.createDocumentFragment()

      let firstZone = createDropZone(pipeline, 0)
      Dom.add(firstZone, "is-endpoint")
      Dom.appendChild(fragment, firstZone)

      Belt.Array.forEachWithIndex(state.timeline, (index, item) => {
        let node = Dom.createElement("div")
        Dom.setClassName(node, "pipeline-node")
        Dict.set(Dom.dataset(node), "id", item.id)
        Dom.setDraggable(node, true)
        Dom.setAttribute(node, "role", "button")
        Dom.setAttribute(node, "tabindex", "0")
        Dom.setAttribute(node, "aria-label", "Timeline step: " ++ item.targetScene)

        let activateNode = () => {
          GlobalStateBridge.dispatch(SetActiveTimelineStep(Some(item.id)))
          let sceneIdx =
            state.scenes
            ->Belt.Array.getIndexBy(s => s.id == item.sceneId)
            ->Option.getOr(-1)
          if sceneIdx != -1 {
            switch Belt.Array.get(state.scenes, sceneIdx) {
            | Some(s) =>
              let hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == item.linkId)
              switch hotspot {
              | Some(h) =>
                GlobalStateBridge.dispatch(SetActiveScene(sceneIdx, h.yaw, h.pitch, None))
              | None => GlobalStateBridge.dispatch(SetActiveScene(sceneIdx, 0.0, 0.0, None))
              }
            | None => ()
            }
          }
        }

        let scene = state.scenes->Belt.Array.getBy(s => s.id == item.sceneId)
        let color = ref("#0a7a56")
        switch scene {
        | Some(s) =>
          color := ColorPalette.getGroupColor(s.colorGroup)
          Dom.setProperty(node, "--node-color", color.contents)
        | None => ()
        }

        if index == 0 {
          Dom.setPointerEvents(firstZone, "auto") // dummy style call to ensure it's themed
          Dom.setProperty(firstZone, "--pipe-color", color.contents)
        }

        // Active check
        let isActive = switch state.activeTimelineStepId {
        | Some(id) => id == item.id
        | None =>
          switch Belt.Array.get(state.scenes, state.activeIndex) {
          | Some(currentScene) =>
            let firstMatchIdx =
              state.timeline
              ->Belt.Array.getIndexBy(t => t.sceneId == currentScene.id)
              ->Option.getOr(-1)
            item.sceneId == currentScene.id && firstMatchIdx == index
          | None => false
          }
        }

        if isActive {
          Dom.add(node, "active")
        }

        Dom.addEventListenerNoEv(node, "click", activateNode)
        Dom.addEventListener(node, "keydown", (e: Dom.event) => {
          let key = Dom.key(e)
          if key == "Enter" || key == " " {
            Dom.preventDefault(e)
            activateNode()
          }
        })

        Dom.addEventListener(node, "dragstart", e => handleDragStart(pipeline, e))
        Dom.addEventListener(node, "dragend", e => handleDragEnd(pipeline, e))

        Dom.addEventListener(node, "contextmenu", (e: Dom.event) => {
          Dom.preventDefault(e)
          if Window.confirm("Remove this step from the timeline?") {
            GlobalStateBridge.dispatch(RemoveFromTimeline(item.id))
          }
        })

        // Thumbnail
        let thumbUrl = ref("")
        let thumbName = ref("Unknown Scene")
        switch scene {
        | Some(sc) =>
          thumbName := sc.name
          switch Dict.get(pipeline.thumbCache, sc.id) {
          | Some(url) => thumbUrl := url
          | None =>
            let file = switch sc.tinyFile {
            | Some(tf) => tf
            | None => sc.file
            }
            let url = URL.createObjectURL(file)
            Dict.set(pipeline.thumbCache, sc.id, url)
            thumbUrl := url
          }
        | None => ()
        }

        let targetScene = state.scenes->Belt.Array.getBy(s => s.name == item.targetScene)
        let isAutoForward = switch targetScene {
        | Some(ts) => ts.isAutoForward
        | None => false
        }

        Dom.setInnerHTML(
          node,
          "
                  <div class=\"node-tooltip\">
                     <span class=\"tooltip-link-id\">Link: " ++
          item.linkId ++
          "</span>
                     " ++
          if thumbUrl.contents != "" {
            "<img src=\"" ++
            thumbUrl.contents ++
            "\" class=\"tooltip-thumb\" alt=\"" ++
            thumbName.contents ++ " preview\">"
          } else {
            ""
          } ++
          "
                     <span class=\"tooltip-text\">" ++
          thumbName.contents ++
          "</span>
                  </div>
                  " ++
          if isAutoForward {
            "<span class=\"auto-forward-indicator\">»</span>"
          } else {
            ""
          } ++ "
                ",
        )

        Dom.appendChild(fragment, node)

        let nextZone = createDropZone(pipeline, index + 1)
        if index == Belt.Array.length(state.timeline) - 1 {
          Dom.add(nextZone, "is-endpoint")
        }
        Dom.setProperty(nextZone, "--pipe-color", color.contents)
        Dom.appendChild(fragment, nextZone)
      })

      Dom.setTextContent(t, "")
      Dom.appendChild(t, fragment)
    | None => ()
    }
  }
}

let init = (containerId: string) => {
  let container = Dom.getElementById(containerId)
  switch Nullable.toOption(container) {
  | Some(c) =>
    injectStyles()
    let wrapper = Dom.createElement("div")
    Dom.setClassName(wrapper, "visual-pipeline-wrapper")
    Dom.setInnerHTML(wrapper, "<div class=\"pipeline-track\"></div>")
    Dom.appendChild(c, wrapper)

    let pipeline = {
      container: c,
      wrapper,
      dragSourceId: Nullable.null,
      thumbCache: Dict.make(),
    }

    GlobalStateBridge.subscribe(state => render(pipeline, state))
    render(pipeline, GlobalStateBridge.getState())
    Some(pipeline)
  | None => None
  }
}
