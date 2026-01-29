/* src/systems/NavigationGraph.res - Extracted Pathfinding Logic */

open Types
open ReBindings

let calculateSmartArrivalTarget = (scenes: array<scene>, targetIndex: int) => {
  let (ay, ap, ah) = (ref(0.0), ref(0.0), ref(90.0))
  if targetIndex >= 0 && targetIndex < Array.length(scenes) {
    scenes[targetIndex]->Option.forEach(ns => {
      let t =
        ns.hotspots
        ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
        ->Option.getOr(ns.hotspots->Belt.Array.get(0)->Option.getOr(Obj.magic(None)))
      if Obj.magic(t) !== None {
        switch (t.startYaw, t.startPitch) {
        | (Some(sy), Some(sp)) =>
          ay := sy
          ap := sp
          t.startHfov->Option.forEach(sh => ah := sh)
        | _ =>
          ay := t.yaw -. 35.0
          ap := 0.0
        }
      }
    })
  }
  (ay.contents, ap.contents, ah.contents)
}

let getCurrentView = () => {
  switch Viewer.instance->Nullable.toOption {
  | Some(v) => (Viewer.getYaw(v), Viewer.getPitch(v), Viewer.getHfov(v))
  | None => (0.0, 0.0, 90.0)
  }
}

let findSceneByName = (scenes, name) => scenes->Belt.Array.getBy(s => s.name == name)

let getNextScene = (scenes, cur) => {
  let len = Array.length(scenes)
  len == 0 ? None : Some(mod(cur + 1, len))
}

let getPreviousScene = (scenes, cur) => {
  let len = Array.length(scenes)
  len == 0 ? None : Some(mod(cur - 1 + len, len))
}

let calculatePathData = (state: state, sIdx, sHIdx, tIdx, tYaw, tPitch, tHfov, currView) => {
  state.scenes[sIdx]->Option.flatMap(src => {
    src.hotspots[sHIdx]->Option.flatMap(h => {
      let (cy, cp, ch) = currView
      let (ay, ap, ah) =
        state.simulation.status == Running
          ? calculateSmartArrivalTarget(state.scenes, tIdx)
          : (tYaw, tPitch, tHfov)
      let (sy, sp) = (h.startYaw->Option.getOr(cy), h.startPitch->Option.getOr(cp))
      let (ty, tp) = h.viewFrame->Option.map(vf => (vf.yaw, vf.pitch))->Option.getOr((tYaw, tPitch))
      let p0: PathInterpolation.point = {yaw: sy, pitch: sp}
      let pe: PathInterpolation.point = {yaw: ty, pitch: tp}
      let wp =
        h.waypoints
        ->Option.getOr([])
        ->Belt.Array.map(
          (w): PathInterpolation.point => {
            PathInterpolation.yaw: w.yaw,
            pitch: w.pitch,
          },
        )
      let cp = Array.length(wp) > 0 ? Array.concat([p0], Array.concat(wp, [pe])) : [p0, pe]
      let path =
        Array.length(wp) > 0
          ? PathInterpolation.getCatmullRomSpline(cp, 100)
          : PathInterpolation.getFloorProjectedPath(p0, pe, 100)
      let (tdist, segs) = (ref(0.0), [])
      if Array.length(path) >= 2 {
        for i in 0 to Array.length(path) - 2 {
          switch (Belt.Array.get(path, i), Belt.Array.get(path, i + 1)) {
          | (Some(p1), Some(p2)) =>
            let yd = ref(p2.yaw -. p1.yaw)
            while yd.contents > 180.0 {
              yd := yd.contents -. 360.0
            }
            while yd.contents < -180.0 {
              yd := yd.contents +. 360.0
            }
            let pd = p2.pitch -. p1.pitch
            let d = Math.sqrt(yd.contents ** 2.0 +. pd ** 2.0)
            let _ = Array.push(
              segs,
              {
                dist: d,
                yawDiff: yd.contents,
                pitchDiff: pd,
                p1: {yaw: p1.yaw, pitch: p1.pitch},
                p2: {yaw: p2.yaw, pitch: p2.pitch},
              },
            )
            tdist := tdist.contents +. d
          | _ => ()
          }
        }
      }
      let dur = Math.min(
        Math.max(
          tdist.contents /. Constants.panningVelocity *. 1000.0,
          Constants.panningMinDuration,
        ),
        Constants.panningMaxDuration,
      )
      Some({
        startPitch: sp,
        startYaw: sy,
        startHfov: ch,
        targetPitchForPan: tp,
        targetYawForPan: ty,
        targetHfovForPan: ah,
        totalPathDistance: tdist.contents,
        segments: segs,
        waypoints: wp->Belt.Array.map((p): pathPoint => {yaw: p.yaw, pitch: p.pitch}),
        panDuration: dur,
        arrivalYaw: ay,
        arrivalPitch: ap,
        arrivalHfov: ah,
      })
    })
  })
}
