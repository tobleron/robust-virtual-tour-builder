open Vitest
open TestUtils

let makeProjectedHotspot = (
  ~linkId: string,
  ~targetSceneId: option<string>,
  ~coords: option<Types.screenCoords>,
  ~isMovingThis=false,
): ReactHotspotLayer.projectedHotspot => {
  let baseHotspot = createMockHotspot(~id=linkId, ~target=targetSceneId->Option.getOr(""), ())
  {
    hotspot: {...baseHotspot, targetSceneId},
    hotspotIndex: 0,
    isMovingThis,
    coords,
    labelText: None,
    badge: None,
    targetSceneNumber: None,
    targetSceneId,
  }
}

describe("ReactHotspotLayer", () => {
  test("deriveDuplicateStackPlacements groups same-destination hotspots under the first anchor", t => {
    let placements = ReactHotspotLayer.deriveDuplicateStackPlacements([
      {linkId: "h1", targetSceneId: Some("scene-b")},
      {linkId: "h2", targetSceneId: Some("scene-b")},
      {linkId: "h3", targetSceneId: Some("scene-c")},
      {linkId: "h4", targetSceneId: Some("scene-b")},
      {linkId: "h5", targetSceneId: None},
    ])

    t
    ->expect(placements->Belt.Map.String.get("h1"))
    ->Expect.toEqual(Some({anchorLinkId: "h1", stackIndex: 0}))
    t
    ->expect(placements->Belt.Map.String.get("h2"))
    ->Expect.toEqual(Some({anchorLinkId: "h1", stackIndex: 1}))
    t
    ->expect(placements->Belt.Map.String.get("h4"))
    ->Expect.toEqual(Some({anchorLinkId: "h1", stackIndex: 2}))
    t
    ->expect(placements->Belt.Map.String.get("h3"))
    ->Expect.toEqual(Some({anchorLinkId: "h3", stackIndex: 0}))
    t->expect(placements->Belt.Map.String.get("h5"))->Expect.toEqual(None)
  })

  test("resolveStackedCoords reuses the anchor x/y for duplicate hotspots", t => {
    let anchor = makeProjectedHotspot(
      ~linkId="h1",
      ~targetSceneId=Some("scene-b"),
      ~coords=Some({x: 100.0, y: 200.0}),
    )
    let duplicate = makeProjectedHotspot(
      ~linkId="h2",
      ~targetSceneId=Some("scene-b"),
      ~coords=Some({x: 300.0, y: 400.0}),
    )
    let placements = ReactHotspotLayer.deriveDuplicateStackPlacements([
      {linkId: "h1", targetSceneId: Some("scene-b")},
      {linkId: "h2", targetSceneId: Some("scene-b")},
    ])
    let hotspotByLinkId = Belt.Map.String.fromArray([("h1", anchor), ("h2", duplicate)])

    t
    ->expect(ReactHotspotLayer.resolveStackedCoords(duplicate, placements, hotspotByLinkId))
    ->Expect.toEqual(Some({x: 100.0, y: 242.0}))
  })

  test("resolveStackedCoords preserves the active hotspot while it is being moved", t => {
    let anchor = makeProjectedHotspot(
      ~linkId="h1",
      ~targetSceneId=Some("scene-b"),
      ~coords=Some({x: 100.0, y: 200.0}),
    )
    let movingDuplicate = makeProjectedHotspot(
      ~linkId="h2",
      ~targetSceneId=Some("scene-b"),
      ~coords=Some({x: 300.0, y: 400.0}),
      ~isMovingThis=true,
    )
    let placements = ReactHotspotLayer.deriveDuplicateStackPlacements([
      {linkId: "h1", targetSceneId: Some("scene-b")},
      {linkId: "h2", targetSceneId: Some("scene-b")},
    ])
    let hotspotByLinkId = Belt.Map.String.fromArray([("h1", anchor), ("h2", movingDuplicate)])

    t
    ->expect(
      ReactHotspotLayer.resolveStackedCoords(movingDuplicate, placements, hotspotByLinkId),
    )
    ->Expect.toEqual(Some({x: 300.0, y: 400.0}))
  })

  test("duplicate labels stay hidden for non-anchor hotspots and hover restore delay stays explicit", t => {
    let anchor = makeProjectedHotspot(
      ~linkId="h1",
      ~targetSceneId=Some("scene-b"),
      ~coords=Some({x: 100.0, y: 200.0}),
    )
    let duplicate = makeProjectedHotspot(
      ~linkId="h2",
      ~targetSceneId=Some("scene-b"),
      ~coords=Some({x: 300.0, y: 400.0}),
    )
    let placements = ReactHotspotLayer.deriveDuplicateStackPlacements([
      {linkId: "h1", targetSceneId: Some("scene-b")},
      {linkId: "h2", targetSceneId: Some("scene-b")},
    ])

    t
    ->expect(ReactHotspotLayer.shouldShowHotspotLabel(anchor, placements, true))
    ->Expect.toBe(true)
    t
    ->expect(ReactHotspotLayer.shouldShowHotspotLabel(duplicate, placements, true))
    ->Expect.toBe(false)
    t
    ->expect(ReactHotspotLayer.shouldShowHotspotLabel(anchor, placements, false))
    ->Expect.toBe(false)
    t
    ->expect(ReactHotspotLayer.resolveDuplicateGroupAnchorLinkId("h2", placements))
    ->Expect.toBe("h1")
    t
    ->expect(ReactHotspotLayer.resolveDuplicateGroupAnchorLinkId("orphan", placements))
    ->Expect.toBe("orphan")
    t->expect(ReactHotspotLayer.duplicateStackRestoreDelayMs)->Expect.toBe(240)
  })
})
