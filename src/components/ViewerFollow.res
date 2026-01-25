open ReBindings
open ViewerState

let rec updateFollowLoop = () => {
  let progressUi = Dom.getElementById("processing-ui")
  let isBusy = switch Nullable.toOption(progressUi) {
  | Some(el) => !(Dom.classList(el)->Dom.ClassList.contains("hidden"))
  | None => false
  }

  if !isBusy {
    let viewer = getActiveViewer()
    let storeState = GlobalStateBridge.getState()

    let hasViewer = switch Nullable.toOption(viewer) {
    | Some(_) => true
    | None => false
    }

    if !state.followLoopActive || !hasViewer || !storeState.isLinking {
      // Clear lines only if we are truly stopping
      if !state.isSceneLoading {
        let svg = Dom.getElementById("viewer-hotspot-lines")
        switch Nullable.toOption(svg) {
        | Some(el) => Dom.setTextContent(el, "")
        | None => ()
        }
      }
      state.followLoopActive = false
    } else {
      // Speed Factor
      let yawMaxSpeed = 1.5
      let pitchMaxSpeed = 1.0
      let deadzone = 0.5

      if storeState.isLinking {
        let getEdgePower = (val, dz) => {
          let absVal = Math.abs(val)
          if absVal > dz {
            let sign = val > 0.0 ? 1.0 : -1.0
            // Quadratic ramp: speed increases as we approach edge, slows as we return to center
            let normalized = (absVal -. dz) /. (1.0 -. dz)
            sign *. (normalized *. normalized)
          } else {
            0.0
          }
        }

        // Check startup deadzone (prevent instant movement when clicking Add Link near edge)
        let isInsideDeadzone = switch (
          Nullable.toOption(state.linkingStartPoint),
          Nullable.toOption(state.lastMouseEvent),
        ) {
        | (Some(start), Some(evt)) =>
          let cx = Belt.Int.toFloat(Dom.clientX(evt))
          let cy = Belt.Int.toFloat(Dom.clientY(evt))
          let dx = cx -. start["x"]
          let dy = cy -. start["y"]
          let dist = Math.sqrt(dx *. dx +. dy *. dy)
          if dist > 150.0 {
            // Threshold passed, clear the point so we don't check again
            state.linkingStartPoint = Nullable.null
            false
          } else {
            true
          }
        | (Some(_), None) => true // Have start point but no mouse event yet -> safe block
        | (None, _) => false
        }

        // Apply velocity boost
        let getVelocityBoost = vel => {
          let absVel = Math.abs(vel)

          // Threshold: ignore slow micro-movements, start boost after 500px/s
          if absVel > 500.0 {
            let boost = (absVel -. 500.0) /. 3000.0 // Scaled boost
            Math.min(boost, 1.5) // Cap boost at +150% speed (total 2.5x)
          } else {
            0.0
          }
        }

        let yawBoost = getVelocityBoost(state.mouseVelocityX)
        let pitchBoost = getVelocityBoost(state.mouseVelocityY)

        let yawDelta = if isInsideDeadzone {
          0.0
        } else {
          getEdgePower(state.mouseXNorm, deadzone) *. yawMaxSpeed *. (1.0 +. yawBoost)
        }
        let pitchDelta = if isInsideDeadzone {
          0.0
        } else {
          -.getEdgePower(state.mouseYNorm, deadzone) *. pitchMaxSpeed *. (1.0 +. pitchBoost)
        }

        // Reset velocity storage as we are now using direct mapping
        state.lastAppliedYaw = Nullable.null
        state.lastAppliedPitch = Nullable.null

        // Apply to Viewer
        switch Nullable.toOption(viewer) {
        | Some(v) =>
          if yawDelta != 0.0 {
            Viewer.setYaw(v, Viewer.getYaw(v) +. yawDelta, false)
          }
          if pitchDelta != 0.0 {
            Viewer.setPitch(v, Viewer.getPitch(v) +. pitchDelta, false)
          }
        | None => ()
        }
      }

      // HotspotLine Update
      // Skip updates during viewer swap to prevent race condition
      if !state.isSwapping {
        let mouseEvent = switch Nullable.toOption(state.lastMouseEvent) {
        | Some(e) => Some(e)
        | None => None
        }

        switch Nullable.toOption(viewer) {
        | Some(v) =>
          try {
            HotspotLine.updateLines(v, storeState, ~mouseEvent?, ())
          } catch {
          | e =>
            Logger.error(
              ~module_="ViewerFollow",
              ~message="UPDATE_LINES_ERROR",
              ~data=Some(Logger.castToJson(e)),
              (),
            )
          }
        | None => ()
        }
      }

      let _ = Window.requestAnimationFrame(updateFollowLoop)
    }
  }
}
