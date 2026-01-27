/* src/systems/HotspotLineUtils.res */

open ReBindings

/* --- STATE --- */
let lastFrameIds = ref(Belt.MutableSet.String.make())

/* --- CACHING --- */

let pathCache: JSWeakMap.t<Types.hotspot, array<PathInterpolation.point>> = JSWeakMap.make()

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
