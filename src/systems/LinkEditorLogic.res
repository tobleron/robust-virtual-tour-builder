/* src/systems/LinkEditorLogic.res */

open ReBindings
open ViewerState
open Types

let handleStageClick = (e: Dom.event) => {
  let currentState = GlobalStateBridge.getState()

  if currentState.isLinking && currentState.simulation.status != Running {
    let viewer = getActiveViewer()

    switch Nullable.toOption(viewer) {
    | Some(v) =>
      // Offset click by linkingRodHeight to match visual tip (v4.2.18 behavior)
      let mockEvent = {
        "clientX": Belt.Int.toFloat(Dom.clientX(e)),
        "clientY": Belt.Int.toFloat(Dom.clientY(e)) +. Constants.linkingRodHeight,
      }
      let coords = Viewer.mouseEventToCoords(v, mockEvent)
      let pitchOpt = Belt.Array.get(coords, 0)
      let yawOpt = Belt.Array.get(coords, 1)

      switch (pitchOpt, yawOpt) {
      | (Some(pitch), Some(yaw)) =>
        Logger.debug(
          ~module_="LinkEditorLogic",
          ~message="STAGE_CLICK_LINKING",
          ~data=Some({"pitch": pitch, "yaw": yaw}),
          (),
        )

        let draft = currentState.linkDraft

        switch draft {
        | None =>
          let hfov = Viewer.getHfov(v)
          let camPitch = Viewer.getPitch(v)
          let camYaw = Viewer.getYaw(v)

          let initialDraft = {
            yaw,
            pitch,
            camYaw,
            camPitch,
            camHfov: hfov,
            intermediatePoints: None,
          }

          GlobalStateBridge.dispatch(Actions.StartLinking(Some(initialDraft)))

          // Force update lines immediately for the very first click
          let mockState = {...currentState, linkDraft: Some(initialDraft)}
          HotspotLine.updateLines(v, mockState, ~mouseEvent=e, ())

        | Some(d) =>
          let currentPoints = switch d.intermediatePoints {
          | Some(pts) => pts
          | None => []
          }
          let camPitch = Viewer.getPitch(v)
          let camYaw = Viewer.getYaw(v)
          let camHfov = Viewer.getHfov(v)

          let newPoint: Types.linkDraft = {
            yaw,
            pitch,
            camYaw,
            camPitch,
            camHfov,
            intermediatePoints: None,
          }

          let newPoints = Belt.Array.concat(currentPoints, [newPoint])

          let updatedDraft = {...d, intermediatePoints: Some(newPoints)}
          GlobalStateBridge.dispatch(Actions.UpdateLinkDraft(updatedDraft))

          // Force update lines immediately
          let mockState = {...currentState, linkDraft: Some(updatedDraft)}
          HotspotLine.updateLines(v, mockState, ~mouseEvent=e, ())
        }
      | _ => Logger.warn(~module_="LinkEditorLogic", ~message="STAGE_CLICK_INVALID_COORDS", ())
      }
    | None => Logger.warn(~module_="LinkEditorLogic", ~message="NO_ACTIVE_VIEWER", ())
    }
    true->ignore
  } else {
    false->ignore
  }
}

let handleStagePointerDown = (e: Dom.event) => {
  let currentState = GlobalStateBridge.getState()
  if currentState.isLinking && currentState.simulation.status != Running {
    Logger.debug(
      ~module_="LinkEditorLogic",
      ~message="POINTER_DOWN_CAPTURE",
      ~data=Some({"action": "stopPropagation"}),
      (),
    )
    Dom.stopPropagation(e)
  }
}

let handleEnter = () => {
  let currentState = GlobalStateBridge.getState()

  if currentState.isLinking && currentState.simulation.status != Running {
    let viewer = getActiveViewer()

    switch (Nullable.toOption(viewer), currentState.linkDraft) {
    | (Some(v), Some(d)) =>
      let camPitch = Viewer.getPitch(v)
      let camYaw = Viewer.getYaw(v)
      let camHfov = Viewer.getHfov(v)

      LinkModal.showLinkModal(
        ~pitch=d.pitch,
        ~yaw=d.yaw,
        ~camPitch,
        ~camYaw,
        ~camHfov,
        ~linkDraft=Nullable.make(d),
        (),
      )
    | _ =>
      // If no draft (no clicks yet), we could either ignore or use center.
      // Notification said "Enter to save", implying clicking first is required or center is used.
      // For now, let's notify if they try to save without any points.
      if currentState.linkDraft == None {
        EventBus.dispatch(ShowNotification("Add at least one point before saving.", #Warning))
      }
    }
  }
}
