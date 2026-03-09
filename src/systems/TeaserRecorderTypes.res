// @efficiency-role: data-model

open ReBindings

type logoResult = {
  img: option<Dom.element>,
  loaded: bool,
}

type teaserMarketingOverlay = TeaserRecorderHudTypes.marketingBannerData

type teaserHudOverlay = {
  roomLabel: option<string>,
  activeFloor: string,
  visibleFloorIds: array<string>,
  marketing: option<teaserMarketingOverlay>,
}

type hudScale = TeaserRecorderHudTypes.hudScale
