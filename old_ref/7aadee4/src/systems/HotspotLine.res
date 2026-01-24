/* src/systems/HotspotLine.res */

open ReBindings
open HotspotLineTypes
open HotspotLineLogic

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

/* --- FACADE --- */

let isViewerReady = HotspotLineLogic.isViewerReady
let getScreenCoords = HotspotLineLogic.getScreenCoords
let drawSimulationArrow = HotspotLineLogic.drawSimulationArrow

external asCustom: Viewer.t => customViewerProps = "%identity"

let updateLines = (viewer, state: Types.state, ~mouseEvent: option<'a>=?, ()) => {
  let svgOpt = Dom.getElementById("viewer-hotspot-lines")
  switch Nullable.toOption(svgOpt) {
  | Some(svg) =>
    Dom.setTextContent(svg, "")

    if !isViewerReady(viewer) {
      ()
    } else {
      let rect = Dom.getBoundingClientRect(svg)

      if rect.width > 0.0 && state.activeIndex >= 0 {
        let viewerSceneId = asCustom(viewer).sceneId

        let sceneToRender = switch Belt.Array.getBy(state.scenes, s => s.id == viewerSceneId) {
        | Some(s) => Some(s)
        | None =>
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
                    let splinePath = getCachedSplinePath(h, controlPoints, 100)
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
              ()
            }
          }
        | None => ()
        }
      }
    }
  | None => ()
  }
}
