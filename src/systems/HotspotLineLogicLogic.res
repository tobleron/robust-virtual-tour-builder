/* src/systems/HotspotLineLogicLogic.res */
open ReBindings

let isViewerValid = (viewer: Viewer.t): bool => {
  let loaded = Viewer.isLoaded(viewer)
  if !loaded {
    false
  } else {
    let hfov = Viewer.getHfov(viewer)
    let yaw = Viewer.getYaw(viewer)
    let pitch = Viewer.getPitch(viewer)
    hfov > 0.0 && Float.isFinite(hfov) && Float.isFinite(yaw) && Float.isFinite(pitch)
  }
}

let isActiveViewer = (viewer: Viewer.t): bool => {
  let activeViewer = ViewerState.getActiveViewer()
  switch Nullable.toOption(activeViewer) {
  | Some(active) => active === viewer
  | None => false
  }
}

let isViewerReady = (viewer: Viewer.t): bool => {
  if !isViewerValid(viewer) {
    false
  } else if !isActiveViewer(viewer) {
    false
  } else {
    Viewer.getHfov(viewer) > 1.0
  }
}

let getCamState = (viewer, rect: Dom.rect) => {
  let yaw = Viewer.getYaw(viewer)
  let pitch = Viewer.getPitch(viewer)
  let hfov = Viewer.getHfov(viewer)
  ProjectionMath.makeCamState(yaw, pitch, hfov, rect)
}

let updatePolyLine = (
  id,
  cam: ProjectionMath.camState,
  path: array<PathInterpolation.point>,
  rect,
  color,
  width,
  opacity,
  ~dashArray=?,
  ~className=?,
  (),
) => {
  let len = Array.length(path)
  if len >= 2 {
    let screenPoints = []

    for i in 0 to len - 1 {
      switch Belt.Array.get(path, i) {
      | Some(p) =>
        switch ProjectionMath.getScreenCoords(cam, p.pitch, p.yaw, rect) {
        | Some(coords) =>
          let _ = Array.push(screenPoints, coords)
        | None => ()
        }
      | None => ()
      }
    }

    if Array.length(screenPoints) > 0 {
      SvgRenderer.drawPolyLine(
        id,
        screenPoints,
        color,
        width,
        opacity,
        ~dashArray?,
        ~className?,
        (),
      )
    } else {
      SvgRenderer.hide(id)
    }
  } else {
    SvgRenderer.hide(id)
  }
}

let drawPersistentLines = (
  cam,
  rect,
  hotspots: array<Types.hotspot>,
  currentFrameIds,
  simulationStatus: Types.simulationStatus,
) => {
  for i in 0 to Array.length(hotspots) - 1 {
    switch Belt.Array.get(hotspots, i) {
    | Some(h) =>
      switch (h.startYaw, h.startPitch, h.viewFrame) {
      | (Some(sy), Some(sp), Some(vf)) =>
        let id = "hl_" ++ h.linkId
        Belt.MutableSet.String.add(currentFrameIds, id)

        let waypointsRaw = switch h.waypoints {
        | Some(w) => w
        | None => []
        }
        let waypoints: array<PathInterpolation.point> = Belt.Array.map(waypointsRaw, w => {
          PathInterpolation.yaw: w.yaw,
          pitch: w.pitch,
        })

        if Array.length(waypoints) > 0 {
          let startPt: array<PathInterpolation.point> = [{PathInterpolation.yaw: sy, pitch: sp}]
          let endPt: array<PathInterpolation.point> = [
            {PathInterpolation.yaw: vf.yaw, pitch: vf.pitch},
          ]
          let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
          let splinePath = HotspotLineUtils.getCachedSplinePath(h, controlPoints, 40)
          updatePolyLine(
            id,
            cam,
            splinePath,
            rect,
            "var(--danger-light)",
            3.0,
            0.8,
            ~className="line-marching-ants",
            (),
          )
        } else {
          let startPt: PathInterpolation.point = {PathInterpolation.yaw: sy, pitch: sp}
          let endPt: PathInterpolation.point = {
            PathInterpolation.yaw: vf.yaw,
            pitch: vf.pitch,
          }
          let curvedPath = HotspotLineUtils.getCachedFloorPath(h, startPt, endPt, 40)
          updatePolyLine(
            id,
            cam,
            curvedPath,
            rect,
            "var(--danger-light)",
            3.0,
            0.8,
            ~className="line-marching-ants",
            (),
          )
        }

        // Arrow
        if simulationStatus == Idle {
          let arrowId = "arrow_" ++ h.linkId
          Belt.MutableSet.String.add(currentFrameIds, arrowId)
          HotspotLineLogicArrow.updateSimulationArrow(
            cam,
            sp,
            sy,
            vf.pitch,
            vf.yaw,
            0.0,
            rect,
            ~opacity=0.9,
            ~waypoints,
            ~colorOverride="var(--orange-brand)",
            ~id=arrowId,
            (),
          )
        }
      | _ => ()
      }
    | None => ()
    }
  }
}

