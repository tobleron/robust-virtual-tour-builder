@react.component
let make = (
  ~item: Types.timelineItem,
  ~isActive: bool,
  ~interactionDisabled: bool,
  ~scene: option<Types.scene>,
  ~targetScene: option<Types.scene>,
  ~onActivate: string => unit,
  ~onRemove: string => unit,
  ~onHoverStart: (option<Types.scene>, string) => unit,
  ~onHoverEnd: unit => unit,
) => {
  let handleClick = (e: ReactEvent.Mouse.t) => {
    ReactEvent.Mouse.preventDefault(e)
    if !interactionDisabled {
      onActivate(item.id)
    }
  }

  let handleKeyDown = (e: ReactEvent.Keyboard.t) => {
    let key = ReactEvent.Keyboard.key(e)
    if !interactionDisabled && (key == "Enter" || key == " ") {
      ReactEvent.Keyboard.preventDefault(e)
      onActivate(item.id)
    }
  }

  let handleContextMenu = (e: ReactEvent.Mouse.t) => {
    ReactEvent.Mouse.preventDefault(e)
    if !interactionDisabled {
      onRemove(item.id)
    }
  }

  let handleMouseEnter = (_e: ReactEvent.Mouse.t) =>
    if !interactionDisabled {
      onHoverStart(scene, item.linkId)
    }
  let handleMouseLeave = (_e: ReactEvent.Mouse.t) => onHoverEnd()
  let handleFocus = (_e: ReactEvent.Focus.t) =>
    if !interactionDisabled {
      onHoverStart(scene, item.linkId)
    }
  let handleBlur = (_e: ReactEvent.Focus.t) => onHoverEnd()

  let (linkIdVisible, setLinkIdVisible) = React.useState(_ => false)
  let linkIdTimerRef = React.useRef((None: option<int>))

  React.useEffect2(() => {
    None
  }, (isActive, interactionDisabled))

  let startLinkIdTimer = () => {
    switch linkIdTimerRef.current {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    linkIdTimerRef.current = Some(ReBindings.Window.setTimeout(() => {
        setLinkIdVisible(_ => true)
      }, 3000))
  }

  let stopLinkIdTimer = () => {
    switch linkIdTimerRef.current {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    linkIdTimerRef.current = None
    setLinkIdVisible(_ => false)
  }

  let localHandleMouseEnter = e => {
    if !interactionDisabled {
      startLinkIdTimer()
      handleMouseEnter(e)
    }
  }

  let localHandleMouseLeave = e => {
    stopLinkIdTimer()
    handleMouseLeave(e)
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
    "var(--success)"
  } else {
    switch scene {
    | Some(s) => ColorPalette.getGroupColor(s.colorGroup)
    | None => "var(--primary-ui-blue)"
    }
  }

  let style = ReBindings.makeStyle({"--node-color": color})
  let className =
    "pipeline-node" ++ (isActive ? " active" : "") ++ (interactionDisabled ? " disabled" : "")

  <div
    className
    role="button"
    tabIndex={interactionDisabled ? -1 : 0}
    ariaDisabled=interactionDisabled
    ariaLabel={"Timeline step: " ++ targetScene->Option.map(ts => ts.name)->Option.getOr("Unknown")}
    onClick=handleClick
    onKeyDown=handleKeyDown
    onContextMenu=handleContextMenu
    onMouseEnter=localHandleMouseEnter
    onMouseLeave=localHandleMouseLeave
    onFocus=handleFocus
    onBlur=handleBlur
    style
  >
    {linkIdVisible
      ? <div className="pipeline-node-tooltip">
          <span className="tooltip-label"> {React.string("ID")} </span>
          <span className="tooltip-value"> {React.string(item.linkId)} </span>
        </div>
      : React.null}
  </div>
}
