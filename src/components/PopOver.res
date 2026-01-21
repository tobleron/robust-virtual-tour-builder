/* src/components/PopOver.res */
open ReBindings

type position = {
  top: float,
  left: float,
}

type alignment = [#BottomLeft | #BottomRight | #TopLeft | #TopRight | #Auto]

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

@react.component
let make = (
  ~anchor: Dom.element,
  ~children: React.element,
  ~onClose: unit => unit,
  ~alignment: alignment=#Auto,
  ~offset: float=8.0,
) => {
  let (pos, setPos) = React.useState(_ => {top: 0.0, left: 0.0})
  let (isVisible, setIsVisible) = React.useState(_ => false)
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
        let spaceRight = viewportWidth -. anchorRect.left

        let vertical = spaceBelow < popoverRect.height && spaceAbove > spaceBelow ? #Top : #Bottom
        let horizontal = spaceRight < popoverRect.width ? #Right : #Left

        switch (vertical, horizontal) {
        | (#Top, #Left) => #TopLeft
        | (#Top, #Right) => #TopRight
        | (#Bottom, #Left) => #BottomLeft
        | (#Bottom, #Right) => #BottomRight
        }
      | other => other
      }

      let top = switch targetAlignment {
      | #BottomLeft | #BottomRight => anchorRect.bottom +. offset
      | #TopLeft | #TopRight => anchorRect.top -. popoverRect.height -. offset
      | #Auto => 0.0 // Should not happen
      }

      let left = switch targetAlignment {
      | #BottomLeft | #TopLeft => anchorRect.left
      | #BottomRight | #TopRight => anchorRect.right -. popoverRect.width
      | #Auto => 0.0 // Should not happen
      }

      // Final clamping to viewport
      let finalTop = Math.max(offset, Math.min(viewportHeight -. popoverRect.height -. offset, top))
      let finalLeft = Math.max(offset, Math.min(viewportWidth -. popoverRect.width -. offset, left))

      setPos(_ => {top: finalTop, left: finalLeft})
    | _ => ()
    }
  }, (anchor, alignment))

  // Initial position calculation and visibility trigger
  React.useEffect1(() => {
    calculatePosition()
    let id = Window.setTimeout(() => setIsVisible(_ => true), 10)
    Some(() => Window.clearTimeout(id))
  }, [calculatePosition])

  // Handle window resize/scroll to reposition
  React.useEffect0(() => {
    let handleReposition = _ => calculatePosition()
    Window.addEventListener("resize", handleReposition)
    Window.addEventListener("scroll", handleReposition)
    Some(
      () => {
        Window.removeEventListener("resize", handleReposition)
        Window.removeEventListener("scroll", handleReposition)
      },
    )
  })

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
      let target: Dom.element = Dom.target(e)->Obj.magic
      switch Nullable.toOption(popoverRef.current) {
      | Some(el) =>
        if !Dom.containsElement(el, target) && !Dom.containsElement(anchor, target) {
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
      className={"popover-root" ++ (isVisible ? " state-visible" : "")}
      style={makeStyle({
        "top": pos.top->Float.toString ++ "px",
        "left": pos.left->Float.toString ++ "px",
      })}
    >
      <div className="popover-content"> children </div>
    </div>
  </Portal>
}
