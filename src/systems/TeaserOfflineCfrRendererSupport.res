open Types

let normalizeSceneFloor = (floorRaw: string): option<string> => {
  let trimmed = floorRaw->String.trim
  if trimmed == "" {
    None
  } else {
    Some(trimmed)
  }
}

let floorLevelsInUse = (scenes: array<scene>): array<string> => {
  let inUse = Dict.make()
  scenes->Belt.Array.forEach(scene =>
    normalizeSceneFloor(scene.floor)->Option.forEach(floorId => Dict.set(inUse, floorId, true))
  )
  Constants.Scene.floorLevels->Belt.Array.keepMap(level =>
    switch Dict.get(inUse, level.id) {
    | Some(true) => Some(level.id)
    | _ => None
    }
  )
}

let sceneOverlayFor = (
  scenes: array<scene>,
  sceneId: string,
  visibleFloorIds: array<string>,
  ~marketing: option<TeaserRecorder.teaserMarketingOverlay>,
): TeaserRecorder.teaserHudOverlay =>
  scenes
  ->Belt.Array.getBy(scene => scene.id == sceneId)
  ->Option.map((scene): TeaserRecorder.teaserHudOverlay => {
    roomLabel: {
      let trimmed = scene.label->String.trim
      if trimmed == "" || trimmed->String.toLowerCase->String.includes("untagged") {
        None
      } else {
        Some(scene.label)
      }
    },
    activeFloor: if scene.floor->String.trim == "" {
      "ground"
    } else {
      scene.floor
    },
    visibleFloorIds,
    marketing,
  })
  ->Option.getOr(
    (
      {
        roomLabel: None,
        activeFloor: "ground",
        visibleFloorIds,
        marketing,
      }: TeaserRecorder.teaserHudOverlay
    ),
  )

let marketingOverlayFromState = (state: state): option<TeaserRecorder.teaserMarketingOverlay> => {
  let composed = MarketingText.compose(
    ~comment=state.marketingComment,
    ~phone1=state.marketingPhone1,
    ~phone2=state.marketingPhone2,
    ~forRent=state.marketingForRent,
    ~forSale=state.marketingForSale,
  )
  if composed.full != "" {
    Some({
      showRent: composed.showRent,
      showSale: composed.showSale,
      body: composed.body,
    })
  } else {
    None
  }
}
