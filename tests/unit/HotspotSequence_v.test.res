open Vitest
open Types

let makeHotspot = (
  ~linkId: string,
  ~targetSceneId: string,
  ~sequenceOrder: option<int>=None,
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
  isAutoForward: None,
  sequenceOrder,
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

let makeGraphState = (~manual=false, ()) => {
  let hAB = makeHotspot(
    ~linkId="hAB",
    ~targetSceneId="B",
    ~sequenceOrder=manual ? Some(2) : None,
    (),
  )
  let hBC = makeHotspot(
    ~linkId="hBC",
    ~targetSceneId="C",
    ~sequenceOrder=manual ? Some(1) : None,
    (),
  )
  let hBA = makeHotspot(~linkId="hBA", ~targetSceneId="A", ())
  let hCB = makeHotspot(~linkId="hCB", ~targetSceneId="B", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
  let sceneB = makeScene(~id="B", ~hotspots=[hBC, hBA], ())
  let sceneC = makeScene(~id="C", ~hotspots=[hCB], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ~activeIndex=0, ())
}

let makeDisconnectedState = () => {
  let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
  let hCD = makeHotspot(~linkId="hCD", ~targetSceneId="D", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
  let sceneB = makeScene(~id="B", ~hotspots=[], ())
  let sceneC = makeScene(~id="C", ~hotspots=[hCD], ())
  let sceneD = makeScene(~id="D", ~hotspots=[], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC, sceneD], ~activeIndex=0, ())
}

let makeParentBacklinkState = () => {
  let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
  let hBC = makeHotspot(~linkId="hBC", ~targetSceneId="C", ())
  let hBA = makeHotspot(~linkId="hBA", ~targetSceneId="A", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
  let sceneB = makeScene(~id="B", ~hotspots=[hBC, hBA], ())
  let sceneC = makeScene(~id="C", ~hotspots=[], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ~activeIndex=0, ())
}

let makeMultiForwardInboundReturnState = () => {
  let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
  let hAC = makeHotspot(~linkId="hAC", ~targetSceneId="C", ())
  let hBD = makeHotspot(~linkId="hBD", ~targetSceneId="D", ())
  let hCE = makeHotspot(~linkId="hCE", ~targetSceneId="E", ())
  let hED = makeHotspot(~linkId="hED", ~targetSceneId="D", ())
  let hDA = makeHotspot(~linkId="hDA", ~targetSceneId="A", ())
  let hDB = makeHotspot(~linkId="hDB", ~targetSceneId="B", ())
  let hDE = makeHotspot(~linkId="hDE", ~targetSceneId="E", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB, hAC], ())
  let sceneB = makeScene(~id="B", ~hotspots=[hBD], ())
  let sceneC = makeScene(~id="C", ~hotspots=[hCE], ())
  let sceneD = makeScene(~id="D", ~hotspots=[hDA, hDB, hDE], ())
  let sceneE = makeScene(~id="E", ~hotspots=[hED], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC, sceneD, sceneE], ~activeIndex=0, ())
}

let makeAutoForwardUnvisitedReturnState = () => {
  let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
  let hBA = makeHotspot(~linkId="hBA", ~targetSceneId="A", ())
  let hBC = {
    ...makeHotspot(~linkId="hBC", ~targetSceneId="C", ()),
    isAutoForward: Some(true),
  }
  let hCB = makeHotspot(~linkId="hCB", ~targetSceneId="B", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB], ())
  // Keep return-first order so traversal can end before visiting C.
  let sceneB = makeScene(~id="B", ~hotspots=[hBA, hBC], ())
  let sceneC = makeScene(~id="C", ~hotspots=[hCB], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ~activeIndex=0, ())
}

let makeMasterBalconyReturnState = () => {
  let hHM = makeHotspot(~linkId="hHM", ~targetSceneId="master", ())
  let hMH = {
    ...makeHotspot(~linkId="hMH", ~targetSceneId="hub", ()),
    isAutoForward: Some(true),
  }
  let hMB = makeHotspot(~linkId="hMB", ~targetSceneId="balcony", ())
  let hBM = {
    ...makeHotspot(~linkId="hBM", ~targetSceneId="master", ()),
    isAutoForward: Some(true),
  }

  let hub = makeScene(~id="hub", ~hotspots=[hHM], ())
  let master = makeScene(~id="master", ~hotspots=[hMB, hMH], ())
  let balcony = makeScene(~id="balcony", ~hotspots=[hBM], ())

  TestUtils.createMockState(~scenes=[hub, master, balcony], ~activeIndex=0, ())
}

