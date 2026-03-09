// @efficiency-role: ui-component

type flickerState = [#Clear | #Delete | #None | #Throttled]

let useSceneItemRef = sceneId => {
  let sceneItemRef = React.useRef(Nullable.null)

  React.useEffect1(() => {
    switch Nullable.toOption(sceneItemRef.current) {
    | Some(el) => ReBindings.Dom.setAttribute(el, "data-scene-id", sceneId)
    | None => ()
    }
    None
  }, [sceneId])

  sceneItemRef
}

let useMenuFeedback = (~wasThrottled, ~index, ~onItemClearLinks, ~onItemDelete) => {
  let (isMenuOpen, setMenuOpen) = React.useState(_ => false)
  let (flickerState, setFlickerState) = React.useState(_ => #None)

  React.useEffect1(() => {
    if wasThrottled {
      setFlickerState(_ => #Throttled)
      let timeoutId = ReBindings.Window.setTimeout(
        () => {
          setFlickerState(_ => #None)
        },
        600,
      )
      Some(() => ReBindings.Window.clearTimeout(timeoutId))
    } else {
      None
    }
  }, [wasThrottled])

  let scheduleMenuAction = (event, nextState: flickerState, onComplete) => {
    JsxEvent.Mouse.preventDefault(event)
    JsxEvent.Mouse.stopPropagation(event)
    setFlickerState(_ => nextState)
    let _ = ReBindings.Window.setTimeout(() => {
      setFlickerState(_ => #None)
      setMenuOpen(_ => false)
      onComplete()
    }, 800)
  }

  let handleClearClick = event =>
    scheduleMenuAction(event, #Clear, () => onItemClearLinks(index))
  let handleDeleteClick = event =>
    scheduleMenuAction(event, #Delete, () => onItemDelete(index))
  let throttleClasses = switch flickerState {
  | #Throttled => "ring-2 ring-primary/40 opacity-80 cursor-wait"
  | _ => ""
  }
  let isBusy = flickerState == #Throttled

  (
    isMenuOpen,
    setMenuOpen,
    flickerState,
    handleClearClick,
    handleDeleteClick,
    throttleClasses,
    isBusy,
  )
}
