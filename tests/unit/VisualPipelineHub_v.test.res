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
  sequenceOrder: None,
}

let makeScene = (~id: string, ~name: string, ()): scene => {
  id,
  name,
  label: "",
  file: Url(""),
  tinyFile: None,
  originalFile: None,
  hotspots: [dummyHotspot(id)],
  category: "",
  floor: "ground",
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: false,
  labelSet: false,
  isAutoForward: false,
  sequenceId: 0,
}

let makeHotspot = (~linkId: string, ~targetSceneId: string, ()): hotspot => {
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
  isAutoForward: None,
  sequenceOrder: None,
}

let item = (~id, ~sceneId, ~linkId, ~targetScene="", ()) => {
  id,
  sceneId,
  linkId,
  targetScene,
  transition: "cut",
  duration: 0,
}

describe("VisualPipelineHub", () => {
  test("detect marks scene as hub when it has two unique outgoing targets", t => {
    let s1 = makeScene(~id="s1", ~name="Hub", ())
    let s2 = makeScene(~id="s2", ~name="Room A", ())
    let s3 = makeScene(~id="s3", ~name="Room B", ())
    let scenes = [
      {
        ...s1,
        hotspots: [
          makeHotspot(~linkId="a", ~targetSceneId="s2", ()),
          makeHotspot(~linkId="b", ~targetSceneId="s3", ()),
        ],
      },
      s2,
      s3,
    ]
    let timeline = [
      item(~id="t1", ~sceneId="s1", ~linkId="a", ~targetScene="s2", ()),
      item(~id="t2", ~sceneId="s1", ~linkId="b", ~targetScene="s3", ()),
    ]
    let graph = VisualPipelineGraph.build(~scenes, ~timeline)
    let hubInfo = VisualPipelineHub.getInfo(VisualPipelineHub.detect(graph), "s1")

    t->expect(hubInfo.isHub)->Expect.toBe(true)
    t->expect(hubInfo.branchCount)->Expect.toBe(2)
  })
})
