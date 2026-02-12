/* src/systems/LinkEditorLogic.res */

open ReBindings

open Types
open Actions

let getStateRef: ref<unit => state> = ref(AppContext.getBridgeState)
let dispatchRef: ref<unit => action => unit> = ref(AppContext.getBridgeDispatch)

let configure = (~getState: unit => state, ~dispatch: action => unit) => {
  getStateRef := getState
  dispatchRef := (() => dispatch)
}

let handleStageClick = (e: Dom.event) => {
  let currentState = getStateRef.contents()
  let isModifier = Dom.altKey(e) || Dom.metaKey(e)

  if (currentState.isLinking || isModifier) && currentState.simulation.status != Running {
    let viewer = ViewerSystem.getActiveViewer()

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

          if isModifier {
            dispatchRef.contents()(Actions.StartLinking(Some(initialDraft)))
            LinkModal.showLinkModal(
              ~pitch,
              ~yaw,
              ~camPitch,
              ~camYaw,
              ~camHfov=hfov,
              ~linkDraft=Nullable.make(initialDraft),
              ~getState=getStateRef.contents,
              ~dispatch=dispatchRef.contents(),
              (),
            )
          } else {
            dispatchRef.contents()(Actions.StartLinking(Some(initialDraft)))

            // Force update lines immediately for the very first click
            let mockState = {...currentState, linkDraft: Some(initialDraft)}
            HotspotLine.updateLines(v, mockState, ~mouseEvent=e, ())
          }

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
          dispatchRef.contents()(Actions.UpdateLinkDraft(updatedDraft))

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
  let currentState = getStateRef.contents()
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

let handleEnter = (~getState: unit => state=getStateRef.contents) => {
  let currentState = getState()

  if currentState.isLinking && currentState.simulation.status != Running {
    let viewer = ViewerSystem.getActiveViewer()

    switch (Nullable.toOption(viewer), currentState.linkDraft) {
    | (Some(v), Some(d)) =>
      let camPitch = Viewer.getPitch(v)
      let camYaw = Viewer.getYaw(v)
      let camHfov = Viewer.getHfov(v)

      // Use the LAST point in the draft as the hotspot position if available
      let (finalPitch, finalYaw) = switch d.intermediatePoints {
      | Some(points) =>
        let count = Belt.Array.length(points)
        if count > 0 {
          switch Belt.Array.get(points, count - 1) {
          | Some(lastPoint) => (lastPoint.pitch, lastPoint.yaw)
          | None => (d.pitch, d.yaw)
          }
        } else {
          (d.pitch, d.yaw)
        }
      | None => (d.pitch, d.yaw)
      }

      LinkModal.showLinkModal(
        ~pitch=finalPitch,
        ~yaw=finalYaw,
        ~camPitch,
        ~camYaw,
        ~camHfov,
        ~linkDraft=Nullable.make(d),
        ~getState=getStateRef.contents,
        ~dispatch=dispatchRef.contents(),
        (),
      )
    | _ =>
      // If no draft (no clicks yet), we could either ignore or use center.
      // Notification said "Enter to save", implying clicking first is required or center is used.
      // For now, let's notify if they try to save without any points.
      if currentState.linkDraft == None {
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: Operation("link_editor"),
          message: "Add at least one point before saving.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
    }
  }
}
