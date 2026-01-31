/* src/systems/HotspotLine/HotspotLineLogicTypes.res */
// @efficiency-role: data-model

type customViewerProps = {@as("_sceneId") sceneId: string}

// Cache for path segments to avoid heavy re-calculation (O(N) * 60fps)
type segmentData = (
  float,
  array<(float, float, float, PathInterpolation.point, PathInterpolation.point)>,
)
