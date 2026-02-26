open Types

let fastShotDurationMs = 1200

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
  let shots = baseManifest.shots->Belt.Array.map(shot => {
    ...shot,
    arrivalPose: resolveEndpointPose(shot),
    animationSegments: [],
    transitionOut: None,
    pathData: None,
    waitBeforePanMs: fastShotDurationMs,
    blinkAfterPanMs: 0,
  })
  if Belt.Array.length(shots) == 0 {
    Error("No teaser shots available")
  } else {
    Ok({...baseManifest, shots})
  }
}
