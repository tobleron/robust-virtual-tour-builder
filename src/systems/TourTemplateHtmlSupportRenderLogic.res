let resolveAutoForwardHotspotIndex = (rawHotspots: array<TourData.hotspotData>, hasSceneId: string => bool) => {
  let autoForwardHotspotIndex = rawHotspots->Belt.Array.getIndexBy(h =>
    h["targetIsAutoForward"] == true && hasSceneId(h["targetSceneId"])
  )
  let autoForwardTargetSceneId = switch autoForwardHotspotIndex {
  | Some(idx) =>
    rawHotspots
    ->Belt.Array.get(idx)
    ->Option.map(h => h["targetSceneId"])
    ->Option.getOr("")
  | None => ""
  }
  (autoForwardHotspotIndex->Option.getOr(-1), autoForwardTargetSceneId)
}
