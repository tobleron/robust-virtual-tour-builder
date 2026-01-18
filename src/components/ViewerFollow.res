open ReBindings
open ViewerTypes
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
      let yawSpeed = 1.2
      let pitchSpeed = 0.8
      let deadzone = 0.85

      if (
        storeState.isLinking &&
        (Math.abs(state.mouseXNorm) > deadzone || Math.abs(state.mouseYNorm) > deadzone)
      ) {
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

        let yawDelta = getEdgePower(state.mouseXNorm, deadzone) *. yawSpeed
        let pitchDelta = -.getEdgePower(state.mouseYNorm, deadzone) *. pitchSpeed

        let appliedYawDelta = ref(0.0)
        let appliedPitchDelta = ref(0.0)

        state.ratchetState.yawOffset = state.ratchetState.yawOffset +. yawDelta
        state.ratchetState.pitchOffset = state.ratchetState.pitchOffset +. pitchDelta

        let edgeThreshold = 0.85
        let edgeReluctance = 0.4

        if state.ratchetState.yawOffset > state.ratchetState.maxYawOffset {
          appliedYawDelta := state.ratchetState.yawOffset -. state.ratchetState.maxYawOffset
          state.ratchetState.maxYawOffset = state.ratchetState.yawOffset
          state.ratchetState.minYawOffset = Math.min(
            state.ratchetState.minYawOffset,
            state.ratchetState.yawOffset,
          )
        } else if state.ratchetState.yawOffset < state.ratchetState.minYawOffset {
          appliedYawDelta := state.ratchetState.yawOffset -. state.ratchetState.minYawOffset
          state.ratchetState.minYawOffset = state.ratchetState.yawOffset
          state.ratchetState.maxYawOffset = Math.max(
            state.ratchetState.maxYawOffset,
            state.ratchetState.yawOffset,
          )
        } else if Math.abs(state.mouseXNorm) > edgeThreshold {
          appliedYawDelta := yawDelta *. edgeReluctance
          state.ratchetState.maxYawOffset =
            state.ratchetState.maxYawOffset +. appliedYawDelta.contents
          state.ratchetState.minYawOffset =
            state.ratchetState.minYawOffset +. appliedYawDelta.contents
        }

        if state.ratchetState.pitchOffset > state.ratchetState.maxPitchOffset {
          appliedPitchDelta := state.ratchetState.pitchOffset -. state.ratchetState.maxPitchOffset
          state.ratchetState.maxPitchOffset = state.ratchetState.pitchOffset
          state.ratchetState.minPitchOffset = Math.min(
            state.ratchetState.minPitchOffset,
            state.ratchetState.pitchOffset,
          )
        } else if state.ratchetState.pitchOffset < state.ratchetState.minPitchOffset {
          appliedPitchDelta := state.ratchetState.pitchOffset -. state.ratchetState.minPitchOffset
          state.ratchetState.minPitchOffset = state.ratchetState.pitchOffset
          state.ratchetState.maxPitchOffset = Math.max(
            state.ratchetState.maxPitchOffset,
            state.ratchetState.pitchOffset,
          )
        } else if Math.abs(state.mouseYNorm) > edgeThreshold {
          appliedPitchDelta := pitchDelta *. edgeReluctance
          state.ratchetState.maxPitchOffset =
            state.ratchetState.maxPitchOffset +. appliedPitchDelta.contents
          state.ratchetState.minPitchOffset =
            state.ratchetState.minPitchOffset +. appliedPitchDelta.contents
        }

        switch Nullable.toOption(viewer) {
        | Some(v) =>
          if appliedYawDelta.contents != 0.0 {
            Viewer.setYaw(v, Viewer.getYaw(v) +. appliedYawDelta.contents, false)
          }
          if appliedPitchDelta.contents != 0.0 {
            Viewer.setPitch(v, Viewer.getPitch(v) +. appliedPitchDelta.contents, false)
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
