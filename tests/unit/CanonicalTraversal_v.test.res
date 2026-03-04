open Vitest
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
  category: "indoor",
  floor: "ground",
  label: id,
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: true,
  labelSet: true,
  isAutoForward: false,
  sequenceId: 0,
}

describe("CanonicalTraversal", () => {
  test("marks parent backlink as Return and keeps forward links sequenced", t => {
    let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
    let hBA = makeHotspot(~linkId="hBA", ~targetSceneId="A", ())
    let hBC = makeHotspot(~linkId="hBC", ~targetSceneId="C", ())

    let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
    let sceneB = makeScene(~id="B", ~hotspots=[hBA, hBC], ())
    let sceneC = makeScene(~id="C", ~hotspots=[], ())

    let state = TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ~activeIndex=0, ())
    let model = CanonicalTraversal.derive(~state)

    t->expect(model.displayOrderByLinkId->Belt.Map.String.get("hAB"))->Expect.toEqual(Some(1))
    t
    ->expect(model.badgeByLinkId->Belt.Map.String.get("hBA"))
    ->Expect.toEqual(Some(CanonicalTraversal.Return))
    t->expect(model.displayOrderByLinkId->Belt.Map.String.get("hBC"))->Expect.toEqual(Some(2))
  })

  test("admissible orders keep auto-forward links behind non-auto links in same scene", t => {
    let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ~isAutoForward=Some(true), ())
    let hAC = makeHotspot(~linkId="hAC", ~targetSceneId="C", ())

    let sceneA = makeScene(~id="A", ~hotspots=[hAB, hAC], ())
    let sceneB = makeScene(~id="B", ~hotspots=[], ())
    let sceneC = makeScene(~id="C", ~hotspots=[], ())

    let state = TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ~activeIndex=0, ())
    let admissibleAuto = CanonicalTraversal.deriveAdmissibleOrders(~state, ~linkId="hAB")

    t->expect(admissibleAuto->Belt.Array.some(order => order == 1))->Expect.toBe(false)
    t->expect(admissibleAuto->Belt.Array.some(order => order == 2))->Expect.toBe(true)
  })
})
