/* src/systems/HotspotLineLogic.res */
open ReBindings
open HotspotLineTypes

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

let getScreenCoords = (viewer, pitch, yaw, rect: Dom.rect) => {
  if !isViewerReady(viewer) {
    None
  } else {
    let camYaw = Viewer.getYaw(viewer)
    let hfov = Viewer.getHfov(viewer)

    let diff = ref(yaw -. camYaw)
    while diff.contents > 180.0 {
      diff := diff.contents -. 360.0
    }
    while diff.contents < -180.0 {
      diff := diff.contents +. 360.0
    }

    let toRad = deg => deg *. Math.Constants.pi /. 180.0
    let hfovRad = hfov->toRad
    let camPitch = Viewer.getPitch(viewer)
    let aspectRatio = rect.width /. rect.height
    let vfovRad = 2.0 *. Math.atan(Math.tan(hfovRad /. 2.0) /. aspectRatio)

    let yawRad = diff.contents->toRad
    let pitchRad = (pitch -. camPitch)->toRad

    let cosYaw = Math.cos(yawRad)

    if cosYaw < 0.0 || hfov <= 0.0 {
      None
    } else {
      let halfHfovRad = hfovRad /. 2.0
      let halfVfovRad = vfovRad /. 2.0

      if halfHfovRad == 0.0 || halfVfovRad == 0.0 {
        None
      } else {
        let x = Math.tan(yawRad) /. Math.tan(halfHfovRad)
        let y = Math.tan(pitchRad) /. (Math.tan(halfVfovRad) *. cosYaw)

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
  viewer,
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
    let d = ref("")
    let first = ref(true)

    for i in 0 to len - 1 {
      switch Belt.Array.get(path, i) {
      | Some(p) =>
        switch getScreenCoords(viewer, p.pitch, p.yaw, rect) {
        | Some(coords) =>
          let prefix = if first.contents {
            first := false
            "M "
          } else {
            " L "
          }
          d :=
            d.contents ++
            prefix ++
            Float.toString(Math.round(coords.x *. 10.0) /. 10.0) ++
            " " ++
            Float.toString(Math.round(coords.y *. 10.0) /. 10.0)
        | None => ()
        }
      | None => ()
      }
    }

    if d.contents != "" {
      let pathEl = Svg.createElementNS(Svg.namespace, "path")
      Svg.setAttribute(pathEl, "d", d.contents)
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

let drawSimulationArrow = (
  viewer,
  startPitch,
  startYaw,
  endPitch,
  endYaw,
  progress,
  ~opacity=1.0,
  ~waypoints=[],
  ~colorOverride=?,
  (),
) => {
  if !isViewerReady(viewer) {
    ()
  } else {
    let svgOpt = Dom.getElementById("viewer-hotspot-lines")
    switch (Nullable.toOption(svgOpt), viewer) {
    | (Some(svg), v) =>
      let rect = Dom.getBoundingClientRect(svg)

      if rect.width <= 0.0 || rect.height <= 0.0 {
        ()
      } else {
        let path = if Array.length(waypoints) > 0 {
          let startPt: array<PathInterpolation.point> = [
            {PathInterpolation.yaw: startYaw, pitch: startPitch},
          ]
          let endPt: array<PathInterpolation.point> = [
            {PathInterpolation.yaw: endYaw, pitch: endPitch},
          ]
          let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
          PathInterpolation.getCatmullRomSpline(controlPoints, 100)
        } else {
          PathInterpolation.getFloorProjectedPath(
            {yaw: startYaw, pitch: startPitch},
            {yaw: endYaw, pitch: endPitch},
            100,
          )
        }

        let totalDistance = ref(0.0)
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
              totalDistance := totalDistance.contents +. dist
            | _ => ()
            }
          }
        }

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

        let rotationProgressThreshold = 0.80
        let lookbackAmt = 0.15

        let progRotation = if progress >= rotationProgressThreshold {
          rotationProgressThreshold
        } else {
          progress
        }

        let progCurrent = Math.min(progRotation, 1.0)
        let progStable = Math.max(0.0, progCurrent -. lookbackAmt)

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

        let (yC, pC) = getPointAtProgress(progCurrent)
        let (yS, pS) = getPointAtProgress(progStable)

        let dy = ref(yC -. yS)
        while dy.contents > 180.0 {
          dy := dy.contents -. 360.0
        }
        while dy.contents < -180.0 {
          dy := dy.contents +. 360.0
        }

        rotYaw := dy.contents
        rotPitch := pC -. pS

        // 2. Calculate Position (Actual)
        let targetDist = progress *. totalDistance.contents
        let covered = ref(0.0)
        let found = ref(false)

        if progress >= 1.0 {
          // Snap to end
          targetPitch := endPitch
          targetYaw := endYaw
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

        let startCoordsOpt = getScreenCoords(v, targetPitch.contents, targetYaw.contents, rect)
        switch startCoordsOpt {
        | Some(s) =>
          let lookAhead = 0.5
          let endCoordsOpt = getScreenCoords(
            v,
            targetPitch.contents +. rotPitch.contents *. lookAhead,
            targetYaw.contents +. rotYaw.contents *. lookAhead,
            rect,
          )

          switch endCoordsOpt {
          | Some(e) =>
            let angle = Math.atan2(~y=e.y -. s.y, ~x=e.x -. s.x) *. (180.0 /. Math.Constants.pi)

            let color = if progress >= 0.99 {
              "#dc2626" // Red 600
            } else {
              switch colorOverride {
              | Some(c) => c
              | None =>
                if mod(Belt.Float.toInt(Date.now() /. 200.0), 2) == 0 {
                  "#fdba74" // Orange 300 (Brighter premium orange)
                } else {
                  "var(--orange-brand)" // Orange
                }
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
    | _ => ()
    }
  }
}
