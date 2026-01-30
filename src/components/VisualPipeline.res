/* src/components/VisualPipeline.res - Consolidated VisualPipeline module 
   @efficiency-role: entry-point */

open ReBindings

module InternalTypes = {
  type t = {
    container: Dom.element,
    wrapper: Dom.element,
    dragSourceId: ref<Nullable.t<string>>,
    thumbCache: Dict.t<string>,
  }
}

module InternalStyles = {
  let nodeSize = 22

  let injectStyles = () => {
    let existing = Dom.getElementById("visual-pipeline-styles")
    switch Nullable.toOption(existing) {
    | Some(_) => ()
    | None =>
      Logger.info(~module_="VisualPipelineStyles", ~message="INJECT_STYLES", ())
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
              width: 100%; height: 6px; background: var(--pipe-color, var(--slate-700)); z-index: 10;
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
              content: ''; position: absolute; inset: 0; background: var(--node-color, var(--success-dark));
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
              background: var(--slate-800); border: 1px solid var(--slate-700); border-radius: 8px; padding: 4px;
              opacity: 0; pointer-events: none; transition: all 0.2s ease; display: flex;
              flex-direction: column; align-items: center; width: 120px; z-index: 30;
              box-shadow: 0 8px 16px rgba(0,0,0,0.5);
            }
            .pipeline-node:hover .node-tooltip { opacity: 1; transform: translateX(-50%) translateY(0); }
            .tooltip-thumb { 
              width: 112px; height: 63px; object-fit: cover; border-radius: 4px; 
              margin-top: 4px; margin-bottom: 4px; background: var(--slate-900);
            }
            .tooltip-text { font-size: 10px; color: white; font-weight: 600; text-align: center; width: 100%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; padding: 0 4px; }
            .tooltip-link-id { font-size: 8px; color: var(--slate-400); font-weight: bold; margin-bottom: 2px; }
            .auto-forward-indicator { position: absolute; top: -8px; right: -8px; color: white; font-size: 12px; font-weight: bold; text-shadow: 1px 1px 2px black; pointer-events: none; }
            .drop-zone.is-endpoint { width: 4px; }
            .drop-zone.is-endpoint.drag-over { width: 32px; }
        ",
      )
      Dom.appendChild(Dom.head, style)
    }
  }
}

module InternalLogic = {
  open InternalTypes

  let handleDragStart = (pipeline: t, e) => {
    let target = Dom.target(e)
    let id = Dict.get(Dom.dataset(target), "id")->Option.getOr("")
    pipeline.dragSourceId := Nullable.fromOption(Some(id))
    Dom.add(target, "is-dragging")
    Dom.add(pipeline.wrapper, "dragging-active")
  }

  let handleDragEnd = (pipeline: t, e) => {
    let target = Dom.target(e)
    pipeline.dragSourceId := Nullable.null
    Dom.remove(target, "is-dragging")
    Dom.remove(pipeline.wrapper, "dragging-active")
  }

  let handleDragOver = e => {
    Dom.preventDefault(e)
  }

  let handleDragEnter = e => {
    let target = Dom.target(e)
    Dom.add(target, "drag-over")
  }

  let handleDragLeave = e => {
    let target = Dom.target(e)
    Dom.remove(target, "drag-over")
  }

  let handleDrop = (pipeline: t, e) => {
    Dom.preventDefault(e)
    let target = Dom.target(e)
    Dom.remove(target, "drag-over")

    let dropIndex =
      Dict.get(Dom.dataset(target), "index")
      ->Option.flatMap(s => Belt.Int.fromString(s))
      ->Option.getOr(-1)

    switch (dropIndex, Nullable.toOption(pipeline.dragSourceId.contents)) {
    | (dropIndex, Some(sourceId)) if dropIndex != -1 =>
      let state = GlobalStateBridge.getState()
      let sourceIndex =
        state.timeline->Belt.Array.getIndexBy(t => t.id == sourceId)->Option.getOr(-1)

      if sourceIndex != -1 {
        let finalIndex = if dropIndex > sourceIndex {
          dropIndex - 1
        } else {
          dropIndex
        }
        if finalIndex != sourceIndex {
          Logger.info(
            ~module_="VisualPipeline",
            ~message="REORDER_TIMELINE",
            ~data=Some({"from": sourceIndex, "to": finalIndex}),
            (),
          )
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
}

module InternalRender = {
  open InternalTypes
  open InternalLogic

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
            Logger.debug(
              ~module_="VisualPipeline",
              ~message="ACTIVATE_NODE",
              ~data=Some({"id": item.id}),
              (),
            )
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
          let color = ref("var(--success-dark)")
          switch scene {
          | Some(s) =>
            color := ColorPalette.getGroupColor(s.colorGroup)
            Dom.setProperty(node, "--node-color", color.contents)
          | None => ()
          }

          if index == 0 {
            Dom.setPointerEvents(firstZone, "auto")
            Dom.setProperty(firstZone, "--pipe-color", color.contents)
          }

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
              Logger.info(
                ~module_="VisualPipeline",
                ~message="REMOVE_STEP",
                ~data=Some({"id": item.id}),
                (),
              )
              GlobalStateBridge.dispatch(RemoveFromTimeline(item.id))
            }
          })

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
              let url = UrlUtils.fileToUrl(file)
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

          let tooltip = Dom.createElement("div")
          Dom.setClassName(tooltip, "node-tooltip")

          let linkIdSpan = Dom.createElement("span")
          Dom.setClassName(linkIdSpan, "tooltip-link-id")
          Dom.setTextContent(linkIdSpan, "Link: " ++ item.linkId)
          Dom.appendChild(tooltip, linkIdSpan)

          if thumbUrl.contents != "" {
            let img = Dom.createElement("img")
            Dom.setClassName(img, "tooltip-thumb")
            Dom.setAttribute(img, "src", thumbUrl.contents)
            Dom.setAttribute(img, "alt", thumbName.contents ++ " preview")
            Dom.appendChild(tooltip, img)
          }

          let textSpan = Dom.createElement("span")
          Dom.setClassName(textSpan, "tooltip-text")
          Dom.setTextContent(textSpan, thumbName.contents)
          Dom.appendChild(tooltip, textSpan)

          Dom.appendChild(node, tooltip)

          if isAutoForward {
            let indicator = Dom.createElement("span")
            Dom.setClassName(indicator, "auto-forward-indicator")
            Dom.setTextContent(indicator, "\u00BB")
            Dom.appendChild(node, indicator)
          }

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
}

include InternalTypes

let init = (containerId: string) => {
  let container = Dom.getElementById(containerId)
  switch Nullable.toOption(container) {
  | Some(c) =>
    Logger.initialized(~module_="VisualPipeline")
    InternalStyles.injectStyles()
    let wrapper = Dom.createElement("div")
    Dom.setClassName(wrapper, "visual-pipeline-wrapper")

    let track = Dom.createElement("div")
    Dom.setClassName(track, "pipeline-track")
    Dom.appendChild(wrapper, track)

    Dom.appendChild(c, wrapper)

    let pipeline = {
      container: c,
      wrapper,
      dragSourceId: ref(Nullable.null),
      thumbCache: Dict.make(),
    }

    let _ = GlobalStateBridge.subscribe(state => InternalRender.render(pipeline, state))
    InternalRender.render(pipeline, GlobalStateBridge.getState())
    Some(pipeline)
  | None => None
  }
}
