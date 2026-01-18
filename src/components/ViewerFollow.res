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

        let yawDelta = getEdgePower(state.mouseXNorm, deadzone) *. yawMaxSpeed
        let pitchDelta = -.getEdgePower(state.mouseYNorm, deadzone) *. pitchMaxSpeed

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
