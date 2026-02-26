open Types

let shotDurationMs = 1800
let premiumCrossfadeDurationMs = 900

let resolveEndpointPose = (shot: motionShot): viewFrame =>
  switch shot.pathData {
  | Some(pathData) => {
      yaw: pathData.targetYawForPan,
      pitch: pathData.targetPitchForPan,
      hfov: ViewerSystem.getCorrectHfov(),
    }
  | None =>
    switch Belt.Array.get(shot.animationSegments, Belt.Array.length(shot.animationSegments) - 1) {
    | Some(segment) => {
        yaw: segment.endYaw,
        pitch: segment.endPitch,
        hfov: segment.endHfov,
      }
    | None => shot.arrivalPose
    }
  }

let buildManifest = (state: state, ~skipAutoForward: bool, ~includeIntroPan: bool): result<
  motionManifest,
  string,
> => {
  let baseManifest = TeaserManifest.generateSimulationParityManifest(
    state,
    ~skipAutoForward,
    ~includeIntroPan,
  )
  let shotsCount = Belt.Array.length(baseManifest.shots)
  let shots = baseManifest.shots->Belt.Array.mapWithIndex((idx, shot) => {
    let isLastShot = idx == shotsCount - 1
    {
      ...shot,
      arrivalPose: resolveEndpointPose(shot),
      animationSegments: [],
      pathData: None,
      waitBeforePanMs: shotDurationMs,
      blinkAfterPanMs: 0,
      transitionOut: if isLastShot {
        None
      } else {
        Some({type_: "crossfade", durationMs: premiumCrossfadeDurationMs})
      },
    }
  })
  if shotsCount == 0 {
    Error("No teaser shots available")
  } else {
    Ok({...baseManifest, shots})
  }
}
