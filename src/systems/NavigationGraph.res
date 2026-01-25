/* src/systems/NavigationGraph.res */

open Types

/* --- HELPERS --- */

/* Calculate the intended arrival orientation for a scene */
let calculateSmartArrivalTarget = (scenes: array<scene>, targetIndex: int) => {
  let arrivalYaw = ref(0.0)
  let arrivalPitch = ref(0.0)
  let arrivalHfov = ref(90.0)

  if targetIndex >= 0 && targetIndex < Belt.Array.length(scenes) {
    let nextSceneOpt = Belt.Array.get(scenes, targetIndex)

    switch nextSceneOpt {
    | Some(nextScene) =>
      /* PRIORITY: Use creation sequence (Oldest first) logic from JS is:
           let nextHotspot = null
           if (!nextHotspot && nextScene.hotspots.length > 0) ...
           Use find explicitly.
 */
      let nextHotspot = Array.find(nextScene.hotspots, h => {
        /* !h.isReturnLink */
        switch h.isReturnLink {
        | Some(true) => false
        | _ => true
        }
      })

      let target = switch nextHotspot {
      | Some(h) => Some(h)
      | None =>
        if Belt.Array.length(nextScene.hotspots) > 0 {
          Belt.Array.get(nextScene.hotspots, 0)
        } else {
          None
        }
      }

      switch target {
      | Some(h) =>
        /* Check startYaw/Pitch definition */
        switch (h.startYaw, h.startPitch) {
        | (Some(sy), Some(sp)) =>
          arrivalYaw := sy
          arrivalPitch := sp
          switch h.startHfov {
          | Some(sh) => arrivalHfov := sh
          | _ => ()
          }
        | _ =>
          arrivalYaw := h.yaw -. 35.0
          arrivalPitch := 0.0
        }
      | None => ()
      }
    | None => ()
    }
  }

  (arrivalYaw.contents, arrivalPitch.contents, arrivalHfov.contents)
}

/* Helper to get current view safely */
let getCurrentView = () => {
  switch Nullable.toOption(ReBindings.Viewer.instance) {
  | Some(v) => (
      ReBindings.Viewer.getYaw(v),
      ReBindings.Viewer.getPitch(v),
      ReBindings.Viewer.getHfov(v),
    )
  | None => (0.0, 0.0, 90.0)
  }
}

/**
 * Finds a scene by its name in the given array of scenes.
 */
let findSceneByName = (scenes: array<Types.scene>, name: string) => {
  Belt.Array.getBy(scenes, s => s.name == name)
}

/**
 * Returns the index of the next scene in the array, wrapping around to the start.
 */
let getNextScene = (scenes: array<Types.scene>, currentIndex: int) => {
  let len = Array.length(scenes)
  if len == 0 {
    None
  } else {
    Some(mod(currentIndex + 1, len))
  }
}

/**
 * Returns the index of the previous scene in the array, wrapping around to the end.
 */
let getPreviousScene = (scenes: array<Types.scene>, currentIndex: int) => {
  let len = Array.length(scenes)
  if len == 0 {
    None
  } else {
    Some(mod(currentIndex - 1 + len, len))
  }
}

/* --- PURE PATH CALCULATION --- */

let calculatePathData = (
  state: state,
  sourceSceneIndex: int,
  sourceHotspotIndex: int,
  targetIndex: int,
  targetYaw: float,
  targetPitch: float,
  targetHfov: float,
  currentView: (float, float, float),
) => {
  let sourceSceneOpt = Belt.Array.get(state.scenes, sourceSceneIndex)
  switch sourceSceneOpt {
  | Some(sourceScene) =>
    let hotspotOpt = Belt.Array.get(sourceScene.hotspots, sourceHotspotIndex)
    switch hotspotOpt {
    | Some(hotspot) =>
      let (curYaw, curPitch, curHfov) = currentView

      let (arrYaw, arrPitch, arrHfov) = if state.simulation.status == Running {
        calculateSmartArrivalTarget(state.scenes, targetIndex)
      } else {
        (targetYaw, targetPitch, targetHfov)
      }

      /* Determine start params */
      let startPitch = switch hotspot.startPitch {
      | Some(p) => p
      | _ => curPitch
      }
      let startYaw = switch hotspot.startYaw {
      | Some(y) => y
      | _ => curYaw
      }

      /* Determine target pan params */
      let (tYawPan, tPitchPan) = switch hotspot.viewFrame {
      | Some(vf) => (vf.yaw, vf.pitch)
      | _ => (targetYaw, targetPitch)
      }

      /* Generate Control Points */
      let p0: PathInterpolation.point = {yaw: startYaw, pitch: startPitch}
      let pEnd: PathInterpolation.point = {yaw: tYawPan, pitch: tPitchPan}

      let waypointsRaw = switch hotspot.waypoints {
      | Some(w) => w
      | None => []
      }
      let waypoints: array<PathInterpolation.point> = Belt.Array.map(waypointsRaw, w => {
        PathInterpolation.yaw: w.yaw,
        pitch: w.pitch,
      })

      let controlPoints = if Array.length(waypoints) > 0 {
        Belt.Array.concat([p0], Belt.Array.concat(waypoints, [pEnd]))
      } else {
        [p0, pEnd]
      }

      /* Path generation - match HotspotLine.res logic */
      let path = if Array.length(waypoints) > 0 {
        PathInterpolation.getCatmullRomSpline(controlPoints, 100)
      } else {
        PathInterpolation.getFloorProjectedPath(p0, pEnd, 100)
      }

      /* Calculate segments and total distance */
      let totalDistance = ref(0.0)
      let segments = []

      if Array.length(path) >= 2 {
        for i in 0 to Array.length(path) - 2 {
          switch (Belt.Array.get(path, i), Belt.Array.get(path, i + 1)) {
          | (Some(p1_orig), Some(p2_orig)) =>
            let p1: pathPoint = {yaw: p1_orig.yaw, pitch: p1_orig.pitch}
            let p2: pathPoint = {yaw: p2_orig.yaw, pitch: p2_orig.pitch}

            let yawDiff = ref(p2.yaw -. p1.yaw)
            while yawDiff.contents > 180.0 {
              yawDiff := yawDiff.contents -. 360.0
            }
            while yawDiff.contents < -180.0 {
              yawDiff := yawDiff.contents +. 360.0
            }

            let pitchDiff = p2.pitch -. p1.pitch
            let dist = Math.sqrt(yawDiff.contents *. yawDiff.contents +. pitchDiff *. pitchDiff)

            let segment: pathSegment = {
              dist,
              yawDiff: yawDiff.contents,
              pitchDiff,
              p1,
              p2,
            }
            let _ = Array.push(segments, segment)
            totalDistance := totalDistance.contents +. dist
          | _ => ()
          }
        }
      }

      let panDuration = Math.min(
        Math.max(
          totalDistance.contents /. Constants.panningVelocity *. 1000.0,
          Constants.panningMinDuration,
        ),
        Constants.panningMaxDuration,
      )

      Some({
        startPitch,
        startYaw,
        startHfov: curHfov,
        targetPitchForPan: tPitchPan,
        targetYawForPan: tYawPan,
        targetHfovForPan: arrHfov,
        totalPathDistance: totalDistance.contents,
        segments,
        waypoints: Belt.Array.map(waypoints, p => {yaw: p.yaw, pitch: p.pitch}),
        panDuration,
        arrivalYaw: arrYaw,
        arrivalPitch: arrPitch,
        arrivalHfov: arrHfov,
      })
    | None => None
    }
  | None => None
  }
}
