/* src/systems/HotspotLineLogic.res */

open ReBindings
open Types

// --- TYPES ---

type customViewerProps = {@as("_sceneId") sceneId: string}

// Cache for path segments to avoid heavy re-calculation (O(N) * 60fps)
type segmentData = (
  float,
  array<(float, float, float, PathInterpolation.point, PathInterpolation.point)>,
)

// --- UTILS & STATE ---

module Utils = {
  let lastFrameIds = ref(Belt.MutableSet.String.make())
  let pathCache: JSWeakMap.t<Types.hotspot, array<PathInterpolation.point>> = JSWeakMap.make()
  let segmentCache: JSWeakMap.t<array<PathInterpolation.point>, segmentData> = JSWeakMap.make()

  let getCachedSplinePath = (h: Types.hotspot, controlPoints, segments) => {
    switch Nullable.toOption(JSWeakMap.get(pathCache, h)) {
    | Some(p) => p
    | None =>
      let p = if Constants.useBSplineSmoothing {
        PathInterpolation.getBSplinePath(controlPoints, segments)
      } else {
        PathInterpolation.getCatmullRomSpline(controlPoints, segments)
      }
      JSWeakMap.set(pathCache, h, p)
      p
    }
  }

  let getCachedFloorPath = (h: Types.hotspot, startPt, endPt, segments) => {
    switch Nullable.toOption(JSWeakMap.get(pathCache, h)) {
    | Some(p) => p
    | None =>
      let p = PathInterpolation.getFloorProjectedPath(startPt, endPt, segments)
      JSWeakMap.set(pathCache, h, p)
      p
    }
  }
}

// --- INTERNAL LOGIC ---

module Logic = {
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

  let renderPathSegment = (
    _h: Types.hotspot,
    id,
    points,
    color,
    width,
    opacity,
    ~dashArray=?,
    ~className=?,
    (),
  ) => {
    SvgManager.Renderer.drawPolyLine(
      id,
      points,
      color,
      width,
      opacity,
      ~dashArray?,
      ~className?,
      (),
    )
  }

  let updateArrow = (id, s: screenCoords, angle, color, opacity) => {
    if Float.isFinite(s.x) && Float.isFinite(s.y) && Float.isFinite(angle) {
      if opacity > 0.01 {
        SvgManager.Renderer.drawArrow(id, s.x, s.y, angle, color, opacity)
      } else {
        SvgManager.Renderer.hide(id)
      }
    } else {
      SvgManager.Renderer.hide(id)
    }
  }

  let calculatePointAtProgress = (
    progress,
    totalDistance,
    segments: array<(float, float, float, PathInterpolation.point, PathInterpolation.point)>,
    startYaw,
    startPitch,
    endYaw,
    endPitch,
  ) => {
    let tDist = progress *. totalDistance
    let cov = ref(0.0)
    let ptYaw = ref(startYaw)
    let ptPitch = ref(startPitch)
    let fnd = ref(false)

    for i in 0 to Array.length(segments) - 1 {
      if !fnd.contents {
        switch Belt.Array.get(segments, i) {
        | Some((dist, dy, dp, p1, _)) =>
          if tDist <= cov.contents +. dist {
            let sp = if dist > 0.0 {
              (tDist -. cov.contents) /. dist
            } else {
              0.0
            }
            ptPitch := p1.pitch +. dp *. sp
            ptYaw := p1.yaw +. dy *. sp
            fnd := true
          }
          cov := cov.contents +. dist
        | None => ()
        }
      }
    }
    if !fnd.contents {
      ptPitch := endPitch
      ptYaw := endYaw
    }
    (ptYaw.contents, ptPitch.contents)
  }

