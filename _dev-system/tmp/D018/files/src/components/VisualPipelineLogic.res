/* src/components/VisualPipelineLogic.res - Logic for VisualPipeline */

open ReBindings

type t = {
  container: Dom.element,
  wrapper: Dom.element,
  dragSourceId: ref<Nullable.t<string>>,
  mutable thumbCache: Dict.t<string>,
  mutable lastSessionId: option<string>,
}

module Logic = {
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

  let handleDrop = (
    pipeline: t,
    e,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
  ) => {
    Dom.preventDefault(e)
    let target = Dom.target(e)
    Dom.remove(target, "drag-over")

    let dropIndex =
      Dict.get(Dom.dataset(target), "index")
      ->Option.flatMap(s => Belt.Int.fromString(s))
      ->Option.getOr(-1)

    switch (dropIndex, Nullable.toOption(pipeline.dragSourceId.contents)) {
    | (dropIndex, Some(sourceId)) if dropIndex != -1 =>
      let state = getState()
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
          dispatch(ReorderTimeline(sourceIndex, finalIndex))
        }
      }
    | _ => ()
    }
    handleDragEnd(pipeline, e)
  }

  let createDropZone = (pipeline: t, index: int, ~getState, ~dispatch) => {
    let zone = Dom.createElement("div")
    Dom.setClassName(zone, "drop-zone")
    Dict.set(Dom.dataset(zone), "index", Belt.Int.toString(index))

    Dom.addEventListener(zone, "dragover", e => {
      let _ = handleDragOver(e)
    })
    Dom.addEventListener(zone, "dragenter", handleDragEnter)
    Dom.addEventListener(zone, "dragleave", handleDragLeave)
    Dom.addEventListener(zone, "drop", e => handleDrop(pipeline, e, ~getState, ~dispatch))
    zone
  }
}

module Styles = {
  let nodeSize = 22

  let styles =
    "
  #visual-pipeline-container {
    position: absolute; bottom: 0; left: 0; width: 100%; height: auto; z-index: 9000;
    display: flex; justify-content: center; align-items: flex-end; pointer-events: none;
    padding-bottom: env(safe-area-inset-bottom, 20px);
    box-sizing: border-box;
  }

  /* Responsive padding */
  @media (min-width: 768px) {
    #visual-pipeline-container {
      padding-left: 80px;
      padding-right: 80px;
    }
  }

  .visual-pipeline-wrapper {
    pointer-events: auto;
    margin-bottom: 24px;
    display: flex; justify-content: center; align-items: center;
    width: auto; max-width: 90%;
    padding: 12px 24px;
    background: rgba(15, 23, 42, 0.7); /* Slate-900 with opacity */
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 16px;
    box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.5);
    user-select: none;
    flex-wrap: wrap;
    gap: 12px;
    transition: all 0.3s ease;
  }

  .pipeline-track {
    display: flex; flex-wrap: wrap; justify-content: center; align-items: center;
    position: relative; width: 100%; gap: 4px;
  }

  .drop-zone {
    width: 14px; height: 32px; display: flex; align-items: center; justify-content: center;
    position: relative; z-index: 10;
    transition: width 0.3s cubic-bezier(0.2, 1, 0.2, 1); will-change: width;
  }

  .drop-zone::before {
    content: ''; position: absolute; top: 50%; left: 0; transform: translateY(-50%);
    width: 100%; height: 4px; background: rgba(255, 255, 255, 0.2); z-index: 10;
    border-radius: 2px; pointer-events: none;
  }

  .drop-zone::after {
    content: ''; position: absolute; width: " ++
    Int.toString(nodeSize) ++
    "px;
    height: " ++
    Int.toString(nodeSize) ++
    "px; border-radius: 50%;
    background: rgba(255, 255, 255, 0.1); border: 2px dashed rgba(255, 255, 255, 0.5); opacity: 0;
    box-shadow: 0 0 12px rgba(255, 255, 255, 0.4); z-index: 15; pointer-events: none;
    transition: all 0.3s cubic-bezier(0.2, 1, 0.2, 1); transform: scale(0.7);
  }

  .drop-zone.drag-over::after { opacity: 1; transform: scale(1); border-color: white; }
  .drop-zone.drag-over { width: 36px; }
  .dragging-active .drop-zone { z-index: 100; cursor: copy; }

  .pipeline-node {
    width: " ++
    Int.toString(nodeSize + 4) ++
    "px; height: " ++
    Int.toString(nodeSize + 4) ++ "px;
    display: flex; align-items: center; justify-content: center; cursor: pointer;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    position: relative; flex-shrink: 0;
    z-index: 20;
  }

  .pipeline-node:hover { transform: translateY(-2px); }
  .pipeline-node:active { transform: translateY(0) scale(0.95); }

  .pipeline-node.is-dragging { opacity: 0.4; transform: scale(0.9); }

  .pipeline-node::after {
    content: ''; position: absolute; inset: 2px;
    background: var(--node-color, var(--success-dark));
    border-radius: 50%; z-index: 20;
    box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    border: 2px solid rgba(255,255,255,0.1);
    transition: all 0.3s ease;
  }

  .pipeline-node:hover::after {
    box-shadow: 0 0 0 2px rgba(255,255,255,0.2), 0 4px 8px rgba(0,0,0,0.4);
    border-color: rgba(255,255,255,0.8);
  }

  .pipeline-node.active::after {
    box-shadow: 0 0 0 2px white, 0 0 12px var(--node-color);
    border-color: white;
  }

  .pipeline-node:focus-visible {
    outline: none;
  }
  .pipeline-node:focus-visible::after {
    box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.5);
  }

  .node-tooltip {
    position: absolute; bottom: 100%; left: 50%; transform: translateX(-50%) translateY(10px);
    background: rgba(15, 23, 42, 0.95);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px; padding: 6px;
    opacity: 0; pointer-events: none; transition: all 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
    display: flex; flex-direction: column; align-items: center; width: 140px; z-index: 100;
    box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(4px);
    margin-bottom: 12px;
  }

  .pipeline-node:hover .node-tooltip { opacity: 1; transform: translateX(-50%) translateY(0); }

  .tooltip-thumb {
    width: 100%; height: 72px; object-fit: cover; border-radius: 4px;
    margin-bottom: 6px; background: var(--slate-900);
    border: 1px solid rgba(255,255,255,0.1);
  }

  .tooltip-text {
    font-size: 11px; color: white; font-weight: 600; text-align: center;
    width: 100%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    line-height: 1.4;
  }

  .tooltip-link-id {
    font-size: 9px; color: var(--slate-400); font-weight: 700;
    text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;
  }

  .auto-forward-indicator {
    position: absolute; top: -6px; right: -6px;
    background: var(--primary); color: white;
    width: 14px; height: 14px; border-radius: 50%;
    font-size: 9px; display: flex; align-items: center; justify-content: center;
    box-shadow: 0 2px 4px rgba(0,0,0,0.3);
    z-index: 30; pointer-events: none;
  }

  .drop-zone.is-endpoint { width: 4px; }
  .drop-zone.is-endpoint.drag-over { width: 36px; }
