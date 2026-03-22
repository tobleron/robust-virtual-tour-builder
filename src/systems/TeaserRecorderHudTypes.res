// @efficiency-role: data-model

type hudScale = {
  sx: float,
  sy: float,
  uniform: float,
}

type marketingBannerData = {
  showRent: bool,
  showSale: bool,
  body: string,
}

type bannerSegmentKind = Rent | Sale | Body

type bannerSegment = {
  kind: bannerSegmentKind,
  text: string,
  width: float,
}