  let updateSimulationArrow = (
    cam: ProjectionMath.camState,
    startPitch,
    startYaw,
    endPitch,
    endYaw,
    progress,
    rect,
    ~opacity=1.0,
    ~waypoints=[],
    ~colorOverride=?,
    ~preComputedSegments=?,
    ~preComputedTotalDistance=?,
    ~id="sim_arrow",
    (),
  ) => {
    let (totalDist, segments) = switch (preComputedTotalDistance, preComputedSegments) {
    | (Some(td), Some(segs)) => (td, segs)
    | _ =>
      let path = if Array.length(waypoints) > 0 {
        let startPt: array<PathInterpolation.point> = [
          {PathInterpolation.yaw: startYaw, pitch: startPitch},
        ]
        let endPt: array<PathInterpolation.point> = [
          {PathInterpolation.yaw: endYaw, pitch: endPitch},
        ]
        let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
        if Constants.useBSplineSmoothing {
          PathInterpolation.getBSplinePath(controlPoints, 40)
        } else {
          PathInterpolation.getCatmullRomSpline(controlPoints, 40)
        }
      } else {
        PathInterpolation.getFloorProjectedPath(
          {yaw: startYaw, pitch: startPitch},
          {yaw: endYaw, pitch: endPitch},
          40,
        )
      }

      switch Nullable.toOption(JSWeakMap.get(Utils.segmentCache, path)) {
      | Some(cached) => cached
      | None =>
        let totalDist = ref(0.0)
        let segments = []
        if Array.length(path) >= 2 {
          for i in 0 to Array.length(path) - 2 {
            switch (Belt.Array.get(path, i), Belt.Array.get(path, i + 1)) {
            | (Some(p1), Some(p2)) =>
              let yawDiff = ref(p2.yaw -. p1.yaw)
              while yawDiff.contents > 180.0 {
                yawDiff := yawDiff.contents -. 360.0
              }
              while yawDiff.contents < -180.0 {
                yawDiff := yawDiff.contents +. 360.0
              }
              let pitchDiff = p2.pitch -. p1.pitch
              let dist = Math.sqrt(yawDiff.contents *. yawDiff.contents +. pitchDiff *. pitchDiff)
              let segment = (dist, yawDiff.contents, pitchDiff, p1, p2)
              let _ = Array.push(segments, segment)
              totalDist := totalDist.contents +. dist
            | _ => ()
            }
          }
        }
        let res = (totalDist.contents, segments)
        JSWeakMap.set(Utils.segmentCache, path, res)
        res
      }
    }

    let totalDistanceRef = {contents: totalDist}
    let targetPitch = ref(startPitch)
    let targetYaw = ref(startYaw)
    let rotYaw = ref(0.0)
    let rotPitch = ref(0.0)

    let rotationCalcProgress = Math.min(progress, 0.90)
    let delta = 0.02
    let progFront = Math.min(rotationCalcProgress +. delta, 1.0)
    let progBack = Math.max(0.0, rotationCalcProgress -. delta)

    let (yF, pF) = calculatePointAtProgress(
      progFront,
      totalDistanceRef.contents,
      segments,
      startYaw,
      startPitch,
      endYaw,
      endPitch,
    )
    let (yB, pB) = calculatePointAtProgress(
      progBack,
      totalDistanceRef.contents,
      segments,
      startYaw,
      startPitch,
      endYaw,
      endPitch,
    )

    let dy = ref(yF -. yB)
    while dy.contents > 180.0 {
      dy := dy.contents -. 360.0
    }
    while dy.contents < -180.0 {
      dy := dy.contents +. 360.0
    }
    rotYaw := dy.contents
    rotPitch := pF -. pB

    let targetDist = progress *. totalDistanceRef.contents
    let covered = ref(0.0)
    let found = ref(false)

    if progress >= 0.98 {
      targetPitch := endPitch
      targetYaw := endYaw
      found := true
    } else {
      for i in 0 to Array.length(segments) - 1 {
        if !found.contents {
          switch Belt.Array.get(segments, i) {
          | Some((dist, dy, dp, p1, _)) =>
            if targetDist <= covered.contents +. dist {
              let segProg = if dist > 0.0 {
                (targetDist -. covered.contents) /. dist
              } else {
                0.0
              }
              targetPitch := p1.pitch +. dp *. segProg
              targetYaw := p1.yaw +. dy *. segProg
              found := true
            }
            covered := covered.contents +. dist
          | None => ()
          }
        }
      }
    }
    if !found.contents {
      targetPitch := endPitch
      targetYaw := endYaw
    }

    switch ProjectionMath.getScreenCoords(cam, targetPitch.contents, targetYaw.contents, rect) {
    | Some(s) =>
      let endCoordsOpt = ProjectionMath.getScreenCoords(
        cam,
        targetPitch.contents +. rotPitch.contents *. 0.5,
        targetYaw.contents +. rotYaw.contents *. 0.5,
        rect,
      )
      switch endCoordsOpt {
      | Some(e) =>
        let angle = Math.atan2(~y=e.y -. s.y, ~x=e.x -. s.x) *. (180.0 /. Math.Constants.pi)
        let color = if progress >= 1.0 {
          if mod(Belt.Float.toInt(Date.now() /. 200.0), 2) == 0 {
            "#dc2626"
          } else {
            "var(--orange-brand)"
          }
        } else {
          switch colorOverride {
          | Some(c) => c
          | None => "var(--orange-brand)"
          }
        }
        SvgManager.Renderer.drawArrow(id, s.x, s.y, angle, color, opacity)
      | None => SvgManager.Renderer.hide(id)
      }
    | None => SvgManager.Renderer.hide(id)
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
            let splinePath = Utils.getCachedSplinePath(h, controlPoints, 40)
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
            let curvedPath = Utils.getCachedFloorPath(h, startPt, endPt, 40)
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

          if simulationStatus == Idle {
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
}
