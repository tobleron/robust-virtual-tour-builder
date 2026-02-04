/* src/systems/InputSystem.res */

open ReBindings
open ViewerState
open Actions
open EventBus

let normalizeMouseCoords = (e: Dom.event, element: Dom.element) => {
  let rect = Dom.getBoundingClientRect(element)
  let clientX = Belt.Int.toFloat(Dom.clientX(e))
  let clientY = Belt.Int.toFloat(Dom.clientY(e))

  let x = clientX -. rect.left
  let y = clientY -. rect.top

  {
    "x": x,
    "y": y,
    "xNorm": x /. rect.width *. 2.0 -. 1.0,
    "yNorm": (y +. Constants.linkingRodHeight) /. rect.height *. 2.0 -. 1.0,
    "width": rect.width,
    "height": rect.height,
  }
}

let handleMouseMove = (e: Dom.event) => {
  ViewerState.state := {...ViewerState.state.contents, lastMouseEvent: Nullable.make(e)}

  let stage = Dom.getElementById("viewer-stage")
  switch Nullable.toOption(stage) {
  | Some(el) =>
    let coords = normalizeMouseCoords(e, el)

    ViewerState.state := {
        ...ViewerState.state.contents,
        mouseXNorm: coords["xNorm"],
        mouseYNorm: coords["yNorm"],
      }

    // Physics Update
    CursorPhysics.calculateVelocity(coords["x"], coords["y"])

    // Rod UI Update
    let currentState = GlobalStateBridge.getState()
    CursorPhysics.updateRodPosition(coords["x"], coords["y"], currentState.isLinking)

  | None => ()
  }
}

let handleKeyDown = e => {
  let key = Dom.key(e)
  let ctrlKey = Dom.ctrlKey(e)
  let shiftKey = Dom.shiftKey(e)

  if key == "Escape" {
    // 0. Handle Link Cancellation
    let storeState = GlobalStateBridge.getState()
    if storeState.isLinking {
      GlobalStateBridge.dispatch(StopLinking)
      EventBus.dispatch(ShowNotification("Link Cancelled", #Info, None))
    }

    // 0b. Handle Navigation Interruption
    switch storeState.navigationFsm {
    | NavigationFSM.Idle | NavigationFSM.Error(_) => ()
    | _ => GlobalStateBridge.dispatch(Actions.DispatchNavigationFsmEvent(NavigationFSM.Aborted))
    }

    // 1. Close Modals
    let closeBtn = Dom.getElementById("btn-close-style")
    switch Nullable.toOption(closeBtn) {
    | Some(btn) => Dom.click(btn)
    | None => ()
    }

    // 2. Hide Context Menu
    let contextMenu = Dom.getElementById("context-menu")
    switch Nullable.toOption(contextMenu) {
    | Some(m) => Dom.ClassList.add(Dom.classList(m), "hidden")
    | None => ()
    }
  }

  if key == "Enter" {
    Logger.debug(~module_="InputSystem", ~message="ENTER_KEY_PRESSED", ())
    LinkEditorLogic.handleEnter()
  }

  // 3. Debug Toggle
  if ctrlKey && shiftKey && (key == "D" || key == "d") {
    let _ = %raw(`
      (function() {
        if (window.DEBUG && typeof window.DEBUG.toggle === 'function') {
          window.DEBUG.toggle();
        }
      })()
    `)
  }
}

let initInputSystem = () => {
  Logger.initialized(~module_="InputSystem")
  Logger.debug(~module_="InputSystem", ~message="KEYBOARD_LISTENERS_ATTACHED", ())
  Window.addEventListener("keydown", handleKeyDown)
  () => Window.removeEventListener("keydown", handleKeyDown)
}
