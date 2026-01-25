/* src/systems/HotspotLineLogic.res */
open ReBindings
open HotspotLineTypes

let degToRad = Math.Constants.pi /. 180.0
let toRad = deg => deg *. degToRad

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

type camState = {
  yaw: float,
  pitch: float,
  hfov: float,
  aspectRatio: float,
  halfTanHfov: float,
  halfTanVfov: float,
  invHalfTanHfov: float,
  invHalfTanVfov: float,
}

let getCamState = (viewer, rect: Dom.rect) => {
  let yaw = Viewer.getYaw(viewer)
  let pitch = Viewer.getPitch(viewer)
  let hfov = Viewer.getHfov(viewer)
  let hfovRad = hfov *. degToRad
  let aspectRatio = rect.width /. rect.height
  let halfTanHfov = Math.tan(hfovRad /. 2.0)

  // vfov calculation: tan(vfov/2) = tan(hfov/2) / aspects
  let halfTanVfov = halfTanHfov /. aspectRatio

  let invHalfTanHfov = if halfTanHfov != 0.0 {
    1.0 /. halfTanHfov
  } else {
    0.0
  }

  let invHalfTanVfov = if halfTanVfov != 0.0 {
    1.0 /. halfTanVfov
  } else {
    0.0
  }

  {
    yaw,
    pitch,
    hfov,
    aspectRatio,
    halfTanHfov,
    halfTanVfov,
    invHalfTanHfov,
    invHalfTanVfov,
  }
}

let getScreenCoords = (cam: camState, pitch, yaw, rect: Dom.rect) => {
  let diff = ref(yaw -. cam.yaw)
  while diff.contents > 180.0 {
    diff := diff.contents -. 360.0
  }
  while diff.contents < -180.0 {
    diff := diff.contents +. 360.0
  }

  let yawRad = diff.contents *. degToRad
  let pitchRad = (pitch -. cam.pitch) *. degToRad

  let cosYaw = Math.cos(yawRad)

  if cosYaw <= 0.0 || cam.hfov <= 0.0 {
    None
  } else {
    let x = Math.tan(yawRad) *. cam.invHalfTanHfov
    let y = Math.tan(pitchRad) *. (cam.invHalfTanVfov /. cosYaw)

    if !Float.isFinite(x) || !Float.isFinite(y) {
      None
    } else {
      let screenX = rect.width /. 2.0 *. (1.0 +. x)
      let screenY = rect.height /. 2.0 *. (1.0 -. y)

      Some(
        (
          {
            x: screenX,
            y: screenY,
          }: screenCoords
        ),
      )
    }
  }
}

let drawLine = (svg, x1, y1, x2, y2, color, width, opacity, ~dashArray=?, ~className=?, ()) => {
  let line = Svg.createElementNS(Svg.namespace, "line")
  Svg.setAttribute(line, "x1", Float.toString(x1))
  Svg.setAttribute(line, "y1", Float.toString(y1))
  Svg.setAttribute(line, "x2", Float.toString(x2))
  Svg.setAttribute(line, "y2", Float.toString(y2))
  Svg.setAttribute(line, "stroke", color)
  Svg.setAttribute(line, "stroke-width", Float.toString(width))
  Svg.setAttribute(line, "stroke-opacity", Float.toString(opacity))

  switch dashArray {
  | Some(d) => Svg.setAttribute(line, "stroke-dasharray", d)
  | None => ()
  }

  switch className {
  | Some(c) => Svg.setAttribute(line, "class", c)
  | None => ()
  }

  Svg.appendChild(svg, line)
}

let drawPolyLine = (
  svg,
  cam: camState,
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
    let pathCommands = []
    let first = ref(true)

    for i in 0 to len - 1 {
      switch Belt.Array.get(path, i) {
      | Some(p) =>
        switch getScreenCoords(cam, p.pitch, p.yaw, rect) {
        | Some(coords) =>
          let prefix = if first.contents {
            first := false
            "M"
          } else {
            "L"
          }
          let _ = Array.push(pathCommands, prefix)
          let _ = Array.push(pathCommands, Float.toString(Math.round(coords.x *. 10.0) /. 10.0))
          let _ = Array.push(pathCommands, Float.toString(Math.round(coords.y *. 10.0) /. 10.0))
        | None => ()
        }
      | None => ()
      }
    }

    let dString = Array.join(pathCommands, " ")

    if dString != "" {
      let pathEl = Svg.createElementNS(Svg.namespace, "path")
      Svg.setAttribute(pathEl, "d", dString)
      Svg.setAttribute(pathEl, "stroke", color)
      Svg.setAttribute(pathEl, "stroke-width", Float.toString(width))
      Svg.setAttribute(pathEl, "stroke-opacity", Float.toString(opacity))
      Svg.setAttribute(pathEl, "fill", "none")
      Svg.setAttribute(pathEl, "stroke-linecap", "round")
      Svg.setAttribute(pathEl, "stroke-linejoin", "round")

      switch dashArray {
      | Some(da) => Svg.setAttribute(pathEl, "stroke-dasharray", da)
      | None => ()
      }

      switch className {
      | Some(c) => Svg.setAttribute(pathEl, "class", c)
      | None => ()
      }

      Svg.appendChild(svg, pathEl)
    }
  }
}

// Cache for path segments to avoid heavy re-calculation (O(N) * 60fps)
type segmentData = (
  float,
  array<(float, float, float, PathInterpolation.point, PathInterpolation.point)>,
)
let segmentCache: JSWeakMap.t<array<PathInterpolation.point>, segmentData> = JSWeakMap.make()

