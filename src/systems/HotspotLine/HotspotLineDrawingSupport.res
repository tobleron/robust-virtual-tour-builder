open ReBindings

open HotspotLineUtils
open HotspotLineLogicArrow

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
      SvgManager.Renderer.drawPolyLine(
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
      SvgManager.Renderer.hide(id)
    }
  } else {
    SvgManager.Renderer.hide(id)
  }
}

let drawSingleHotspotLine = (
  h: Types.hotspot,
  cam,
  rect,
  currentFrameIds,
  _simulationStatus: Types.simulationStatus,
) => {
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
      let endPt: array<PathInterpolation.point> = [{PathInterpolation.yaw: vf.yaw, pitch: vf.pitch}]
      let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
      let splinePath = getCachedSplinePath(h, controlPoints, 40)
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
      let endPt: PathInterpolation.point = {PathInterpolation.yaw: vf.yaw, pitch: vf.pitch}
      let curvedPath = getCachedFloorPath(h, startPt, endPt, 40)
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

    let arrowId = "arrow_" ++ h.linkId
    Belt.MutableSet.String.add(currentFrameIds, arrowId)
    updateSimulationArrow(
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
  | _ => ()
  }
}

let calculateMousePoint = (viewer, ev): option<PathInterpolation.point> => {
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
}

let drawDraftPolyline = (
  id,
  cam: ProjectionMath.camState,
  rect,
  points: array<PathInterpolation.point>,
  color,
  opacity,
  ~className,
) => {
  if Array.length(points) == 2 {
    switch (Belt.Array.get(points, 0), Belt.Array.get(points, 1)) {
    | (Some(p1), Some(p2)) =>
      let path = PathInterpolation.getFloorProjectedPath(p1, p2, 40)
      updatePolyLine(id, cam, path, rect, color, 3.0, opacity, ~className, ())
    | _ => ()
    }
  } else if Array.length(points) > 2 {
    let spline = PathInterpolation.getBSplinePath(points, 40)
    updatePolyLine(id, cam, spline, rect, color, 3.0, opacity, ~className, ())
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
  let currentCam: PathInterpolation.point = {PathInterpolation.yaw: cam.yaw, pitch: cam.pitch}
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
  drawDraftPolyline(
    draftId,
    cam,
    rect,
    allRedPoints,
    "var(--danger-light)",
    1.0,
    ~className="line-marching-ants",
  )

  let floorPoints: array<PathInterpolation.point> = Belt.Array.concat(
    [{PathInterpolation.yaw: draft.yaw, pitch: draft.pitch}],
    Belt.Array.map(intermediate, (p): PathInterpolation.point => {
      PathInterpolation.yaw: p.yaw,
      pitch: p.pitch,
    }),
  )
  let mousePtOpt = switch mouseEvent {
  | Some(ev) => calculateMousePoint(viewer, ev)
  | None => None
  }
  let allYellowPoints = switch mousePtOpt {
  | Some(m) => Belt.Array.concat(floorPoints, [m])
  | None => floorPoints
  }
  let yellowId = "link_draft_yellow"
  Belt.MutableSet.String.add(currentFrameIds, yellowId)
  drawDraftPolyline(
    yellowId,
    cam,
    rect,
    allYellowPoints,
    "var(--warning-light)",
    0.8,
    ~className="line-rod-yellow",
  )
}
