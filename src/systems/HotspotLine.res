/* src/systems/HotspotLine.res */

open ReBindings

/* --- TYPES --- */

type screenCoords = {x: float, y: float}

/* --- CACHING --- */

let pathCache: JSWeakMap.t<Types.hotspot, array<PathInterpolation.point>> = JSWeakMap.make()

let getCachedSplinePath = (h: Types.hotspot, controlPoints, segments) => {
  switch Nullable.toOption(JSWeakMap.get(pathCache, h)) {
  | Some(p) => p
  | None =>
    let p = PathInterpolation.getCatmullRomSpline(controlPoints, segments)
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

/* --- VIEWER VALIDATION --- */

/**
 * Validates that a viewer instance has valid camera data AND is fully loaded.
 * Returns false if:
 * - Pannellum hasn't finished loading the scene texture
 * - Camera values are NaN or infinite
 * - HFOV is zero or negative
 */
let isViewerValid = (viewer: Viewer.t): bool => {
  // Check if Pannellum has finished loading the scene
  // This is critical - before isLoaded() is true, camera values are unreliable
  let loaded = Viewer.isLoaded(viewer)

  if !loaded {
    false
  } else {
    let hfov = Viewer.getHfov(viewer)
    let yaw = Viewer.getYaw(viewer)
    let pitch = Viewer.getPitch(viewer)

    // Check for valid HFOV (must be positive and finite)
    // Check for finite yaw and pitch values
    hfov > 0.0 && Float.isFinite(hfov) && Float.isFinite(yaw) && Float.isFinite(pitch)
  }
}

/**
 * Checks if the given viewer is the currently active viewer.
 * This prevents rendering with stale camera data from an old viewer
 * that's being faded out during scene transitions.
 */
let isActiveViewer = (viewer: Viewer.t): bool => {
  let activeViewer = ViewerState.getActiveViewer()
  switch Nullable.toOption(activeViewer) {
  | Some(active) => active === viewer
  | None => false
  }
}

/**
 * Combined check: viewer must be:
 * 1. Fully loaded (Pannellum has initialized camera)
 * 2. Have valid camera values (finite, positive HFOV)
 * 3. Be the currently active viewer (not a stale reference)
 * 
 * Use this before any screen coordinate calculations.
 */
let isViewerReady = (viewer: Viewer.t): bool => {
  if !isViewerValid(viewer) {
    false
  } else if !isActiveViewer(viewer) {
    false
  } else {
    // Stricter check: If camera is exactly at 0,0,0, it might be uninitialized.
    // However, 0,0 is a valid view. We check if it matches the "default" state
    // that creates artifacts (e.g. before initialYaw is applied).
    // For now, we rely on isViewerValid's finite checks, but we add a check for
    // extremely small HFOV which indicates initialization failure.
    Viewer.getHfov(viewer) > 1.0
  }
}

/* --- MATH HELPERS --- */

let getScreenCoords = (viewer, pitch, yaw, rect: Dom.rect) => {
  // Early exit if viewer is not valid or not the active viewer
  // This prevents calculating positions from a stale viewer during transitions
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

        // Essential safety check: Reject non-finite values from mathematical edge cases
        // Note: isViewerReady() already validates camera data, and CSS hides (0,0) artifacts
        if !Float.isFinite(x) || !Float.isFinite(y) {
          None
        } else {
          let screenX = rect.width /. 2.0 *. (1.0 +. x)
          let screenY = rect.height /. 2.0 *. (1.0 -. y)

          Some({
            x: screenX,
            y: screenY,
          })
        }
      }
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
  // Early exit if viewer is stale or not active - prevents drawing with wrong camera data
  if !isViewerReady(viewer) {
    ()
  } else {
    let svgOpt = Dom.getElementById("viewer-hotspot-lines")
    switch (Nullable.toOption(svgOpt), viewer) {
    | (Some(svg), v) =>
      let rect = Dom.getBoundingClientRect(svg)

      // Safety check for zero-size rect (e.g. during layout thrashing)
      if rect.width <= 0.0 || rect.height <= 0.0 {
        ()
      } else {
        // 1. Path Generation
        let path = if Array.length(waypoints) > 0 {
          let startPt: array<PathInterpolation.point> = [
            {PathInterpolation.yaw: startYaw, pitch: startPitch},
          ]
          let endPt: array<PathInterpolation.point> = [
            {PathInterpolation.yaw: endYaw, pitch: endPitch},
          ]
          let controlPoints = Belt.Array.concat(startPt, Belt.Array.concat(waypoints, endPt))
          PathInterpolation.getCatmullRomSpline(controlPoints, 50)
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
              let _ = Array.push(segments, segment)
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
                "var(--warning-light)"
              } else {
                "var(--success)"
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

/* --- INTERNAL HELPERS --- */
type customViewerProps = {@as("_sceneId") sceneId: string}
external asCustom: Viewer.t => customViewerProps = "%identity"

let updateLines = (viewer, state: Types.state, ~mouseEvent: option<'a>=?, ()) => {
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch Nullable.toOption(svgOpt) {
  | Some(svg) =>
    // ALWAYS clear SVG first to prevent stale arrows from lingering
    // This is critical - even if we exit early, we don't want old content
    Dom.setTextContent(svg, "")

    // Now check if viewer is ready for drawing new content
    // If not ready, SVG stays cleared (no arrows) which is correct behavior
    if !isViewerReady(viewer) {
      () // Exit - SVG is already cleared, nothing to draw
    } else {
      let rect = Dom.getBoundingClientRect(svg)

      if rect.width > 0.0 && state.activeIndex >= 0 {
        // Correctly identify the scene currently displayed by THIS viewer
        // We must use the custom _sceneId property because Viewer.getScene() returns
        // Pannellum's internal ID ("master"/"preview") which doesn't match our state.
        let viewerSceneId = asCustom(viewer).sceneId

        // Find the scene object that matches what the viewer is actually showing
        let sceneToRender = switch Belt.Array.getBy(state.scenes, s => s.id == viewerSceneId) {
        | Some(s) => Some(s)
        | None =>
          // Fallback: If custom ID is missing or invalid, check if active scene matches
          // This handles cases where _sceneId might not be set yet (rare)
          switch Belt.Array.get(state.scenes, state.activeIndex) {
          | Some(activeS) if activeS.id == viewerSceneId => Some(activeS)
          | _ => None
          }
        }

        switch sceneToRender {
        | Some(currentScene) => {
            let _isSimulationActive = state.simulation.status != Idle

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
                  let waypoints: array<PathInterpolation.point> = Belt.Array.map(
                    waypointsRaw,
                    w => {
                      PathInterpolation.yaw: w.yaw,
                      pitch: w.pitch,
                    },
                  )

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
                    let splinePath = getCachedSplinePath(h, controlPoints, 30)
                    drawPolyLine(
                      svg,
                      viewer,
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
                    let curvedPath = getCachedFloorPath(h, startPt, endPt, 20)
                    drawPolyLine(
                      svg,
                      viewer,
                      curvedPath,
                      rect,
                      "var(--danger-light)",
                      3.0,
                      0.8,
                      ~className="line-marching-ants",
                      (),
                    )
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
                let camStart: PathInterpolation.point = {
                  PathInterpolation.yaw: draft.camYaw,
                  pitch: draft.camPitch,
                }

                let intermediate = switch draft.intermediatePoints {
                | Some(pts) => pts
                | None => []
                }

                // --- RED CRITICAL PATH (Camera Director Curve) ---
                let currentCam: PathInterpolation.point = {
                  PathInterpolation.yaw: Viewer.getYaw(viewer),
                  pitch: Viewer.getPitch(viewer),
                }
                let redPoints = Belt.Array.concat(
                  [camStart],
                  Belt.Array.map(intermediate, (p): PathInterpolation.point => {
                    PathInterpolation.yaw: p.camYaw,
                    pitch: p.camPitch,
                  }),
                )
                let allRedPoints = Belt.Array.concat(redPoints, [currentCam])

                if Array.length(allRedPoints) == 2 {
                  // Ensure curvature from the very first click using floor projection
                  // Use floor projection for red path too as it gives the desired curved look
                  switch (Belt.Array.get(allRedPoints, 0), Belt.Array.get(allRedPoints, 1)) {
                  | (Some(p1), Some(p2)) =>
                    let path = PathInterpolation.getFloorProjectedPath(p1, p2, 40)
                    drawPolyLine(
                      svg,
                      viewer,
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
                  let redSpline = PathInterpolation.getCatmullRomSpline(allRedPoints, 60)
                  drawPolyLine(
                    svg,
                    viewer,
                    redSpline,
                    rect,
                    "var(--danger-light)",
                    3.0,
                    1.0,
                    ~className="line-marching-ants",
                    (),
                  )
                }

                // --- YELLOW TARGET PATH (The Rod) ---
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
                    "clientX": Belt.Int.toFloat(Obj.magic(ev)["clientX"]),
                    "clientY": Belt.Int.toFloat(Obj.magic(ev)["clientY"]) +.
                    Constants.linkingRodHeight,
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

                if Array.length(allYellowPoints) == 2 {
                  // Ensure curvature from the very first click using floor projection
                  switch (Belt.Array.get(allYellowPoints, 0), Belt.Array.get(allYellowPoints, 1)) {
                  | (Some(p1), Some(p2)) =>
                    let path = PathInterpolation.getFloorProjectedPath(p1, p2, 40)
                    drawPolyLine(
                      svg,
                      viewer,
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
                  let yellowSpline = PathInterpolation.getCatmullRomSpline(allYellowPoints, 60)
                  drawPolyLine(
                    svg,
                    viewer,
                    yellowSpline,
                    rect,
                    "var(--warning-light)",
                    3.0,
                    0.8,
                    ~className="line-rod-yellow",
                    (),
                  )
                }

              | None => ()
              }
            } else if state.simulation.status == Idle {
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
                        let s1Opt = getScreenCoords(viewer, sp, sy, rect)
                        let s2Opt = getScreenCoords(viewer, np.pitch, np.yaw, rect)

                        switch (s1Opt, s2Opt) {
                        | (Some(s1), Some(s2)) =>
                          let angle =
                            Math.atan2(~y=s2.y -. s1.y, ~x=s2.x -. s1.x) *.
                            (180.0 /.
                            Math.Constants.pi)

                          if Float.isFinite(s1.x) && Float.isFinite(s1.y) && Float.isFinite(angle) {
                            let arrow = Svg.createElementNS(Svg.namespace, "path")
                            Svg.setAttribute(arrow, "d", "M -10,-7 L 6,0 L -10,7 Z")
                            Svg.setAttribute(arrow, "fill", "var(--success)")
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
                              Svg.setAttribute(arrow, "fill", "var(--success-light)")
                            )
                            Svg.setOnMouseOut(arrow, () =>
                              Svg.setAttribute(arrow, "fill", "var(--success)")
                            )

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
    }
  | None => ()
  }
}
