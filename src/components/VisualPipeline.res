/* src/components/VisualPipeline.res - Visual Pipeline V2: Thumbnail Chain */

open ReBindings
module Styles = VisualPipelineLogic.Styles

let injectStyles = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  let style = switch Nullable.toOption(existing) {
  | Some(el) => el
  | None =>
    let el = Dom.createElement("style")
    Dom.setId(el, "visual-pipeline-styles")
    Dom.appendChild(Dom.head, el)
    el
  }
  Dom.setTextContent(style, Styles.styles)
}



module PipelineNode = {
  @react.component
  let make = (
    ~item: Types.timelineItem,
    ~index: int,
    ~isActive: bool,
    ~scene: option<Types.scene>,
    ~targetScene: option<Types.scene>,
    ~onActivate: string => unit,
    ~onRemove: string => unit,
  ) => {
    let (thumbUrl, setThumbUrl) = React.useState(_ => "")

    React.useEffect1(() => {
      switch scene {
      | Some(s) =>
        let file = s.tinyFile->Option.getOr(s.file)
        let url = UrlUtils.fileToUrl(file)
        if url != thumbUrl {
          setThumbUrl(_ => url)
        }
        Some(() => UrlUtils.revokeUrl(url))
      | None =>
        setThumbUrl(_ => "")
        None
      }
    }, [scene])

    let handleClick = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      onActivate(item.id)
    }

    let handleKeyDown = (e: ReactEvent.Keyboard.t) => {
      let key = ReactEvent.Keyboard.key(e)
      if key == "Enter" || key == " " {
        ReactEvent.Keyboard.preventDefault(e)
        onActivate(item.id)
      }
    }

    let handleContextMenu = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      onRemove(item.id)
    }

    let isAutoForward = switch scene {
    | Some(s) =>
      let hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == item.linkId)
      switch hotspot {
      | Some(h) =>
        switch h.isAutoForward {
        | Some(true) => true
        | _ => false
        }
      | None => false
      }
    | None => false
    }

    let color = if isAutoForward {
      "#4B0082"
    } else {
      switch scene {
      | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
      | None => "var(--primary-ui-blue)"
      }
    }

    let style = ReBindings.makeStyle({"--node-color": color})
    let className = "pipeline-node" ++ (isActive ? " active" : "")

    // Determine what number to show — find the scene index in the scenes array
    let sceneNumber = switch scene {
    | Some(s) =>
      let idx = AppContext.getBridgeState().scenes->Belt.Array.getIndexBy(sc => sc.id == s.id)
      switch idx {
      | Some(i) => i + 1
      | None => index + 1
      }
    | None => index + 1
    }

    <div
      className
      role="button"
      tabIndex=0
      ariaLabel={"Timeline step: " ++
      targetScene->Option.map(ts => ts.name)->Option.getOr("Unknown")}
      onClick=handleClick
      onKeyDown=handleKeyDown
      onContextMenu=handleContextMenu
      style
    >
      {if thumbUrl != "" {
        <img
          src=thumbUrl
          className="pipeline-thumb"
          alt={scene->Option.map(s => s.name)->Option.getOr("Unknown Scene") ++ " preview"}
          draggable=false
        />
      } else {
        <div className="pipeline-thumb" />
      }}
      <div className="pipeline-badge"> {React.int(sceneNumber)} </div>
      <div className="node-tooltip">
        <span className="tooltip-link-id"> {React.string("Link: " ++ item.linkId)} </span>
        {if thumbUrl != "" {
          <img
            src=thumbUrl
            className="tooltip-thumb"
            alt={scene->Option.map(s => s.name)->Option.getOr("Unknown Scene") ++ " preview"}
          />
        } else {
          React.null
        }}
        <span className="tooltip-text">
          {React.string(scene->Option.map(s => s.name)->Option.getOr("Unknown Scene"))}
        </span>
      </div>
    </div>
  }
}

@react.component
let make = () => {
  PerfUtils.useRenderBudget("VisualPipeline")
  injectStyles()

  let pipelineSlice = AppContext.usePipelineSlice()
  let dispatch = AppContext.useAppDispatch()

  let handleNodeActivate = React.useCallback1((itemId: string) => {
    Logger.debug(
      ~module_="VisualPipeline",
      ~message="ACTIVATE_NODE",
      ~data=Some({"id": itemId}),
      (),
    )
    dispatch(Actions.SetActiveTimelineStep(Some(itemId)))

    let item = pipelineSlice.timeline->Belt.Array.getBy(t => t.id == itemId)
    switch item {
    | Some(t) =>
      let sceneIdx =
        pipelineSlice.scenes->Belt.Array.getIndexBy(s => s.id == t.sceneId)->Option.getOr(-1)
      if sceneIdx != -1 {
        let scene = Belt.Array.get(pipelineSlice.scenes, sceneIdx)
        switch scene {
        | Some(s) =>
          let hotspot = s.hotspots->Belt.Array.getBy(h => h.linkId == t.linkId)
          switch hotspot {
          | Some(h) => dispatch(SetActiveScene(sceneIdx, h.yaw, h.pitch, None))
          | None => dispatch(SetActiveScene(sceneIdx, 0.0, 0.0, None))
          }
        | None => ()
        }
      }
    | None => ()
    }
  }, [pipelineSlice])

  let handleNodeRemove = React.useCallback1((itemId: string) => {
    Logger.info(~module_="VisualPipeline", ~message="REMOVE_STEP", ~data=Some({"id": itemId}), ())
    dispatch(RemoveFromTimeline(itemId))
  }, [dispatch])

  if Belt.Array.length(pipelineSlice.timeline) == 0 {
    React.null
  } else {
    <div id="visual-pipeline-container">
      <div className="visual-pipeline-wrapper">
        <div className="pipeline-track">
          {pipelineSlice.timeline
          ->Belt.Array.mapWithIndex((index, item) => {
            let isActive = switch pipelineSlice.activeTimelineStepId {
            | Some(id) => id == item.id
            | None =>
              switch Belt.Array.get(pipelineSlice.scenes, pipelineSlice.activeIndex) {
              | Some(currentScene) =>
                let firstMatchIdx =
                  pipelineSlice.timeline
                  ->Belt.Array.getIndexBy(t => t.sceneId == currentScene.id)
                  ->Option.getOr(-1)
                item.sceneId == currentScene.id && firstMatchIdx == index
              | None => false
              }
            }

            let scene = pipelineSlice.scenes->Belt.Array.getBy(s => s.id == item.sceneId)
            let targetScene =
              pipelineSlice.scenes
              ->Belt.Array.getBy(s => s.id == item.targetScene)
              ->Option.orElse(
                pipelineSlice.scenes->Belt.Array.getBy(s => s.name == item.targetScene),
              )

            <React.Fragment key={item.id}>
              <PipelineNode
                item
                index
                isActive
                scene
                targetScene
                onActivate=handleNodeActivate
                onRemove=handleNodeRemove
              />
            </React.Fragment>
          })
          ->React.array}
        </div>
      </div>
    </div>
  }
}
