open Types

let getArrowId = (state: Types.state, j: journeyData): string => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch activeScenes[j.sourceIndex] {
  | Some(s) =>
    switch s.hotspots[j.hotspotIndex] {
    | Some(h) => "arrow_" ++ h.linkId
    | None => "sim_arrow"
    }
  | None => "sim_arrow"
  }
}

let waypointPoints = (pd: Types.pathData): array<PathInterpolation.point> =>
  pd.waypoints->Belt.Array.map((w): PathInterpolation.point => {
    PathInterpolation.yaw: w.yaw,
    pitch: w.pitch,
  })

let segmentPoints = (pd: Types.pathData) =>
  pd.segments->Belt.Array.map(s => (
    s.dist,
    s.yawDiff,
    s.pitchDiff,
    {PathInterpolation.yaw: s.p1.yaw, pitch: s.p1.pitch},
    {PathInterpolation.yaw: s.p2.yaw, pitch: s.p2.pitch},
  ))

let renderSimulationOverlay = (
  v,
  state: Types.state,
  j: journeyData,
  pd: Types.pathData,
  progress: float,
  ~opacity: float,
  (),
) => {
  HotspotLine.updateLines(v, state, ())
  HotspotLine.updateSimulationArrow(
    v,
    pd.startPitch,
    pd.startYaw,
    pd.targetPitchForPan,
    pd.targetYawForPan,
    progress,
    ~opacity,
    ~waypoints=waypointPoints(pd),
    ~colorOverride=?j.previewOnly ? Some("red") : None,
    ~preComputedSegments=segmentPoints(pd),
    ~preComputedTotalDistance=pd.totalPathDistance,
    ~id=getArrowId(state, j),
    (),
  )
}