let makeThreeManualForwardState = () => {
  let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ~sequenceOrder=Some(3), ())
  let hAC = makeHotspot(~linkId="hAC", ~targetSceneId="C", ~sequenceOrder=Some(1), ())
  let hAD = makeHotspot(~linkId="hAD", ~targetSceneId="D", ~sequenceOrder=Some(2), ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB, hAC, hAD], ())
  let sceneB = makeScene(~id="B", ~hotspots=[], ())
  let sceneC = makeScene(~id="C", ~hotspots=[], ())
  let sceneD = makeScene(~id="D", ~hotspots=[], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC, sceneD], ~activeIndex=0, ())
}

let makeAdmissibleOrderState = () => {
  let hAB = makeHotspot(~linkId="hAB", ~targetSceneId="B", ())
  let hAD = makeHotspot(~linkId="hAD", ~targetSceneId="D", ())
  let hBC = makeHotspot(~linkId="hBC", ~targetSceneId="C", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB, hAD], ())
  let sceneB = makeScene(~id="B", ~hotspots=[hBC], ())
  let sceneC = makeScene(~id="C", ~hotspots=[], ())
  let sceneD = makeScene(~id="D", ~hotspots=[], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC, sceneD], ~activeIndex=0, ())
}

let makeAutoForwardOrderingState = () => {
  let hAB = {
    ...makeHotspot(~linkId="hAB", ~targetSceneId="B", ()),
    isAutoForward: Some(true),
  }
  let hAC = makeHotspot(~linkId="hAC", ~targetSceneId="C", ())

  let sceneA = makeScene(~id="A", ~hotspots=[hAB, hAC], ())
  let sceneB = makeScene(~id="B", ~hotspots=[], ())
  let sceneC = makeScene(~id="C", ~hotspots=[], ())

  TestUtils.createMockState(~scenes=[sceneA, sceneB, sceneC], ~activeIndex=0, ())
}

let readSeq = (badges: Belt.Map.String.t<HotspotSequence.badgeKind>, linkId: string): option<int> =>
  switch badges->Belt.Map.String.get(linkId) {
  | Some(HotspotSequence.Sequence(n)) => Some(n)
  | _ => None
  }

let isReturn = (badges: Belt.Map.String.t<HotspotSequence.badgeKind>, linkId: string): bool =>
  switch badges->Belt.Map.String.get(linkId) {
  | Some(HotspotSequence.Return) => true
  | _ => false
  }

