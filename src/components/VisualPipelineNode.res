type nodeItem = {nodeId: string, linkId: string}

@react.component
let make = (
  ~item: nodeItem,
  ~nodeDomId: string,
  ~isActive: bool,
  ~interactionDisabled: bool,
  ~scene: option<Types.scene>,
  ~isAutoForward: bool,
  ~onActivate: string => unit,
  ~onRemove: string => unit,
  ~onHoverStart: (option<Types.scene>, string) => unit,
  ~onHoverEnd: unit => unit,
) => {
  ignore(onHoverStart)
  ignore(onHoverEnd)

  let handleClick = (e: ReactEvent.Mouse.t) => {
    ReactEvent.Mouse.preventDefault(e)
    if !interactionDisabled {
      onActivate(item.nodeId)
    }
  }

  let handleKeyDown = (e: ReactEvent.Keyboard.t) => {
    let key = ReactEvent.Keyboard.key(e)
    if !interactionDisabled && (key == "Enter" || key == " ") {
      ReactEvent.Keyboard.preventDefault(e)
      onActivate(item.nodeId)
    }
  }

  let handleContextMenu = (e: ReactEvent.Mouse.t) => {
    ReactEvent.Mouse.preventDefault(e)
    if !interactionDisabled {
      onRemove(item.nodeId)
    }
  }

  let localHandleMouseEnter = _e => {
    /* Hover effects disabled */
    ()
  }

  let localHandleMouseLeave = _e => {
    /* Hover effects disabled */
    ()
  }

  let color = if isAutoForward {
    "var(--success)"
  } else {
    switch scene {
    | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
    | None => "var(--primary-ui-blue)"
    }
  }

  let style = ReBindings.makeStyle({"--node-color": color})
  let className =
    "pipeline-node pipeline-square visual-pipeline-square" ++
    (isActive ? " active" : "") ++ (interactionDisabled ? " disabled" : "")

  <div
    id={nodeDomId}
    className
    role="button"
    tabIndex={interactionDisabled ? -1 : 0}
    ariaDisabled=interactionDisabled
    ariaLabel={"Timeline step: " ++ scene->Option.map(ts => ts.name)->Option.getOr("Unknown")}
    onClick=handleClick
    onKeyDown=handleKeyDown
    onContextMenu=handleContextMenu
    onMouseEnter=localHandleMouseEnter
    onMouseLeave=localHandleMouseLeave
    onFocus={_ => ()}
    onBlur={_ => ()}
    style
  >
    {React.null}
  </div>
}
