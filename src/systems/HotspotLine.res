/* src/systems/HotspotLine.res */

open ReBindings

/* --- TYPES --- */

type screenCoords = {x: float, y: float}

/* --- MATH HELPERS --- */

let getScreenCoords = (viewer, pitch, yaw, rect: Dom.rect) => {
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

      Some({
        x: rect.width /. 2.0 *. (1.0 +. x),
        y: rect.height /. 2.0 *. (1.0 -. y),
      })
    }
  }
}

/* --- SVG DRAWING --- */

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
    let prevPoint = ref(Belt.Array.get(path, 0))

    switch prevPoint.contents {
    | Some(startPt) =>
      let currentPrev = ref(startPt)
      for i in 1 to len - 1 {
        let currPointOpt = Belt.Array.get(path, i)
        switch currPointOpt {
        | Some(currPoint) =>
          let startCoords = getScreenCoords(
            viewer,
            currentPrev.contents.pitch,
            currentPrev.contents.yaw,
            rect,
          )
          let endCoords = getScreenCoords(viewer, currPoint.pitch, currPoint.yaw, rect)

          switch (startCoords, endCoords) {
          | (Some(s), Some(e)) =>
            // Skip very short segments
            if Math.abs(s.x -. e.x) >= 1.0 || Math.abs(s.y -. e.y) >= 1.0 {
              drawLine(svg, s.x, s.y, e.x, e.y, color, width, opacity, ~dashArray?, ~className?, ())
            }
          | _ => ()
          }
          currentPrev := currPoint
        | None => ()
        }
      }
    | None => ()
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
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch (Nullable.toOption(svgOpt), viewer) {
  | (Some(svg), v) =>
    let rect = Dom.getBoundingClientRect(svg)

    // 1. Path Generation
    let path = if Array.length(waypoints) > 0 {
      let startPt: array<PathInterpolation.point> = [
        {PathInterpolation.yaw: startYaw, pitch: startPitch},
      ]
      let endPt: array<PathInterpolation.point> = [{PathInterpolation.yaw: endYaw, pitch: endPitch}]
      let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
      PathInterpolation.getCatmullRomSpline(controlPoints, 100)
    } else {
      [
        {PathInterpolation.yaw: startYaw, pitch: startPitch},
        {PathInterpolation.yaw: endYaw, pitch: endPitch},
      ]
    }

    // 2. Distances
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
          let _ = Js.Array.push(segment, segments)
          totalDistance := totalDistance.contents +. dist
        | _ => ()
        }
      }
    }

    // 3. Current Pos & Rotation
    let targetPitch = ref(startPitch)
    let targetYaw = ref(startYaw)
    let rotYaw = ref(0.0)
    let rotPitch = ref(0.0)

    if progress >= 1.0 {
      targetPitch := endPitch
      targetYaw := endYaw
      if Array.length(segments) > 0 {
        switch Belt.Array.get(segments, Array.length(segments) - 1) {
        | Some((_, dy, dp, _, _)) =>
          rotYaw := dy
          rotPitch := dp
        | None => ()
        }
      }
    } else {
      let targetDist = progress *. totalDistance.contents
      let covered = ref(0.0)
      let found = ref(false)

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
              rotYaw := dy
              rotPitch := dp
              found := true
            }
            covered := covered.contents +. dist
          | None => ()
          }
        }
      }
    }

    // 4. Projection
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

        let color = switch colorOverride {
        | Some(c) => c
        | None =>
          if mod(Belt.Float.toInt(Date.now() /. 200.0), 2) == 0 {
            "#fbbf24"
          } else {
            "#10b981"
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
  | _ => ()
  }
}