let drawSimulationArrow = (
  svg,
  cam: camState,
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
  (),
) => {
  let (totalDist, segments) = switch (preComputedTotalDistance, preComputedSegments) {
  | (Some(td), Some(segs)) => (td, segs)
  | _ =>
    let path = if Array.length(waypoints) > 0 {
      let startPt: array<PathInterpolation.point> = [
        {PathInterpolation.yaw: startYaw, pitch: startPitch},
      ]
      let endPt: array<PathInterpolation.point> = [{PathInterpolation.yaw: endYaw, pitch: endPitch}]
      let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
      PathInterpolation.getCatmullRomSpline(controlPoints, 40)
    } else {
      PathInterpolation.getFloorProjectedPath(
        {yaw: startYaw, pitch: startPitch},
        {yaw: endYaw, pitch: endPitch},
        40,
      )
    }

    switch Nullable.toOption(JSWeakMap.get(segmentCache, path)) {
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
      JSWeakMap.set(segmentCache, path, res)
      res
    }
  }

  let totalDistance = {contents: totalDist}

  let targetPitch = ref(startPitch)
  let targetYaw = ref(startYaw)
  let rotYaw = ref(0.0)
  let rotPitch = ref(0.0)

  // STABILITY FIX: Always calculate rotation based on a point slightly before the end.
  // This avoids "micro-curls" at the very end of the spline and ensures the arrow
  // points in the direction of arrival.

  // STABILITY FIX: Freeze rotation during the final 20% of the journey.
  // This ensures the arrow maintains its stable arrival trajectory and ignores
  // any micro-turns or spline artifacts right at the end of the waypoint.

  // ACCURACY FIX: Use a tighter, centered window for rotation.
  // Instead of looking strictly back, we look slightly ahead and behind (Central Difference).
  // This keeps the arrow tangent much tighter to the curve during turns.

  // STABILITY FIX: We FREEZE the rotation calculation point once we get very close to the end.
  // If we let 'progress' go all the way to 1.0, the 'progFront' calculation can hit the end of the spline
  // and cause a singularity or flip. By clamping the rotation-calculation-progress to 0.90,
  // we ensure the arrow effectively "coasts" into the dock with its final valid heading.
  let rotationCalcProgress = Math.min(progress, 0.90)

  let delta = 0.02
  let progFront = Math.min(rotationCalcProgress +. delta, 1.0)
  let progBack = Math.max(0.0, rotationCalcProgress -. delta)

  // Helper to get point at progress
  let getPointAtProgress = p => {
    let tDist = p *. totalDistance.contents
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
      // If not found (e.g. 1.0), use end
      ptPitch := endPitch
      ptYaw := endYaw
    }
    (ptYaw.contents, ptPitch.contents)
  }

  let (yF, pF) = getPointAtProgress(progFront)
  let (yB, pB) = getPointAtProgress(progBack)

  let dy = ref(yF -. yB)
  while dy.contents > 180.0 {
    dy := dy.contents -. 360.0
  }
  while dy.contents < -180.0 {
    dy := dy.contents +. 360.0
  }

  rotYaw := dy.contents
  rotPitch := pF -. pB

  // 2. Calculate Position (Actual)
  let targetDist = progress *. totalDistance.contents
  let covered = ref(0.0)
  let found = ref(false)

  if progress >= 0.98 {
    // RECOIL GUARD: In the final arrival window, we force snapping to the exact end point.
    // This prevents the arrow from following Catmull-Rom "overshoots" or "swings"
    // that can happen right at the final control point.
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

  let startCoordsOpt = getScreenCoords(cam, targetPitch.contents, targetYaw.contents, rect)
  switch startCoordsOpt {
  | Some(s) =>
    let endCoordsOpt = getScreenCoords(
      cam,
      targetPitch.contents +. rotPitch.contents *. 0.5,
      targetYaw.contents +. rotYaw.contents *. 0.5,
      rect,
    )

    switch endCoordsOpt {
    | Some(e) =>
      let angle = Math.atan2(~y=e.y -. s.y, ~x=e.x -. s.x) *. (180.0 /. Math.Constants.pi)

      let color = if progress >= 1.0 {
        // Blink phase (Arrival - Red Pulse)
        if mod(Belt.Float.toInt(Date.now() /. 200.0), 2) == 0 {
          "#dc2626" // Red 600
        } else {
          "var(--orange-brand)" // Orange
        }
      } else {
        // Journey phase (Solid Orange)
        switch colorOverride {
        | Some(c) => c
        | None => "var(--orange-brand)"
        }
      }

      if Float.isFinite(s.x) && Float.isFinite(s.y) && Float.isFinite(angle) {
        let arrow = Svg.createElementNS(Svg.namespace, "path")
        Svg.setAttribute(arrow, "d", "M -10,-7 L 6,0 L -10,7 Z")
        Svg.setAttribute(arrow, "fill", color)
        Svg.setAttribute(arrow, "stroke", "#000")
        Svg.setAttribute(arrow, "stroke-width", "1")
        Svg.setAttribute(
          arrow,
          "transform",
          "translate(" ++
          Float.toString(s.x) ++
          ", " ++
          Float.toString(s.y) ++
          ") rotate(" ++
          Float.toString(angle) ++ ")",
        )

        if opacity < 1.0 {
          Svg.setAttribute(arrow, "opacity", Float.toString(opacity))
        }

        Svg.appendChild(svg, arrow)
      }
    | None => ()
    }
  | None => ()
  }
}
