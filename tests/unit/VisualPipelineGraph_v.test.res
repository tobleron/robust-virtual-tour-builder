open Vitest
open Types

let makeHotspot = (~linkId: string, ~targetSceneId: option<string>, ()): hotspot => {
  linkId,
  yaw: 0.0,
  pitch: 0.0,
  target: "",
  targetSceneId,
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

let makeScene = (
  ~id: string,
  ~name: string,
  ~floor: string="ground",
  ~hotspots: array<hotspot>=[],
  (),
): scene => {
  let effectiveHotspots = if Belt.Array.length(hotspots) > 0 {
    hotspots
  } else {
    [makeHotspot(~linkId="self_" ++ id, ~targetSceneId=Some(id), ())]
  }

  {
    id,
    name,
    label: "",
    file: Url(""),
    tinyFile: None,
    originalFile: None,
    hotspots: effectiveHotspots,
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
}

let makeTimelineItem = (
  ~id: string,
  ~sceneId: string,
  ~linkId: string,
  ~targetScene: string="",
  (),
): timelineItem => {
  id,
  sceneId,
  linkId,
  targetScene,
  transition: "cut",
  duration: 0,
}

describe("VisualPipelineGraph", () => {
  test("build includes unique scene nodes and scene-to-scene edge", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Entrance",
      ~hotspots=[makeHotspot(~linkId="h1", ~targetSceneId=Some("s2"), ())],
      (),
    )
    let s2 = makeScene(~id="s2", ~name="Hall", ())
    let timeline = [makeTimelineItem(~id="t1", ~sceneId="s1", ~linkId="h1", ~targetScene="s2", ())]
    let graph = VisualPipelineGraph.build(~scenes=[s1, s2], ~timeline)

    t->expect(Belt.Array.length(graph.nodes))->Expect.toBe(2)
    t->expect(graph.nodes[0]->Option.map(n => n.id))->Expect.toEqual(Some("scene_s1"))
    t->expect(Belt.Array.length(graph.edges))->Expect.toBe(1)
  })

  test("build keeps a single edge per scene pair when timeline and hotspots overlap", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Hub",
      ~hotspots=[
        makeHotspot(~linkId="h1", ~targetSceneId=Some("s2"), ()),
        makeHotspot(~linkId="h2", ~targetSceneId=Some("s1"), ()),
      ],
      (),
    )
    let s2 = makeScene(~id="s2", ~name="Room", ())
    let timeline = [
      makeTimelineItem(~id="t1", ~sceneId="s1", ~linkId="h1", ()),
      makeTimelineItem(~id="t2", ~sceneId="s1", ~linkId="h2", ()),
    ]
    let graph = VisualPipelineGraph.build(~scenes=[s1, s2], ~timeline)

    let s1ToS2Count =
      graph.edges
      ->Belt.Array.keep(edge => edge.fromSceneId == "s1" && edge.toSceneId == "s2")
      ->Belt.Array.length
    t->expect(s1ToS2Count)->Expect.toBe(1)
  })

  test("build prefers canonical simulation traversal ordering over timeline-only ordering", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Hub",
      ~hotspots=[
        makeHotspot(~linkId="to_s2", ~targetSceneId=Some("s2"), ()),
        makeHotspot(~linkId="to_s3", ~targetSceneId=Some("s3"), ()),
      ],
      (),
    )
    let s2 = makeScene(
      ~id="s2",
      ~name="Room A",
      ~hotspots=[makeHotspot(~linkId="back_s1_a", ~targetSceneId=Some("s1"), ())],
      (),
    )
    let s3 = makeScene(
      ~id="s3",
      ~name="Room B",
      ~hotspots=[makeHotspot(~linkId="back_s1_b", ~targetSceneId=Some("s1"), ())],
      (),
    )
    let timeline = [
      makeTimelineItem(~id="t1", ~sceneId="s1", ~linkId="to_s3", ~targetScene="s3", ()),
    ]
    let state = TestUtils.createMockState(~scenes=[s1, s2, s3], ~activeIndex=0, ())
    let traversal = VisualPipelineGraph.deriveTraversal(~state)
    let graph = VisualPipelineGraph.build(
      ~scenes=[s1, s2, s3],
      ~timeline,
      ~traversal=Some(traversal),
    )

    let orderedSceneIds = graph.nodes->Belt.Array.map(node => node.representedSceneId)
    t->expect(orderedSceneIds)->Expect.toEqual(["s1", "s2", "s3"])
  })

  test("build ignores timeline edge when source hotspot link no longer exists", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Start",
      ~hotspots=[makeHotspot(~linkId="real", ~targetSceneId=Some("s2"), ())],
      (),
    )
    let s2 = makeScene(~id="s2", ~name="ValidTarget", ())
    let s3 = makeScene(~id="s3", ~name="GhostTarget", ())
    let timeline = [
      makeTimelineItem(~id="valid", ~sceneId="s1", ~linkId="real", ~targetScene="s2", ()),
      makeTimelineItem(~id="stale", ~sceneId="s1", ~linkId="deleted_link", ~targetScene="s3", ()),
    ]

    let graph = VisualPipelineGraph.build(~scenes=[s1, s2, s3], ~timeline)
    let hasGhostEdge =
      graph.edges->Belt.Array.some(edge => edge.fromSceneId == "s1" && edge.toSceneId == "s3")
    t->expect(hasGhostEdge)->Expect.toBe(false)
  })
})