describe("HotspotSequence", () => {
  test("deriveBadgeByLinkId marks return edges as R", t => {
    let state = makeGraphState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(readSeq(badges, "hAB"))->Expect.toEqual(Some(1))
    t->expect(readSeq(badges, "hBC"))->Expect.toEqual(Some(2))
    t->expect(isReturn(badges, "hCB"))->Expect.toBe(true)
    t->expect(isReturn(badges, "hBA"))->Expect.toBe(true)
  })

  test("manual sequence order is honored when valid", t => {
    let state = makeGraphState(~manual=true, ())
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(readSeq(badges, "hAB"))->Expect.toEqual(Some(2))
    t->expect(readSeq(badges, "hBC"))->Expect.toEqual(Some(1))
    t->expect(isReturn(badges, "hCB"))->Expect.toBe(true)
    t->expect(isReturn(badges, "hBA"))->Expect.toBe(true)
  })

  test("ordered hotspot list excludes return edges", t => {
    let state = makeGraphState()
    let ordered = HotspotSequence.deriveOrderedHotspots(~state)
    let linkIds = ordered->Belt.Array.map(x => x.linkId)

    t->expect(linkIds)->Expect.toEqual(["hAB", "hBC"])
  })

  test("buildReorderUpdates ignores return links", t => {
    let state = makeGraphState()
    let updates = HotspotSequence.buildReorderUpdates(~state, ~linkId="hBA", ~desiredOrder=1)

    t->expect(updates->Belt.Array.length)->Expect.toBe(0)
  })

  test("numbers forward hotspots even when traversal does not reach their scenes", t => {
    let state = makeDisconnectedState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(readSeq(badges, "hAB"))->Expect.toEqual(Some(1))
    t->expect(readSeq(badges, "hCD"))->Expect.toEqual(Some(2))
  })

  test("marks parent-back links as R even when not traversed", t => {
    let state = makeParentBacklinkState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(readSeq(badges, "hAB"))->Expect.toEqual(Some(1))
    t->expect(readSeq(badges, "hBC"))->Expect.toEqual(Some(2))
    t->expect(isReturn(badges, "hBA"))->Expect.toBe(true)
  })

  test("marks only first-parent backlink as return in multi-inbound graph", t => {
    let state = makeMultiForwardInboundReturnState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(isReturn(badges, "hDB"))->Expect.toBe(true)
    t->expect(isReturn(badges, "hDE"))->Expect.toBe(false)
  })

  test("marks unvisited auto-forward target back-link as Return", t => {
    let state = makeAutoForwardUnvisitedReturnState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(readSeq(badges, "hAB"))->Expect.toEqual(Some(1))
    t->expect(isReturn(badges, "hBA"))->Expect.toBe(true)
    t->expect(isReturn(badges, "hCB"))->Expect.toBe(true)
    t->expect(readSeq(badges, "hCB"))->Expect.toEqual(None)
  })

  test("keeps forward links sequenced and marks only direct back-links as Return", t => {
    let state = makeMasterBalconyReturnState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(isReturn(badges, "hHM"))->Expect.toBe(false)
    t->expect(isReturn(badges, "hMB"))->Expect.toBe(false)
    t->expect(isReturn(badges, "hBM"))->Expect.toBe(true)
    t->expect(isReturn(badges, "hMH"))->Expect.toBe(true)
    t->expect(readSeq(badges, "hHM"))->Expect.toEqual(Some(1))
    t->expect(readSeq(badges, "hMB"))->Expect.toEqual(Some(2))
  })

  test("keeps all-manual sequence ordering stable for 3+ hotspots", t => {
    let state = makeThreeManualForwardState()
    let badges = HotspotSequence.deriveBadgeByLinkId(~state)

    t->expect(readSeq(badges, "hAC"))->Expect.toEqual(Some(1))
    t->expect(readSeq(badges, "hAD"))->Expect.toEqual(Some(2))
    t->expect(readSeq(badges, "hAB"))->Expect.toEqual(Some(3))
  })

  test("buildReorderUpdates keeps selected link at requested order in all-manual mode", t => {
    let state = makeThreeManualForwardState()
    let updates = HotspotSequence.buildReorderUpdates(~state, ~linkId="hAB", ~desiredOrder=1)

    let selected = updates->Belt.Array.getBy(update => update.linkId == "hAB")
    let ordered =
      updates
      ->Belt.Array.map(update => update.sequenceOrder)
      ->Belt.SortArray.stableSortBy((a, b) => a - b)

    t->expect(selected->Option.map(x => x.sequenceOrder))->Expect.toEqual(Some(1))
    t->expect(ordered)->Expect.toEqual([1, 2, 3])
  })

  test("deriveAdmissibleOrders allows moving links earlier and later", t => {
    let state = makeAdmissibleOrderState()
    let admissibleForHBC = HotspotSequence.deriveAdmissibleOrders(~state, ~linkId="hBC")

    t->expect(admissibleForHBC->Belt.Array.some(order => order == 1))->Expect.toBe(true)
    t->expect(admissibleForHBC->Belt.Array.some(order => order >= 2))->Expect.toBe(true)
  })

  test("deriveAdmissibleOrders always includes the current sequence position", t => {
    let state = makeAdmissibleOrderState()
    let display = HotspotSequence.deriveDisplayOrder(~state)
    let current = display->Belt.Map.String.get("hAB")->Option.getOr(0)
    let admissible = HotspotSequence.deriveAdmissibleOrders(~state, ~linkId="hAB")

    t->expect(current > 0)->Expect.toBe(true)
    t->expect(admissible->Belt.Array.some(order => order == current))->Expect.toBe(true)
  })

  test("deriveAdmissibleOrders blocks auto-forward from preceding non-auto in same scene", t => {
    let state = makeAutoForwardOrderingState()
    let admissibleAuto = HotspotSequence.deriveAdmissibleOrders(~state, ~linkId="hAB")

    t->expect(admissibleAuto->Belt.Array.some(order => order == 1))->Expect.toBe(false)
    t->expect(admissibleAuto->Belt.Array.some(order => order == 2))->Expect.toBe(true)
  })
})
