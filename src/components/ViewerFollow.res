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

      // --- PREMIUM CURSOR & INDICATOR LOGIC ---
      let centerIndicator = Dom.getElementById("viewer-center-indicator")
      let guide = state.guide
      let stage = Dom.getElementById("viewer-stage")

      switch (
        Nullable.toOption(centerIndicator),
        Nullable.toOption(guide),
        Nullable.toOption(stage),
        Nullable.toOption(viewer),
      ) {
      | (Some(ci), Some(gd), Some(stg), Some(v)) =>
        let rect = Dom.getBoundingClientRect(stg)
        let mouseX = (state.mouseXNorm +. 1.0) /. 2.0 *. rect.width
        let mouseY = (state.mouseYNorm +. 1.0) /. 2.0 *. rect.height

        if !storeState.isLinking {
          Dom.setDisplay(ci, "none")
          Dom.setDisplay(gd, "none")
        } else {
          // Rod height calculation helper
          let updateRodHeight = (v, ev, rect: Dom.rect, gd) => {
            let pCoords = Viewer.mouseEventToCoords(v, ev)
            let clickPitch = Belt.Array.getExn(pCoords, 0)
            let targetPitch = clickPitch -. 15.0
            let toRad = deg => deg *. Math.Constants.pi /. 180.0
            let hfov = Viewer.getHfov(v)
            let camPitch = Viewer.getPitch(v)
            let aspectRatio = rect.width /. rect.height
            let tanVfov2 = Math.tan(toRad(hfov /. 2.0)) /. aspectRatio
            let yClickRel = Math.tan(toRad(clickPitch -. camPitch)) /. tanVfov2
            let yTargetRel = Math.tan(toRad(targetPitch -. camPitch)) /. tanVfov2
            let halfHeight = rect.height /. 2.0
            let yClickScreen = halfHeight *. (1.0 -. yClickRel)
            let yTargetScreen = halfHeight *. (1.0 -. yTargetRel)
            let guideHeight = yTargetScreen -. yClickScreen
            Dom.setStyleHeight(gd, Float.toString(Math.max(0.0, guideHeight)) ++ "px")
          }

          switch storeState.linkDraft {
          | None =>
            // --- PHASE 1: Tracking Cursor before first click ---
            Dom.setDisplay(ci, "block")
            Dom.classList(ci)->Dom.ClassList.add("animate-slow-blink")
            Dom.setLeft(ci, Float.toString(mouseX) ++ "px")
            Dom.setTop(ci, Float.toString(mouseY) ++ "px")

            // Show yellow crosshair guide immediately for aiming
            Dom.setDisplay(gd, "block")
            Dom.setLeft(gd, Float.toString(mouseX) ++ "px")
            Dom.setTop(gd, Float.toString(mouseY) ++ "px")

            switch mouseEvent {
            | Some(ev) => updateRodHeight(v, ev, rect, gd)
            | None => ()
            }
          | Some(draft) =>
            // --- PHASE 2: Anchored Start with Laser Rod following mouse ---
            Dom.classList(ci)->Dom.ClassList.remove("animate-slow-blink")

            // Anchored Circle represents the CAMERA's starting orientation or first click
            let coords = HotspotLine.getScreenCoords(v, draft.camPitch, draft.camYaw, rect)
            switch coords {
            | Some(c) =>
              Dom.setDisplay(ci, "block")
              Dom.setLeft(ci, Float.toString(c.x) ++ "px")
              Dom.setTop(ci, Float.toString(c.y) ++ "px")
            | None => Dom.setDisplay(ci, "none")
            }

            // Yellow Crosshair (Laser Rod Tip) follows mouse
            Dom.setDisplay(gd, "block")
            Dom.setLeft(gd, Float.toString(mouseX) ++ "px")
            Dom.setTop(gd, Float.toString(mouseY) ++ "px")

            // PRECISION PERSPECTIVE LASER ROD (Calculates height based on pitch)
            switch mouseEvent {
            | Some(ev) => updateRodHeight(v, ev, rect, gd)
            | None => ()
            }
          }
        }
      | _ => ()
      }

      let _ = Window.requestAnimationFrame(updateFollowLoop)
    }
  }
}
