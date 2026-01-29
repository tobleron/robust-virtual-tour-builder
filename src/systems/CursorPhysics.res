/* src/systems/CursorPhysics.res */

open ReBindings
open ViewerState

let calculateVelocity = (x: float, y: float) => {
  let now = Date.now()
  let dt = (now -. ViewerState.state.contents.lastMoveTime) /. 1000.0 // seconds

  if dt > 0.0 && dt < 0.1 {
    // Only calculate if the time delta is reasonable (e.g., skip big gaps or 0ms)
    let velX = (x -. ViewerState.state.contents.lastMoveX) /. dt
    let velY = (y -. ViewerState.state.contents.lastMoveY) /. dt

    // Apply a bit of smoothing (low-pass filter) to avoid spikes
    let smoothing = 0.7
    let newVelX =
      ViewerState.state.contents.mouseVelocityX *. smoothing +. velX *. (1.0 -. smoothing)
    let newVelY =
      ViewerState.state.contents.mouseVelocityY *. smoothing +. velY *. (1.0 -. smoothing)

    ViewerState.state := {
      ...ViewerState.state.contents,
      mouseVelocityX: newVelX,
      mouseVelocityY: newVelY
    }
  }

  ViewerState.state := {
    ...ViewerState.state.contents,
    lastMoveX: x,
    lastMoveY: y,
    lastMoveTime: now
  }
}

let updateRodPosition = (x: float, y: float, isLinking: bool) => {
  let guide = Dom.getElementById("cursor-guide")

  switch Nullable.toOption(guide) {
  | Some(g) =>
    if isLinking {
      // Ensure rod is visible and accurately positioned (v4.3.1 fix)
      Dom.setProperty(g, "display", "block")

      // Use transform for more reliable positioning that ignores layout flow
      Dom.setProperty(
        g,
        "transform",
        "translate(" ++
        Float.toString(Math.round(x)) ++
        "px, " ++
        Float.toString(Math.round(y)) ++ "px)",
      )

      // Reset left/top to avoid conflicts with transform
      Dom.setLeft(g, "0px")
      Dom.setTop(g, "0px")
      Dom.setStyleHeight(g, Float.toString(Constants.linkingRodHeight) ++ "px")

      // Re-enable follow loop for wider waypoints navigation (Stage 2)
      if !ViewerState.state.contents.followLoopActive {
        ViewerState.state := {...ViewerState.state.contents, followLoopActive: true}
        ViewerSystem.Follow.updateFollowLoop()
      }
    } else {
      Dom.setProperty(g, "display", "none !important")
      Dom.classList(g)->Dom.ClassList.remove("cursor-dot-blinking")
    }
  | None => ()
  }
}
