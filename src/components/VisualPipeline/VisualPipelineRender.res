/* src/components/VisualPipeline/VisualPipelineRender.res */

open ReBindings
open VisualPipelineTypes
open VisualPipelineLogic

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
