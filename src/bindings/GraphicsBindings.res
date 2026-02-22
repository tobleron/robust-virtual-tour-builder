/* src/bindings/GraphicsBindings.res */

module Canvas = {
  type context2d
  @send external getContext2d: (DomBindings.Dom.element, string, {..}) => context2d = "getContext"

  @set external setFillStyle: (context2d, string) => unit = "fillStyle"
  @set external setStrokeStyle: (context2d, string) => unit = "strokeStyle"
  @set external setLineWidth: (context2d, float) => unit = "lineWidth"
  @set external setGlobalAlpha: (context2d, float) => unit = "globalAlpha"
  @set external setFont: (context2d, string) => unit = "font"
  @set external setTextAlign: (context2d, string) => unit = "textAlign"
  @set external setTextBaseline: (context2d, string) => unit = "textBaseline"
  @set external setShadowColor: (context2d, string) => unit = "shadowColor"
  @set external setShadowBlur: (context2d, float) => unit = "shadowBlur"
  @set external setShadowOffsetX: (context2d, float) => unit = "shadowOffsetX"
  @set external setShadowOffsetY: (context2d, float) => unit = "shadowOffsetY"

  @send external fillRect: (context2d, float, float, float, float) => unit = "fillRect"
  @send
  external drawImage: (context2d, DomBindings.Dom.element, float, float, float, float) => unit =
    "drawImage"
  @send
  external drawImageCoords: (
    context2d,
    DomBindings.Dom.element,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
    float,
  ) => unit = "drawImage"

  type imageData
  @send external createImageData: (context2d, int, int) => imageData = "createImageData"
  @send external getImageData: (context2d, float, float, float, float) => imageData = "getImageData"
  @send external putImageData: (context2d, imageData, float, float) => unit = "putImageData"

  @send external beginPath: context2d => unit = "beginPath"
  @send external closePath: context2d => unit = "closePath"
  @send external stroke: context2d => unit = "stroke"
  @send external fill: context2d => unit = "fill"
  type textMetrics
  @send external fillText: (context2d, string, float, float) => unit = "fillText"
  @send external measureText: (context2d, string) => textMetrics = "measureText"
  @send external save: context2d => unit = "save"
  @send external restore: context2d => unit = "restore"

  @send external moveTo: (context2d, float, float) => unit = "moveTo"
  @send external lineTo: (context2d, float, float) => unit = "lineTo"
  @send external arc: (context2d, float, float, float, float, float, bool) => unit = "arc"
  @send external arcTo: (context2d, float, float, float, float, float) => unit = "arcTo"

  @send external translate: (context2d, float, float) => unit = "translate"
  @send external rotate: (context2d, float) => unit = "rotate"
  @send external scale: (context2d, float, float) => unit = "scale"

  @send external roundRect: (context2d, float, float, float, float, float) => unit = "roundRect"
  @send external rect: (context2d, float, float, float, float) => unit = "rect"
  @get external textMetricsWidth: textMetrics => float = "width"
}

module Svg = {
  let namespace = "http://www.w3.org/2000/svg"

  @scope("document") @val
  external createElementNS: (string, string) => DomBindings.Dom.element = "createElementNS"
  @send external setAttribute: (DomBindings.Dom.element, string, string) => unit = "setAttribute"
  @send
  external appendChild: (DomBindings.Dom.element, DomBindings.Dom.element) => unit = "appendChild"

  @set external setOnMouseOver: (DomBindings.Dom.element, unit => unit) => unit = "onmouseover"
  @set external setOnMouseOut: (DomBindings.Dom.element, unit => unit) => unit = "onmouseout"
}
