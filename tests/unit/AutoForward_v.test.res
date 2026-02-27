open Vitest
open Types

let makeHotspot = (~id: string, ~isAutoForward: option<bool>): hotspot => {
  linkId: id,
  yaw: 0.0,
  pitch: 0.0,
  target: "target",
  targetSceneId: None,
  targetYaw: None,
  targetPitch: None,
  targetHfov: None,
  startYaw: None,
  startPitch: None,
  startHfov: None,
  viewFrame: None,
  waypoints: None,
  displayPitch: None,
  transition: None,
  duration: None,
  isAutoForward,
}

let makeScene = (~id: string, ~hotspots: array<hotspot>): scene => {
  id,
  name: id ++ ".webp",
  file: Url(id ++ ".webp"),
  tinyFile: None,
  originalFile: None,
  hotspots,
  category: "default",
  floor: "ground",
  label: "",
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: false,
  labelSet: false,
  isAutoForward: false,
  sequenceId: 0,
}

describe("HotspotHelpers.canEnableAutoForward", () => {
  test("returns true when scene has no auto-forward links", t => {
    let scenes = [makeScene(~id="s1", ~hotspots=[makeHotspot(~id="h1", ~isAutoForward=None)])]
    t
    ->expect(HotspotHelpers.canEnableAutoForward(scenes, 0, 0))
    ->Expect.toBe(true)
  })

  test("returns false when another hotspot already has auto-forward", t => {
    let scenes = [
      makeScene(
        ~id="s1",
        ~hotspots=[
          makeHotspot(~id="h1", ~isAutoForward=Some(true)),
          makeHotspot(~id="h2", ~isAutoForward=None),
        ],
      ),
    ]
    t
    ->expect(HotspotHelpers.canEnableAutoForward(scenes, 0, 1))
    ->Expect.toBe(false)
  })

  test("returns true when current hotspot is already auto-forward (disable path)", t => {
    let scenes = [
      makeScene(
        ~id="s1",
        ~hotspots=[
          makeHotspot(~id="h1", ~isAutoForward=Some(true)),
          makeHotspot(~id="h2", ~isAutoForward=None),
        ],
      ),
    ]
    t
    ->expect(HotspotHelpers.canEnableAutoForward(scenes, 0, 0))
    ->Expect.toBe(true)
  })

  test("returns true when multiple hotspots exist but none are auto-forward", t => {
    let scenes = [
      makeScene(
        ~id="s1",
        ~hotspots=[
          makeHotspot(~id="h1", ~isAutoForward=None),
          makeHotspot(~id="h2", ~isAutoForward=Some(false)),
          makeHotspot(~id="h3", ~isAutoForward=None),
        ],
      ),
    ]
    t
    ->expect(HotspotHelpers.canEnableAutoForward(scenes, 0, 2))
    ->Expect.toBe(true)
  })

  test("returns true for empty hotspot list", t => {
    let scenes = [makeScene(~id="s1", ~hotspots=[])]
    t
    ->expect(HotspotHelpers.canEnableAutoForward(scenes, 0, 0))
    ->Expect.toBe(true)
  })
})