"
}

module Render = {
  open Logic

  let render = (pipeline: t, state: Types.state, ~getState, ~dispatch) => {
    Logger.info(
      ~module_="VisualPipeline",
      ~message="RENDER_CALLED_TIMELINE_" ++ Array.length(state.timeline)->Int.toString,
      (),
    )

    // Clear cache if session changed
    if pipeline.lastSessionId != state.sessionId {
      Logger.info(~module_="VisualPipeline", ~message="SESSION_CHANGED_CLEARING_CACHE", ())
      pipeline.thumbCache = Dict.make()
      pipeline.lastSessionId = state.sessionId
    }

    if Belt.Array.length(state.timeline) == 0 {
      Logger.debug(~module_="VisualPipeline", ~message="DISPLAY_NONE", ())
      Dom.setDisplay(pipeline.wrapper, "none")
    } else {
      Logger.debug(~module_="VisualPipeline", ~message="DISPLAY_FLEX", ())
      Dom.setDisplay(pipeline.wrapper, "flex")

      let track = Dom.querySelector(pipeline.wrapper, ".pipeline-track")
      switch Nullable.toOption(track) {
      | Some(t) =>
        let fragment = Dom.createDocumentFragment()

        let firstZone = createDropZone(pipeline, 0, ~getState, ~dispatch)
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
            dispatch(Actions.SetActiveTimelineStep(Some(item.id)))
            let sceneIdx =
              state.scenes
              ->Belt.Array.getIndexBy(s => s.id == item.sceneId)
              ->Option.getOr(-1)
            if sceneIdx != -1 {
              switch Belt.Array.get(state.scenes, sceneIdx) {
              | Some(s) =>
                let hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == item.linkId)
                switch hotspot {
                | Some(h) => dispatch(SetActiveScene(sceneIdx, h.yaw, h.pitch, None))
                | None => dispatch(SetActiveScene(sceneIdx, 0.0, 0.0, None))
                }
              | None => ()
              }
            }
          }

          let sourceScene = state.scenes->Belt.Array.getBy(s => {
            s.id == item.sceneId || s.id == "legacy_" ++ item.sceneId
          })

          let targetScene = state.scenes->Belt.Array.getBy(s => {
            s.name == item.targetScene ||
            UrlUtils.stripExtension(s.name) == UrlUtils.stripExtension(item.targetScene) ||
            s.id == item.targetScene ||
            s.id == "legacy_" ++ item.targetScene
          })

          let color = ref("var(--success-dark)")
          switch sourceScene {
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
              dispatch(RemoveFromTimeline(item.id))
            }
          })

          // Use target scene for thumbnail/name in pipeline as it's the destination
          let thumbUrl = ref("")
          let thumbName = ref(item.targetScene)

          let effectiveThumbScene = switch targetScene {
          | Some(ts) => Some(ts)
          | None => sourceScene // Fallback to source if target not found
          }

          switch effectiveThumbScene {
          | Some(sc) =>
            thumbName := sc.name
            thumbUrl :=
              switch sc.tinyFile {
              | Some(tf) =>
                let url = SceneCache.getThumbUrl(sc.id ++ "_tiny", tf)
                if url == "" {
                  SceneCache.getThumbUrl(sc.id, sc.file)
                } else {
                  url
                }
              | None => SceneCache.getThumbUrl(sc.id, sc.file)
              }
          | None => ()
          }

          let isAutoForward = switch targetScene {
          | Some(ts) => ts.isAutoForward
          | None => false
          }

          let tooltip = Dom.createElement("div")
          Dom.setClassName(tooltip, "node-tooltip")

          let linkIdSpan = Dom.createElement("span")
          Dom.setClassName(linkIdSpan, "tooltip-link-id")
          Dom.setTextContent(linkIdSpan, "Link: " ++ item.linkId) // Using linkId (e.g., A01) for user friendliness
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

          let nextZone = createDropZone(pipeline, index + 1, ~getState, ~dispatch)
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
