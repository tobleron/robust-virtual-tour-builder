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

    let _hasDraft = switch storeState.linkDraft {
    | Some(_) => true
    | None => false
    }

    let hasViewer = switch Nullable.toOption(viewer) {
    | Some(_) => true
    | None => false
    }

    // We want the loop to run if linking is active OR if the current scene has hotspots to draw (red lines)
    let hasHotspots = if (
      storeState.activeIndex >= 0 && storeState.activeIndex < Array.length(storeState.scenes)
    ) {
      switch Belt.Array.get(storeState.scenes, storeState.activeIndex) {
      | Some(s) => Array.length(s.hotspots) > 0
      | None => false
      }
    } else {
      false
    }

    if !state.followLoopActive || !hasViewer || (!storeState.isLinking && !hasHotspots) {
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
      let yawMaxSpeed = 1.2
      let pitchMaxSpeed = 0.8
      let deadzone = 0.85

      if storeState.isLinking {
        // Calculate normalized distance beyond the deadzone
        let getEdgePower = (val, dz) => {
          let absVal = Math.abs(val)
          if absVal > dz {
            let sign = val > 0.0 ? 1.0 : -1.0
            let normalized = (absVal -. dz) /. (1.0 -. dz)
            sign *. Math.pow(normalized, ~exp=2.0)
          } else {
            0.0
          }
        }

        // Target velocity based on input
        let targetYawDelta = getEdgePower(state.mouseXNorm, deadzone) *. yawMaxSpeed
        let targetPitchDelta = -.getEdgePower(state.mouseYNorm, deadzone) *. pitchMaxSpeed

        // Get current velocity (momentum)
        let currentYawDelta =
          Nullable.toOption(state.lastAppliedYaw)->Belt.Option.getWithDefault(0.0)
        let currentPitchDelta =
          Nullable.toOption(state.lastAppliedPitch)->Belt.Option.getWithDefault(0.0)

        // Physics Constants
        // accel: Fast response when speeding up
        // decel: Slow decay (inertia) when slowing down or reversing
        let accelFactor = 0.20
        let decelFactor = 0.05

        // Calculate Yaw Factor
        let yawFactor = if (
          Math.abs(targetYawDelta) >= Math.abs(currentYawDelta) &&
            (targetYawDelta == 0.0 ||
            currentYawDelta == 0.0 ||
            targetYawDelta > 0.0 == (currentYawDelta > 0.0))
        ) {
          accelFactor
        } else {
          decelFactor
        }

        // Calculate Pitch Factor
        let pitchFactor = if (
          Math.abs(targetPitchDelta) >= Math.abs(currentPitchDelta) &&
            (targetPitchDelta == 0.0 ||
            currentPitchDelta == 0.0 ||
            targetPitchDelta > 0.0 == (currentPitchDelta > 0.0))
        ) {
          accelFactor
        } else {
          decelFactor
        }

        // Apply Smoothing (Lerp)
        let newYawDelta = currentYawDelta +. (targetYawDelta -. currentYawDelta) *. yawFactor
        let newPitchDelta =
          currentPitchDelta +. (targetPitchDelta -. currentPitchDelta) *. pitchFactor

        // Clamp near zero to prevent endless micro-movements
        let newYawDelta = if Math.abs(newYawDelta) < 0.001 {
          0.0
        } else {
          newYawDelta
        }
        let newPitchDelta = if Math.abs(newPitchDelta) < 0.001 {
          0.0
        } else {
          newPitchDelta
        }

        // Store new velocity
        state.lastAppliedYaw = Nullable.make(newYawDelta)
        state.lastAppliedPitch = Nullable.make(newPitchDelta)

        // Apply to Viewer
        switch Nullable.toOption(viewer) {
        | Some(v) =>
          if newYawDelta != 0.0 {
            Viewer.setYaw(v, Viewer.getYaw(v) +. newYawDelta, false)
          }
          if newPitchDelta != 0.0 {
            Viewer.setPitch(v, Viewer.getPitch(v) +. newPitchDelta, false)
          }
        | None => ()
        }
      }

      // HotspotLine Update
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
            ~data=Some(Obj.magic(e)),
            (),
          )
        }
      | None => ()
      }

      let _ = Window.requestAnimationFrame(updateFollowLoop)
    }
  }
}
