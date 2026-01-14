open ReBindings
open ViewerTypes
open ViewerState

let rec updateFollowLoop = () => {
  let progressUi = Dom.getElementById("processing-ui")
  let isBusy = switch Nullable.toOption(progressUi) {
  | Some(el) => !Dom.classList(el)["contains"]("hidden")
  | None => false
  }

  if !isBusy {
    let viewer = getActiveViewer()
    let storeState = GlobalStateBridge.getState()

    let hasDraft = switch storeState.linkDraft {
    | Some(_) => true
    | None => false
    }

    let hasViewer = switch Nullable.toOption(viewer) {
    | Some(_) => true
    | None => false
    }

    if !state.followLoopActive || !hasViewer || !hasDraft || !storeState.isLinking {
      state.followLoopActive = false
    } else {
      // Speed Factor
      let yawSpeed = 1.0
      let pitchSpeed = 0.7
      let deadzone = 0.1

      if Math.abs(state.mouseXNorm) > deadzone || Math.abs(state.mouseYNorm) > deadzone {
        let yawDelta = Math.pow(state.mouseXNorm, ~exp=3.0) *. yawSpeed
        let pitchDelta = -.(Math.pow(state.mouseYNorm, ~exp=3.0) *. pitchSpeed)

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
      | Some(v) => HotspotLine.updateLines(v, storeState, ~mouseEvent?, ())
      | None => ()
      }

      let _ = Window.requestAnimationFrame(updateFollowLoop)
    }
  }
}
