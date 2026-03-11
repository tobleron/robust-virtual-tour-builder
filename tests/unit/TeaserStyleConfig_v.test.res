open Vitest
open Types

let samplePathPoint: pathPoint = {yaw: 0.0, pitch: 0.0}

let samplePathData = (panDuration: float): pathData => {
  startPitch: 0.0,
  startYaw: 0.0,
  startHfov: 80.0,
  targetPitchForPan: 0.0,
  targetYawForPan: 10.0,
  targetHfovForPan: 80.0,
  totalPathDistance: 10.0,
  segments: [
    {
      dist: 10.0,
      yawDiff: 10.0,
      pitchDiff: 0.0,
      p1: samplePathPoint,
      p2: {yaw: 10.0, pitch: 0.0},
    },
  ],
  waypoints: [samplePathPoint, {yaw: 10.0, pitch: 0.0}],
  panDuration,
  arrivalYaw: 10.0,
  arrivalPitch: 0.0,
  arrivalHfov: 80.0,
}

let sampleManifest = (panDuration: float): motionManifest => {
  version: "motion-spec-v1",
  fps: 60,
  canvasWidth: 1920,
  canvasHeight: 1080,
  includeIntroPan: false,
  shots: [
    {
      sceneId: "scene-1",
      arrivalPose: {yaw: 0.0, pitch: 0.0, hfov: 80.0},
      animationSegments: [],
      transitionOut: None,
      pathData: Some(samplePathData(panDuration)),
      waitBeforePanMs: 0,
      blinkAfterPanMs: 0,
    },
    {
      sceneId: "scene-2",
      arrivalPose: {yaw: 10.0, pitch: 0.0, hfov: 80.0},
      animationSegments: [],
      transitionOut: None,
      pathData: None,
      waitBeforePanMs: 0,
      blinkAfterPanMs: 0,
    },
  ],
}

describe("TeaserStyleConfig", () => {
  test("resolvePanSpeedOption returns known presets and falls back to default", t => {
    t->expect(TeaserStyleConfig.resolvePanSpeedOption(Some("fast")).id)->Expect.toBe("fast")
    t
    ->expect(TeaserStyleConfig.resolvePanSpeedOption(Some("unknown")).id)
    ->Expect.toBe(TeaserStyleConfig.defaultPanSpeedId)
    t
    ->expect(TeaserStyleConfig.resolvePanSpeedOption(None).speedDegPerSec)
    ->Expect.toBe(Constants.panningVelocity)
  })

  test("applyPanSpeedOption leaves the manifest unchanged for the default preset", t => {
    let manifest = sampleManifest(1200.0)
    let result = TeaserStyleConfig.applyPanSpeedOption(manifest, TeaserStyleConfig.defaultPanSpeed)
    let firstShot = result.shots[0]->Belt.Option.getExn
    let secondShot = result.shots[1]->Belt.Option.getExn

    let pathData = firstShot.pathData->Belt.Option.getExn
    t->expect(pathData.panDuration)->Expect.toBe(1200.0)
    t->expect(secondShot.pathData)->Expect.toEqual(None)
  })

  test("applyPanSpeedOption retimes pan durations and respects clamp bounds", t => {
    let slow = TeaserStyleConfig.resolvePanSpeedOption(Some("slow"))
    let fast = TeaserStyleConfig.resolvePanSpeedOption(Some("fast"))

    let slowResult = TeaserStyleConfig.applyPanSpeedOption(sampleManifest(1200.0), slow)
    let fastResult = TeaserStyleConfig.applyPanSpeedOption(sampleManifest(1200.0), fast)
    let slowShot = slowResult.shots[0]->Belt.Option.getExn
    let fastShot = fastResult.shots[0]->Belt.Option.getExn
    let slowPathData = slowShot.pathData->Belt.Option.getExn
    let fastPathData = fastShot.pathData->Belt.Option.getExn

    t->expect(slowPathData.panDuration)->Expect.toBe(2000.0)
    t->expect(fastPathData.panDuration)->Expect.toBe(Constants.panningMinDuration)
  })
})
