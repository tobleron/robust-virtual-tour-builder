open Vitest
open Types

let makeLinkHotspot = (): hotspot => {
  linkId: "h1",
  yaw: 12.0,
  pitch: -3.0,
  target: "scene-2",
  targetSceneId: Some("scene-2"),
  targetYaw: Some(47.0),
  targetPitch: Some(-8.0),
  targetHfov: Some(80.0),
  startYaw: None,
  startPitch: None,
  startHfov: None,
  viewFrame: None,
  waypoints: None,
  displayPitch: None,
  transition: None,
  duration: None,
  isAutoForward: None,
  sequenceOrder: None,
}

describe("TeaserStyleFastShots", () => {
  test("buildManifest creates static endpoint shots with 1200ms duration", t => {
    let s1 = TestUtils.createMockScene(
      ~id="scene-1",
      ~name="Scene 1",
      ~hotspots=[makeLinkHotspot()],
      (),
    )
    let s2 = TestUtils.createMockScene(~id="scene-2", ~name="Scene 2", ())
    let state = TestUtils.createMockState(~scenes=[s1, s2], ~activeIndex=0, ())

    let manifest = TeaserStyleFastShots.buildManifest(
      state,
      ~skipAutoForward=false,
      ~includeIntroPan=false,
    )

    t->expect(manifest->Result.isOk)->Expect.toBe(true)
    let resolved = manifest->Result.getOrThrow
    t->expect(Belt.Array.length(resolved.shots) > 0)->Expect.toBe(true)

    resolved.shots->Belt.Array.forEach(
      shot => {
        t->expect(Belt.Array.length(shot.animationSegments))->Expect.toEqual(0)
        t->expect(shot.pathData->Option.isSome)->Expect.toEqual(false)
        t->expect(shot.transitionOut->Option.isSome)->Expect.toEqual(false)
        t->expect(shot.waitBeforePanMs)->Expect.toEqual(1200)
        t->expect(shot.blinkAfterPanMs)->Expect.toEqual(0)
      },
    )
  })
})
