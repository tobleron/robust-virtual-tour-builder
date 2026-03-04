open Vitest
open Types

let makeHotspot = (
  ~linkId: string,
  ~targetSceneId: option<string>,
  ~isAutoForward=false,
  (),
): hotspot => {
  linkId,
  yaw: 0.0,
  pitch: 0.0,
  target: targetSceneId->Option.getOr(""),
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
  isAutoForward: isAutoForward ? Some(true) : None,
  sequenceOrder: None,
}

let makeScene = (~id: string, ~name: string, ~hotspots: array<hotspot>=[], ()): scene => {
  id,
  name,
  file: Url(""),
  tinyFile: None,
  originalFile: None,
  hotspots,
  category: "room",
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

describe("TraversalSequence", () => {
  test("assigns global sequence numbers along linear traversal", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Entrance",
      ~hotspots=[makeHotspot(~linkId="h1", ~targetSceneId=Some("s2"), ())],
      (),
    )
    let s2 = makeScene(
      ~id="s2",
      ~name="Hall",
      ~hotspots=[makeHotspot(~linkId="h2", ~targetSceneId=Some("s3"), ())],
      (),
    )
    let s3 = makeScene(~id="s3", ~name="Room", ())

    let state = TestUtils.createMockState(
      ~scenes=[s1, s2, s3],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let seq = TraversalSequence.deriveLinkSequence(~state)
    t->expect(seq->Belt.Map.String.get("h1"))->Expect.toEqual(Some(1))
    t->expect(seq->Belt.Map.String.get("h2"))->Expect.toEqual(Some(2))
  })

  test("keeps auto-forward links after non-auto-forward links in scene priority", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Hub",
      ~hotspots=[
        makeHotspot(~linkId="to_s2", ~targetSceneId=Some("s2"), ()),
        makeHotspot(~linkId="to_s3_af", ~targetSceneId=Some("s3"), ~isAutoForward=true, ()),
      ],
      (),
    )
    let s2 = makeScene(
      ~id="s2",
      ~name="Branch A",
      ~hotspots=[makeHotspot(~linkId="back_s1_a", ~targetSceneId=Some("s1"), ())],
      (),
    )
    let s3 = makeScene(
      ~id="s3",
      ~name="Branch B",
      ~hotspots=[makeHotspot(~linkId="back_s1_b", ~targetSceneId=Some("s1"), ())],
      (),
    )

    let state = TestUtils.createMockState(
      ~scenes=[s1, s2, s3],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let seq = TraversalSequence.deriveLinkSequence(~state)
    t->expect(seq->Belt.Map.String.get("to_s2"))->Expect.toEqual(Some(1))
    t->expect(seq->Belt.Map.String.get("back_s1_a"))->Expect.toEqual(Some(2))
    t->expect(seq->Belt.Map.String.get("to_s3_af"))->Expect.toEqual(Some(3))
  })

  test("starts sequencing from home scene regardless of current active scene", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="Start",
      ~hotspots=[makeHotspot(~linkId="start_link", ~targetSceneId=Some("s2"), ())],
      (),
    )
    let s2 = makeScene(~id="s2", ~name="Middle", ())
    let s3 = makeScene(~id="s3", ~name="IrrelevantActive", ())

    let state = TestUtils.createMockState(
      ~scenes=[s1, s2, s3],
      ~activeIndex=2,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let seq = TraversalSequence.deriveLinkSequence(~state)
    t->expect(seq->Belt.Map.String.get("start_link"))->Expect.toEqual(Some(1))
  })

  test("does not duplicate sequence entries when revisiting scenes", t => {
    let s1 = makeScene(
      ~id="s1",
      ~name="A",
      ~hotspots=[makeHotspot(~linkId="a_to_b", ~targetSceneId=Some("s2"), ())],
      (),
    )
    let s2 = makeScene(
      ~id="s2",
      ~name="B",
      ~hotspots=[makeHotspot(~linkId="b_to_a", ~targetSceneId=Some("s1"), ())],
      (),
    )

    let state = TestUtils.createMockState(
      ~scenes=[s1, s2],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let seq = TraversalSequence.deriveLinkSequence(~state)
    let total = seq->Belt.Map.String.toArray->Belt.Array.length
    t->expect(total)->Expect.toBe(2)
    t->expect(seq->Belt.Map.String.get("a_to_b"))->Expect.toEqual(Some(1))
    t->expect(seq->Belt.Map.String.get("b_to_a"))->Expect.toEqual(Some(2))
  })
})
