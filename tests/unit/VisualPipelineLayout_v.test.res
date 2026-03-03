open Vitest
open Types

let dummyHotspot = (sceneId: string): hotspot => {
  linkId: "self_" ++ sceneId,
  yaw: 0.0,
  pitch: 0.0,
  target: "",
  targetSceneId: Some(sceneId),
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
  isAutoForward: None,
}

let makeScene = (~id: string, ~name: string, ~floor: string, ()): scene => {
  id,
  name,
  label: "",
  file: Url(""),
  tinyFile: None,
  originalFile: None,
  hotspots: [dummyHotspot(id)],
  category: "",
  floor,
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: false,
  labelSet: false,
  isAutoForward: false,
  sequenceId: 0,
}

let item = (~id, ~sceneId, ~linkId, ~targetScene="", ()) => {
  id,
  sceneId,
  linkId,
  targetScene,
  transition: "cut",
  duration: 0,
}

describe("VisualPipelineLayout", () => {
  test("compute preserves floor row ordering", t => {
    let scenes = [
      makeScene(~id="s1", ~name="Ground", ~floor="ground", ()),
      makeScene(~id="s2", ~name="First", ~floor="first", ()),
    ]
    let timeline = [item(~id="t1", ~sceneId="s1", ~linkId="h1", ~targetScene="s2", ())]
    let graph = VisualPipelineGraph.build(~scenes, ~timeline)
    let layout = VisualPipelineLayout.compute(~graph, ())

    let yGround =
      VisualPipelineLayout.getPoint(layout, "scene_s1")
      ->Option.map(point => point.y)
      ->Option.getOr(0.0)
    let yFirst = VisualPipelineLayout.getPoint(layout, "scene_s2")->Option.map(point => point.y)->Option.getOr(0.0)
    t->expect(yGround > yFirst)->Expect.toBe(true)
  })

  test("compute is deterministic for same graph input", t => {
    let scenes = [
      makeScene(~id="s1", ~name="S1", ~floor="ground", ()),
      makeScene(~id="s2", ~name="S2", ~floor="ground", ()),
    ]
    let timeline = [item(~id="t1", ~sceneId="s1", ~linkId="h1", ~targetScene="s2", ())]
    let graph = VisualPipelineGraph.build(~scenes, ~timeline)

    let a = VisualPipelineLayout.compute(~graph, ())
    let b = VisualPipelineLayout.compute(~graph, ())
    let pointA = VisualPipelineLayout.getPoint(a, "scene_s2")
    let pointB = VisualPipelineLayout.getPoint(b, "scene_s2")
    t->expect(pointA)->Expect.toEqual(pointB)
  })
})
