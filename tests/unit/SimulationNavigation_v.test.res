// @efficiency: infra-adapter
open Vitest
open Simulation.Navigation
open Types

let makeHotspot = (
  ~linkId: string,
  ~targetSceneId: string,
  ~isAutoForward: option<bool>=None,
  (),
): hotspot => {
  linkId,
  yaw: 0.0,
  pitch: 0.0,
  target: targetSceneId,
  targetSceneId: Some(targetSceneId),
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
  sequenceOrder: None,
}

let makeScene = (~id: string, ~hotspots: array<hotspot>, ()): scene => {
  id,
  name: id,
  file: Url(id ++ ".webp"),
  tinyFile: None,
  originalFile: None,
  hotspots,
  category: "",
  floor: "",
  label: "",
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: false,
  labelSet: false,
  isAutoForward: false,
  sequenceId: 0,
}

describe("SimulationNavigation", () => {
  test("prefers non-return forward links before return links", t => {
    let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
    let hBA = makeHotspot(~linkId="hBA", ~targetSceneId="A", ())
    let hBC = makeHotspot(~linkId="hBC", ~targetSceneId="C", ~isAutoForward=Some(true), ())

    let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
    let sceneB = makeScene(~id="B", ~hotspots=[hBA, hBC], ())
    let sceneC = makeScene(~id="C", ~hotspots=[], ())

    let state = TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ())

    switch findBestNextLinkByLinkId(sceneB, state, ["hAB"]) {
    | Some(link) => t->expect(link.hotspot.linkId)->Expect.toBe("hBC")
    | None => t->expect("Some")->Expect.toBe("None")
    }
  })

  test("falls back to return link when forward links are exhausted", t => {
    let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
    let hBA = makeHotspot(~linkId="hBA", ~targetSceneId="A", ())
    let hBC = makeHotspot(~linkId="hBC", ~targetSceneId="C", ~isAutoForward=Some(true), ())

    let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
    let sceneB = makeScene(~id="B", ~hotspots=[hBA, hBC], ())
    let sceneC = makeScene(~id="C", ~hotspots=[], ())

    let state = TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ())

    switch findBestNextLinkByLinkId(sceneB, state, ["hAB", "hBC"]) {
    | Some(link) => t->expect(link.hotspot.linkId)->Expect.toBe("hBA")
    | None => t->expect("Some")->Expect.toBe("None")
    }
  })

  test("handles empty hotspots", t => {
    let sceneA = makeScene(~id="A", ~hotspots=[], ())
    let state = TestUtils.createMockState(~scenes=[sceneA], ())

    switch findBestNextLinkByLinkId(sceneA, state, []) {
    | None => t->expect(true)->Expect.toBe(true)
    | Some(_) => t->expect(false)->Expect.toBe(true)
    }
  })
})
