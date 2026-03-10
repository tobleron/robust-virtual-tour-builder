// @efficiency-role: domain-logic

open Types

let updateHotspotAtIndex = (
  hotspots: array<hotspot>,
  hotspotIndex: int,
  updateHotspot: hotspot => hotspot,
) => {
  Belt.Array.mapWithIndex(hotspots, (currentIndex, currentHotspot) => {
    if currentIndex == hotspotIndex {
      updateHotspot(currentHotspot)
    } else {
      currentHotspot
    }
  })
}

let withFallback = (nextValue: option<'a>, currentValue: 'a): 'a => {
  switch nextValue {
  | Some(value) => value
  | None => currentValue
  }
}

let withOptionalFallback = (nextValue: option<'a>, currentValue: option<'a>): option<'a> => {
  switch nextValue {
  | Some(value) => Some(value)
  | None => currentValue
  }
}

let emptyHotspotMetadata = (): JsonParsersDecoders.updateHotspotMetadata => {
  isAutoForward: None,
  target: None,
  targetSceneId: None,
  sequenceOrder: None,
}

let decodeHotspotMetadata = (metadata: JSON.t): JsonParsersDecoders.updateHotspotMetadata => {
  switch JsonCombinators.Json.decode(metadata, JsonParsers.Domain.updateHotspotMetadata) {
  | Ok(meta) => meta
  | Error(_) => emptyHotspotMetadata()
  }
}

let applyHotspotMetadata = (
  hotspot: hotspot,
  meta: JsonParsersDecoders.updateHotspotMetadata,
) => {
  {
    ...hotspot,
    isAutoForward: withOptionalFallback(meta.isAutoForward, hotspot.isAutoForward),
    target: withFallback(meta.target, hotspot.target),
    targetSceneId: withOptionalFallback(meta.targetSceneId, hotspot.targetSceneId),
    sequenceOrder: withOptionalFallback(meta.sequenceOrder, hotspot.sequenceOrder),
  }
}
