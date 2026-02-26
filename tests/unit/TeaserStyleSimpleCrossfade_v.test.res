open Vitest
open Types

let makeLinkHotspot = (): hotspot => {
  linkId: "h1",
  yaw: 8.0,
  pitch: -2.0,
  target: "scene-2",
  targetSceneId: Some("scene-2"),
  targetYaw: Some(40.0),
  targetPitch: Some(-6.0),
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
}

describe("TeaserStyleSimpleCrossfade", () => {
  test("buildManifest creates static endpoint shots with short crossfades", t => {
    let s1 = TestUtils.createMockScene(
      ~id="scene-1",
      ~name="Scene 1",
      ~hotspots=[makeLinkHotspot()],
      (),
    )
    let s2 = TestUtils.createMockScene(~id="scene-2", ~name="Scene 2", ())
    let state = TestUtils.createMockState(~scenes=[s1, s2], ~activeIndex=0, ())

    let manifest = TeaserStyleSimpleCrossfade.buildManifest(
      state,
      ~skipAutoForward=false,
      ~includeIntroPan=false,
    )

    t->expect(manifest->Result.isOk)->Expect.toBe(true)
    let resolved = manifest->Result.getOrThrow
    let count = Belt.Array.length(resolved.shots)
    t->expect(count > 0)->Expect.toBe(true)

    resolved.shots->Belt.Array.forEach(
      shot => {
        t->expect(Belt.Array.length(shot.animationSegments))->Expect.toEqual(0)
        t->expect(shot.pathData->Option.isSome)->Expect.toEqual(false)
        t->expect(shot.waitBeforePanMs)->Expect.toEqual(1800)
        t->expect(shot.blinkAfterPanMs)->Expect.toEqual(0)
      },
    )

    if count > 1 {
      let first = resolved.shots[0]->Option.getOrThrow
      t->expect(first.transitionOut->Option.isSome)->Expect.toEqual(true)
      switch first.transitionOut {
      | Some(transition) =>
        t->expect(transition.type_)->Expect.toEqual("crossfade")
        t->expect(transition.durationMs)->Expect.toEqual(900)
      | None => t->expect(false)->Expect.toBe(true)
      }
    }

    let last = resolved.shots[count - 1]->Option.getOrThrow
    t->expect(last.transitionOut->Option.isSome)->Expect.toEqual(false)
  })
})
