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

describe("VisualPipelineRouter", () => {
  test("compute generates orthogonal connector paths", t => {
    let s1 = makeScene(~id="s1", ~name="S1", ())
    let s2 = makeScene(~id="s2", ~name="S2", ())
    let scenes = [{...s1, hotspots: [makeHotspot(~linkId="h1", ~targetSceneId="s2", ())]}, s2]
    let timeline = [item(~id="t1", ~sceneId="s1", ~linkId="h1", ~targetScene="s2", ())]
    let graph = VisualPipelineGraph.build(~scenes, ~timeline)
    let layout = VisualPipelineLayout.compute(~graph, ())
    let routed = VisualPipelineRouter.compute(~graph, ~layout).routedEdges

    t->expect(Belt.Array.length(routed))->Expect.toBe(1)
    t
    ->expect(routed[0]->Option.map(edge => String.length(edge.path) > 0))
    ->Expect.toEqual(Some(true))
  })

  test("return routes to same target share trunk lane", t => {
    let s1 = makeScene(~id="s1", ~name="Hub", ())
    let s2 = makeScene(~id="s2", ~name="Room A", ())
    let s3 = makeScene(~id="s3", ~name="Room B", ())
    let scenes = [
      {
        ...s1,
        hotspots: [
          makeHotspot(~linkId="to-a", ~targetSceneId="s2", ()),
          makeHotspot(~linkId="to-b", ~targetSceneId="s3", ()),
        ],
      },
      {...s2, hotspots: [makeHotspot(~linkId="back-a", ~targetSceneId="s1", ())]},
      {...s3, hotspots: [makeHotspot(~linkId="back-b", ~targetSceneId="s1", ())]},
    ]
    let timeline = [
      item(~id="t1", ~sceneId="s1", ~linkId="to-a", ~targetScene="s2", ()),
      item(~id="t2", ~sceneId="s1", ~linkId="to-b", ~targetScene="s3", ()),
      item(~id="t3", ~sceneId="s2", ~linkId="back-a", ~targetScene="s1", ()),
      item(~id="t4", ~sceneId="s3", ~linkId="back-b", ~targetScene="s1", ()),
    ]
    let graph = VisualPipelineGraph.build(~scenes, ~timeline)
    let layout = VisualPipelineLayout.compute(~graph, ())
    let routed = VisualPipelineRouter.compute(~graph, ~layout).routedEdges

    let returnRoutes = routed->Belt.Array.keep(
      edge =>
        switch edge.kind {
        | VisualPipelineGraph.Return => true
        | _ => false
        },
    )
    t->expect(Belt.Array.length(returnRoutes) >= 2)->Expect.toBe(true)

    let firstLaneKey = returnRoutes->Belt.Array.get(0)->Option.map(edge => edge.laneKey)
    let secondLaneKey = returnRoutes->Belt.Array.get(1)->Option.map(edge => edge.laneKey)
    t->expect(firstLaneKey)->Expect.toEqual(secondLaneKey)
  })
})
