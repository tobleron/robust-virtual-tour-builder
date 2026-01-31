/* src/systems/HotspotLine/HotspotLineUtils.res */
// @efficiency-role: util-pure

open ReBindings
open HotspotLineLogicTypes

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