let drawLinkingDraft = (
  viewer,
  cam: ProjectionMath.camState,
  rect,
  draft: Types.linkDraft,
  mouseEvent,
  currentFrameIds,
) => {
  let camStart: PathInterpolation.point = {
    PathInterpolation.yaw: draft.camYaw,
    pitch: draft.camPitch,
  }

  let intermediate = switch draft.intermediatePoints {
  | Some(pts) => pts
  | None => []
  }

  let currentCam: PathInterpolation.point = {
    PathInterpolation.yaw: cam.yaw,
    pitch: cam.pitch,
  }
  let redPoints = Belt.Array.concat(
    [camStart],
    Belt.Array.map(intermediate, (p): PathInterpolation.point => {
      PathInterpolation.yaw: p.camYaw,
      pitch: p.camPitch,
    }),
  )
  let allRedPoints = Belt.Array.concat(redPoints, [currentCam])

  let draftId = "link_draft_red"
  Belt.MutableSet.String.add(currentFrameIds, draftId)

  if Array.length(allRedPoints) == 2 {
    switch (Belt.Array.get(allRedPoints, 0), Belt.Array.get(allRedPoints, 1)) {
    | (Some(p1), Some(p2)) =>
      let path = PathInterpolation.getFloorProjectedPath(p1, p2, 40)
      updatePolyLine(
        draftId,
        cam,
        path,
        rect,
        "var(--danger-light)",
        3.0,
        1.0,
        ~className="line-marching-ants",
        (),
      )
    | _ => ()
    }
  } else if Array.length(allRedPoints) > 2 {
    let redSpline = if Constants.useBSplineSmoothing {
      PathInterpolation.getBSplinePath(allRedPoints, 40)
    } else {
      PathInterpolation.getCatmullRomSpline(allRedPoints, 40)
    }
    updatePolyLine(
      draftId,
      cam,
      redSpline,
      rect,
      "var(--danger-light)",
      3.0,
      1.0,
      ~className="line-marching-ants",
      (),
    )
  }

  let floorPoints: array<PathInterpolation.point> = Belt.Array.concat(
    [{PathInterpolation.yaw: draft.yaw, pitch: draft.pitch}],
    Belt.Array.map(intermediate, (p): PathInterpolation.point => {
      PathInterpolation.yaw: p.yaw,
      pitch: p.pitch,
    }),
  )

  let mousePtOpt = switch mouseEvent {
  | Some(ev) =>
    let mockEvent = {
      "clientX": Belt.Int.toFloat(Dom.clientX(ev)),
      "clientY": Belt.Int.toFloat(Dom.clientY(ev)) +. Constants.linkingRodHeight,
    }
    let mc = Viewer.mouseEventToCoords(viewer, mockEvent)
    let pitchOpt = Belt.Array.get(mc, 0)
    let yawOpt = Belt.Array.get(mc, 1)
    switch (pitchOpt, yawOpt) {
    | (Some(p), Some(y)) => Some({PathInterpolation.yaw: y, pitch: p})
    | _ => None
    }
  | None => None
  }

  let allYellowPoints = switch mousePtOpt {
  | Some(m) => Belt.Array.concat(floorPoints, [m])
  | None => floorPoints
  }

  let yellowId = "link_draft_yellow"
  Belt.MutableSet.String.add(currentFrameIds, yellowId)

  if Array.length(allYellowPoints) == 2 {
    switch (Belt.Array.get(allYellowPoints, 0), Belt.Array.get(allYellowPoints, 1)) {
    | (Some(p1), Some(p2)) =>
      let path = PathInterpolation.getFloorProjectedPath(p1, p2, 40)
      updatePolyLine(
        yellowId,
        cam,
        path,
        rect,
        "var(--warning-light)",
        3.0,
        0.8,
        ~className="line-rod-yellow",
        (),
      )
    | _ => ()
    }
  } else if Array.length(allYellowPoints) > 2 {
    let yellowSpline = PathInterpolation.getCatmullRomSpline(allYellowPoints, 40)
    updatePolyLine(
      yellowId,
      cam,
      yellowSpline,
      rect,
      "var(--warning-light)",
      3.0,
      0.8,
      ~className="line-rod-yellow",
      (),
    )
  }
}
