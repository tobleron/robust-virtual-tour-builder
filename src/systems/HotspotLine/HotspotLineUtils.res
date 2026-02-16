/* src/systems/HotspotLine/HotspotLineUtils.res */
// @efficiency-role: util-pure

open ReBindings
open HotspotLineState

let lastFrameIds = lastFrameIds
let pathCache = pathCache
let segmentCache = segmentCache

let getCachedSplinePath = (h: Types.hotspot, controlPoints, segments) => {
  switch Nullable.toOption(JSWeakMap.get(pathCache, h)) {
  | Some(p) => p
  | None =>
    let p = PathInterpolation.getBSplinePath(controlPoints, segments)
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
