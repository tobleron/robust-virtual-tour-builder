/* src/systems/HotspotLine/HotspotLineState.res */
// @efficiency-role: data-model

open ReBindings

type customViewerProps = {@as("_sceneId") sceneId: string}

// Cache for path segments to avoid heavy re-calculation (O(N) * 60fps)
type segmentData = (
  float,
  array<(float, float, float, PathInterpolation.point, PathInterpolation.point)>,
)

// The global caches for the hotspot line system
let lastFrameIds = ref(Belt.MutableSet.String.make())
let pathCache: JSWeakMap.t<Types.hotspot, array<PathInterpolation.point>> = JSWeakMap.make()
let segmentCache: JSWeakMap.t<array<PathInterpolation.point>, segmentData> = JSWeakMap.make()
