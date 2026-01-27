/* src/systems/HotspotLineLogicArrow.res */
open ReBindings
open HotspotLineLogicTypes

let segmentCache: JSWeakMap.t<array<PathInterpolation.point>, segmentData> = JSWeakMap.make()

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
      let endPt: array<PathInterpolation.point> = [{PathInterpolation.yaw: endYaw, pitch: endPitch}]
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
    // RECOIL GUARD
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

  let startCoordsOpt = ProjectionMath.getScreenCoords(
    cam,
    targetPitch.contents,
    targetYaw.contents,
    rect,
  )
  switch startCoordsOpt {
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

      SvgRenderer.drawArrow(id, s.x, s.y, angle, color, opacity)

    | None => SvgRenderer.hide(id)
    }
  | None => SvgRenderer.hide(id)
  }
}
