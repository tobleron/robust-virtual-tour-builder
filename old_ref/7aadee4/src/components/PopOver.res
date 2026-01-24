/* src/components/PopOver.res */
open ReBindings

type position = {
  top: float,
  left: float,
}

type alignment = [
  | #BottomLeft
  | #BottomRight
  | #TopLeft
  | #TopRight
  | #Right
  | #Left
  | #Auto
]

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = (
  ~anchor: Dom.element,
  ~children: React.element,
  ~onClose: unit => unit,
  ~alignment: alignment=#Auto,
  ~offset: float=8.0,
  ~isTooltip: bool=false,
) => {
  let (pos, setPos) = React.useState(_ => {top: 0.0, left: 0.0})
  let (isVisible, setIsVisible) = React.useState(_ => false)
  let (maxHeight, setMaxHeight) = React.useState(_ => "none")
  let popoverRef = React.useRef(Nullable.null)

  let calculatePosition = React.useCallback2(() => {
    switch (Nullable.toOption(popoverRef.current), anchor) {
    | (Some(popoverEl), anchorEl) =>
      let anchorRect = Dom.getBoundingClientRect(anchorEl)
      let popoverRect = Dom.getBoundingClientRect(popoverEl)
      let viewportWidth = Window.innerWidth->Int.toFloat
      let viewportHeight = Window.innerHeight->Int.toFloat

      let targetAlignment = switch alignment {
      | #Auto =>
        // Determine best alignment based on available space
        let spaceBelow = viewportHeight -. anchorRect.bottom
        let spaceAbove = anchorRect.top
        let spaceRight = viewportWidth -. anchorRect.right

        if spaceRight > popoverRect.width +. offset {
          #Right
        } else if spaceBelow < popoverRect.height && spaceAbove > spaceBelow {
          #TopLeft
        } else {
          #BottomLeft
        }
      | other => other
      }

      let top = switch targetAlignment {
      | #BottomLeft | #BottomRight => anchorRect.bottom +. offset
      | #TopLeft | #TopRight => anchorRect.top -. popoverRect.height -. offset
      | #Right | #Left => anchorRect.top +. anchorRect.height /. 2.0 -. popoverRect.height /. 2.0
      | #Auto => 0.0
      }

      let left = switch targetAlignment {
      | #BottomLeft | #TopLeft => anchorRect.left
      | #BottomRight | #TopRight => anchorRect.right -. popoverRect.width
      | #Right => anchorRect.right +. offset
      | #Left => anchorRect.left -. popoverRect.width -. offset
      | #Auto => 0.0
      }

      // Clamping to viewport
      let finalTop = Math.max(offset, Math.min(viewportHeight -. popoverRect.height -. offset, top))
      let finalLeft = Math.max(offset, Math.min(viewportWidth -. popoverRect.width -. offset, left))

      // Dynamic max height calculation to prevent cropping
      let availableHeight = if finalTop < anchorRect.top {
        // Popover is above or covering anchor from top
        finalTop +. popoverRect.height
      } else {
        // Popover is below anchor
        viewportHeight -. finalTop -. offset
      }

      setMaxHeight(_ => availableHeight->Float.toString ++ "px")
      setPos(_ => {top: finalTop, left: finalLeft})
    | _ => ()
    }
  }, (anchor, alignment))

  // Initial position calculation and visibility trigger
  React.useEffect1(() => {
    // Immediate calculation if possible
    calculatePosition()

    // Slight delay to allow DOM to settle and measure again
    let id = Window.setTimeout(() => {
      calculatePosition()
      setIsVisible(_ => true)
    }, 30)
    Some(() => Window.clearTimeout(id))
  }, [calculatePosition])

  // Handle window resize/scroll to reposition
  React.useEffect2(() => {
    let handleUpdate = _ => calculatePosition()
    Window.addEventListener("resize", handleUpdate)
    Window.addEventListener("scroll", handleUpdate)

    Some(
      () => {
        Window.removeEventListener("resize", handleUpdate)
        Window.removeEventListener("scroll", handleUpdate)
      },
    )
  }, (isVisible, calculatePosition))

  // Handle high-frequency repositioning (for moving anchors like hotspots)
  React.useEffect2(() => {
    let frameId = ref(0)

    let rec loop = () => {
      calculatePosition()
      frameId := Window.requestAnimationFrame(loop)
    }

    if isVisible {
      frameId := Window.requestAnimationFrame(loop)
    }

    Some(
      () => {
        Window.cancelAnimationFrame(frameId.contents)
      },
    )
  }, (isVisible, calculatePosition))

  // Handle outside clicks
  React.useEffect1(() => {
    let handleOutsideClick = (e: Dom.event) => {
      switch Nullable.toOption(popoverRef.current) {
      | Some(popoverEl) =>
        let target = Dom.target(e)
        if !Dom.containsElement(popoverEl, target) && !Dom.containsElement(anchor, target) {
          onClose()
        }
      | None => ()
      }
    }

    Window.addEventListener("mousedown", handleOutsideClick)
    Some(() => Window.removeEventListener("mousedown", handleOutsideClick))
  }, [onClose])

  <Portal>
    <div
      ref={ReactDOM.Ref.domRef(popoverRef)}
      className={"popover-root" ++
      (isVisible ? " state-visible" : "") ++ (isTooltip ? " popover-tooltip" : "")}
      style={makeStyle({
        "top": pos.top->Float.toString ++ "px",
        "left": pos.left->Float.toString ++ "px",
      })}
    >
      <div
        className="popover-content"
        style={makeStyle({
          "maxHeight": maxHeight,
          "overflowY": "auto",
          "display": "flex",
          "flexDirection": "column",
        })}
      >
        children
      </div>
    </div>
  </Portal>
}