let updateLines = (viewer, state: Types.state, ~mouseEvent: option<'a>=?, ()) => {
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch (Nullable.toOption(svgOpt), viewer) {
  | (Some(svg), v) =>
    // Clear SVG content using textContent which is more reliable for SVG
    Dom.setTextContent(svg, "")
    let rect = Dom.getBoundingClientRect(svg)

    if (
      rect.width > 0.0 && state.activeIndex >= 0 && state.activeIndex < Array.length(state.scenes)
    ) {
      switch Belt.Array.get(state.scenes, state.activeIndex) {
      | Some(currentScene) => {
          // 1. Persistent Red Dashed Lines
          let hotspots = currentScene.hotspots
          for i in 0 to Array.length(hotspots) - 1 {
            switch Belt.Array.get(hotspots, i) {
            | Some(h) =>
              switch (h.startYaw, h.startPitch, h.viewFrame) {
              | (Some(sy), Some(sp), Some(vf)) =>
                let waypointsRaw = switch h.waypoints {
                | Some(w) => w
                | None => []
                }
                let waypoints: array<PathInterpolation.point> = Belt.Array.map(waypointsRaw, w => {
                  PathInterpolation.yaw: w.yaw,
                  pitch: w.pitch,
                })

                if Array.length(waypoints) > 0 {
                  let startPt: array<PathInterpolation.point> = [
                    {PathInterpolation.yaw: sy, pitch: sp},
                  ]
                  let endPt: array<PathInterpolation.point> = [
                    {PathInterpolation.yaw: vf.yaw, pitch: vf.pitch},
                  ]
                  let controlPoints = Belt.Array.concat(
                    startPt,
                    Belt.Array.concat(waypoints, endPt),
                  )
                  let splinePath = PathInterpolation.getCatmullRomSpline(controlPoints, 60)
                  drawPolyLine(
                    svg,
                    v,
                    splinePath,
                    rect,
                    "#ef4444",
                    3.0,
                    0.8,
                    ~className="line-marching-ants",
                    (),
                  )
                } else {
                  let startCoords = getScreenCoords(v, sp, sy, rect)
                  let endCoords = getScreenCoords(v, vf.pitch, vf.yaw, rect)
                  switch (startCoords, endCoords) {
                  | (Some(s), Some(e)) =>
                    drawLine(
                      svg,
                      s.x,
                      s.y,
                      e.x,
                      e.y,
                      "#ef4444",
                      3.0,
                      0.8,
                      ~className="line-marching-ants",
                      (),
                    )
                  | _ => ()
                  }
                }
              | _ => ()
              }
            | None => ()
            }
          }

          // 2. Linking Mode
          if state.isLinking {
            switch state.linkDraft {
            | Some(draft) =>
              let currentCam: PathInterpolation.point = {
                PathInterpolation.yaw: Viewer.getYaw(v),
                pitch: Viewer.getPitch(v),
              }
              let camStart: PathInterpolation.point = {
                PathInterpolation.yaw: draft.camYaw,
                pitch: draft.camPitch,
              }

              let intermediate = switch draft.intermediatePoints {
              | Some(pts) => pts
              | None => []
              }

              // --- RED CRITICAL PATH (Camera Director Curve) ---
              // v4.2.0 point 55: Red dashed line appearing on first click
              let camPoints = Belt.Array.concat(
                [camStart],
                Belt.Array.concat(
                  Belt.Array.map(intermediate, (p): PathInterpolation.point => {
                    PathInterpolation.yaw: p.camYaw,
                    pitch: p.camPitch,
                  }),
                  [currentCam],
                ),
              )

              if Array.length(camPoints) >= 2 {
                let redSpline = PathInterpolation.getCatmullRomSpline(camPoints, 60)
                drawPolyLine(
                  svg,
                  v,
                  redSpline,
                  rect,
                  "#ef4444",
                  3.0,
                  1.0,
                  ~className="line-marching-ants",
                  (),
                )
              }

              // --- YELLOW TARGET PATH (The Rod) ---
              // v4.2.0 point 54: Dashed yellow line from last click to mouse
              let floorPoints: array<PathInterpolation.point> = Belt.Array.concat(
                [{PathInterpolation.yaw: draft.yaw, pitch: draft.pitch}],
                Belt.Array.map(intermediate, (p): PathInterpolation.point => {
                  PathInterpolation.yaw: p.yaw,
                  pitch: p.pitch,
                }),
              )

              // 1. Draw confirmed segments (Spline if multiple joints)
              if Array.length(floorPoints) >= 2 {
                let yellowSpline = PathInterpolation.getCatmullRomSpline(floorPoints, 60)
                drawPolyLine(
                  svg,
                  v,
                  yellowSpline,
                  rect,
                  "#fbbf24",
                  3.0,
                  0.8,
                  ~className="line-rod-yellow",
                  (),
                )
              }

              // 2. Draw pending segment (Floor Projection if looking down)
              // v4.2.18 behavior: connect last confirmed point to mouse
              // If no intermediate points, connect DRAFT ORIGIN (first "click" location) to mouse.

              let lastPoint = switch Belt.Array.get(floorPoints, Array.length(floorPoints) - 1) {
              | Some(p) => p
              // Fallback to draft origin if floorPoints empty (this happens when intermediatePoints is None)
              | None => {PathInterpolation.yaw: draft.yaw, pitch: draft.pitch}
              }

              let lastFloorPtOpt = Some(lastPoint)

              switch (lastFloorPtOpt, mouseEvent) {
              | (Some(lastFloorPt), Some(ev)) =>
                let mc = Viewer.mouseEventToCoords(v, ev)
                let pitchOpt = Belt.Array.get(mc, 0)
                let yawOpt = Belt.Array.get(mc, 1)

                switch (pitchOpt, yawOpt) {
                | (Some(p), Some(y)) =>
                  let mousePt: PathInterpolation.point = {
                    PathInterpolation.yaw: y,
                    pitch: p,
                  }

                  let _camPitch = Viewer.getPitch(v)
                  // Always draw pending path for visual feedback (rubber banding)
                  // v4.2.18 behavior: Yellow dashed line from last click to mouse
                  let pendingPath = [lastFloorPt, mousePt]

                  // Only project if looking steeply down? No, user wants it always visible as feedback.
                  // Logic was:
                  // let pendingPath = if camPitch < -20.0 {
                  //   PathInterpolation.getFloorProjectedPath(lastFloorPt, mousePt, 20)
                  // } else {
                  //   [lastFloorPt, mousePt]
                  // }

                  drawPolyLine(
                    svg,
                    v,
                    pendingPath,
                    rect,
                    "#fbbf24",
                    3.0,
                    0.8,
                    ~className="line-rod-yellow",
                    (),
                  )
                | _ => ()
                }
              | _ => ()
              }

            | None => ()
            }
          } else if state.simulation.status != Running {
            // 3. Preview Arrows
            let previewing = switch state.navigation {
            | Previewing(info) => Some(info)
            | _ => None
            }

            let hots = currentScene.hotspots
            for i in 0 to Array.length(hots) - 1 {
              switch Belt.Array.get(hots, i) {
              | Some(h) =>
                let isBeingPreviewed = switch previewing {
                | Some(p) => p.sceneIndex == state.activeIndex && p.hotspotIndex == i
                | None => false
                }

                if !isBeingPreviewed {
                  switch (h.startYaw, h.startPitch, h.viewFrame) {
                  | (Some(sy), Some(sp), Some(vf)) =>
                    let nextPoint = switch h.waypoints {
                    | Some(w) if Array.length(w) > 0 =>
                      switch Belt.Array.get(w, 0) {
                      | Some(firstW) =>
                        Some({
                          PathInterpolation.yaw: firstW.yaw,
                          pitch: firstW.pitch,
                        })
                      | None => Some({PathInterpolation.yaw: vf.yaw, pitch: vf.pitch})
                      }
                    | _ => Some({PathInterpolation.yaw: vf.yaw, pitch: vf.pitch})
                    }

                    switch nextPoint {
                    | Some(np) =>
                      let s1Opt = getScreenCoords(v, sp, sy, rect)
                      let s2Opt = getScreenCoords(v, np.pitch, np.yaw, rect)

                      switch (s1Opt, s2Opt) {
                      | (Some(s1), Some(s2)) =>
                        let angle =
                          Math.atan2(~y=s2.y -. s1.y, ~x=s2.x -. s1.x) *.
                          (180.0 /.
                          Math.Constants.pi)

                        if Float.isFinite(s1.x) && Float.isFinite(s1.y) && Float.isFinite(angle) {
                          let arrow = Svg.createElementNS(Svg.namespace, "path")
                          Svg.setAttribute(arrow, "d", "M -10,-7 L 6,0 L -10,7 Z")
                          Svg.setAttribute(arrow, "fill", "#10b981")
                          Svg.setAttribute(arrow, "stroke", "#000")
                          Svg.setAttribute(arrow, "stroke-width", "1")
                          Svg.setAttribute(
                            arrow,
                            "transform",
                            "translate(" ++
                            Float.toString(s1.x) ++
                            ", " ++
                            Float.toString(s1.y) ++
                            ") rotate(" ++
                            Float.toString(angle) ++ ")",
                          )
                          Svg.setAttribute(arrow, "class", "preview-arrow")
                          Svg.setAttribute(arrow, "data-hs-index", Int.toString(i))

                          Dom.setCursor(arrow, "pointer")
                          Dom.setPointerEvents(arrow, "all")

                          Svg.setOnMouseOver(arrow, () =>
                            Svg.setAttribute(arrow, "fill", "#34d399")
                          )
                          Svg.setOnMouseOut(arrow, () => Svg.setAttribute(arrow, "fill", "#10b981"))

                          Svg.appendChild(svg, arrow)
                        }
                      | _ => ()
                      }
                    | None => ()
                    }
                  | _ => ()
                  }
                }
              | None => ()
              }
            }
          }
        }
      | None => ()
      }
    }
  | _ => ()
  }
}
