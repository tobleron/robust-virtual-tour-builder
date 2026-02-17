/* src/components/VisualPipeline.res - VisualPipeline Component */

open ReBindings
module Logic = VisualPipelineLogic.Logic
module Styles = VisualPipelineLogic.Styles

external toDomEvent: ReactEvent.Mouse.t => Dom.event = "%identity"

let injectStyles = () => {
  let existing = Dom.getElementById("visual-pipeline-styles")
  switch Nullable.toOption(existing) {
  | Some(_) => ()
  | None =>
    Logger.info(~module_="VisualPipelineStyles", ~message="INJECT_STYLES", ())
    let style = Dom.createElement("style")
    Dom.setId(style, "visual-pipeline-styles")
    Dom.setTextContent(style, Styles.styles)
    Dom.appendChild(Dom.head, style)
  }
}

module DropZone = {
  @react.component
  let make = (~index: int, ~onDrop: int => unit, ~isDragging: bool, ~color: string) => {
    let (isDragOver, setIsDragOver) = React.useState(_ => false)

    let handleDragOver = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
    }

    let handleDragEnter = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      if isDragging {
        setIsDragOver(_ => true)
      }
    }

    let handleDragLeave = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      setIsDragOver(_ => false)
    }

    let handleDrop = (e: ReactEvent.Mouse.t) => {
      ReactEvent.Mouse.preventDefault(e)
      setIsDragOver(_ => false)
      if isDragging {
        onDrop(index)
      }
    }

    let className = "drop-zone" ++ (isDragOver ? " drag-over" : "")

    // Use ReBindings.makeStyle for custom properties
    let style = ReBindings.makeStyle({"--pipe-color": color})

    <div
      className
      onDragOver=handleDragOver
      onDragEnter=handleDragEnter
      onDragLeave=handleDragLeave
      onDrop=handleDrop
      style
    />
  }
}

module PipelineNode = {
  @react.component
  let make = (
    ~item: Types.timelineItem,
    ~index as _index: int,
    ~isActive: bool,
    ~scene: option<Types.scene>,
    ~targetScene: option<Types.scene>,
    ~onActivate: string => unit,
    ~onRemove: string => unit,
    ~onDragStart: string => unit,
    ~onDragEnd: unit => unit,
    ~isDraggingSelf: bool,
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

    let handleDragStart = (e: ReactEvent.Mouse.t) => {
      onDragStart(item.id)
      // Need to ensure the drag operation is allowed
      let domEvent = toDomEvent(e)
      let dataTransfer = Dom.dataTransfer(domEvent)
      Dom.setEffectAllowed(dataTransfer, "move")
      Dom.setData(dataTransfer, "text/plain", item.id)
    }

    let handleDragEnd = (_e: ReactEvent.Mouse.t) => {
      onDragEnd()
    }

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
      if Window.confirm("Remove this step from the timeline?") {
        onRemove(item.id)
      }
    }

    let color = switch scene {
    | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
    | None => "var(--success-dark)"
    }

    let style = ReBindings.makeStyle({"--node-color": color})
    let className =
      "pipeline-node" ++ (isActive ? " active" : "") ++ (isDraggingSelf ? " is-dragging" : "")

    let isAutoForward = switch targetScene {
    | Some(ts) => ts.isAutoForward
    | None => false
    }

    <div
      className
      draggable=true
      role="button"
      tabIndex=0
      ariaLabel={"Timeline step: " ++
      targetScene->Option.map(ts => ts.name)->Option.getOr("Unknown")}
      onClick=handleClick
      onKeyDown=handleKeyDown
      onDragStart=handleDragStart
      onDragEnd=handleDragEnd
      onContextMenu=handleContextMenu
      style
    >
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
      {if isAutoForward {
        <span className="auto-forward-indicator"> {React.string("\u00BB")} </span>
      } else {
        React.null
      }}
      <div className="node-marker" />
    </div>
  }
}

@react.component
let make = () => {
  PerfUtils.useRenderBudget("VisualPipeline")
  injectStyles()

  let pipelineSlice = AppContext.usePipelineSlice()
  let dispatch = AppContext.useAppDispatch()

  let (dragSourceId, setDragSourceId) = React.useState(_ => None)

  // Wrapper class needs to know if dragging
  let wrapperClassName =
    "visual-pipeline-wrapper" ++ (Option.isSome(dragSourceId) ? " dragging-active" : "")

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

  let handleDragStart = React.useCallback1((itemId: string) => {
    setDragSourceId(_ => Some(itemId))
  }, [setDragSourceId])

  let handleDragEnd = React.useCallback1(() => {
    setDragSourceId(_ => None)
  }, [setDragSourceId])

  let handleDrop = React.useCallback2((dropIndex: int) => {
    switch dragSourceId {
    | Some(sourceId) =>
      let reorder = Logic.calculateReorder(pipelineSlice.timeline, sourceId, dropIndex)
      switch reorder {
      | Some((sourceIndex, finalIndex)) =>
        Logger.info(
          ~module_="VisualPipeline",
          ~message="REORDER_TIMELINE",
          ~data=Some({"from": sourceIndex, "to": finalIndex}),
          (),
        )
        dispatch(ReorderTimeline(sourceIndex, finalIndex))
      | None => ()
      }
    | None => ()
    }
    setDragSourceId(_ => None)
  }, (dragSourceId, pipelineSlice.timeline))

  if Belt.Array.length(pipelineSlice.timeline) == 0 {
    React.null
  } else {
    <div id="visual-pipeline-container">
      <div className=wrapperClassName>
        <div className="pipeline-track">
          // Render first drop zone (index 0)
          <DropZone
            index=0
            onDrop=handleDrop
            isDragging={Option.isSome(dragSourceId)}
            color={switch Belt.Array.get(pipelineSlice.timeline, 0) {
            | Some(firstItem) =>
              let scene = pipelineSlice.scenes->Belt.Array.getBy(s => s.id == firstItem.sceneId)
              switch scene {
              | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
              | None => "var(--success-dark)"
              }
            | None => "var(--success-dark)"
            }}
          />
          {pipelineSlice.timeline
          ->Belt.Array.mapWithIndex((index, item) => {
            let isActive = switch pipelineSlice.activeTimelineStepId {
            | Some(id) => id == item.id
            | None =>
              switch Belt.Array.get(pipelineSlice.scenes, pipelineSlice.activeIndex) {
              | Some(currentScene) =>
                // Find first match
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
            let color = switch scene {
            | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
            | None => "var(--success-dark)"
            }

            <React.Fragment key={item.id}>
              <PipelineNode
                item
                index
                isActive
                isDraggingSelf={switch dragSourceId {
                | Some(id) => id == item.id
                | None => false
                }}
                scene
                targetScene
                onActivate=handleNodeActivate
                onRemove=handleNodeRemove
                onDragStart=handleDragStart
                onDragEnd=handleDragEnd
              />
              <DropZone
                index={index + 1} onDrop=handleDrop isDragging={Option.isSome(dragSourceId)} color
              />
            </React.Fragment>
          })
          ->React.array}
        </div>
      </div>
    </div>
  }
}
