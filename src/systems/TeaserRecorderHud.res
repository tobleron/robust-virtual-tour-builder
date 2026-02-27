open ReBindings

@send
external drawImageScaled: (Canvas.context2d, Dom.element, float, float, float, float) => unit =
  "drawImage"
external asDynamic: 'a => {..} = "%identity"

type hudScale = {
  sx: float,
  sy: float,
  uniform: float,
}

let hdReferenceWidth = Constants.Teaser.HudReference.stageWidth
let hdReferenceHeight = Constants.Teaser.HudReference.stageHeight

let checkRoundRect: 'a => bool = %raw("function(x) { return typeof x === 'function'; }")

let drawRoundedRect = (ctx, x, y, width, height, radius) => {
  Canvas.beginPath(ctx)
  if checkRoundRect(asDynamic(ctx)["roundRect"]) {
    let rr: (Canvas.context2d, float, float, float, float, float) => unit = %raw(
      "(ctx, px, py, w, h, r) => ctx.roundRect(px, py, w, h, r)"
    )
    rr(ctx, x, y, width, height, radius)
  } else {
    Canvas.rect(ctx, x, y, width, height)
  }
}

let getHudScale = (~canvasWidth: int, ~canvasHeight: int): hudScale => {
  let cw = Belt.Int.toFloat(canvasWidth)
  let ch = Belt.Int.toFloat(canvasHeight)
  let sx = cw /. hdReferenceWidth
  let sy = ch /. hdReferenceHeight
  let uniform = if sx < sy {
    sx
  } else {
    sy
  }
  {
    sx,
    sy,
    uniform,
  }
}

let renderWatermark = (
  ~ctx: Canvas.context2d,
  ~logoImg: Dom.element,
  ~scale: hudScale,
  ~canvasWidth: int,
  ~canvasHeight: int,
) => {
  let logoHeight = Constants.Teaser.HudReference.logoHeight *. scale.uniform
  let marginBottom = Constants.Teaser.HudReference.logoBottomInset *. scale.sy
  let marginRight = Constants.Teaser.HudReference.logoRightInset *. scale.sx
  let sourceWidth = Belt.Int.toFloat(Dom.getWidth(logoImg))
  if sourceWidth <= 0.0 {
    ()
  } else {
    let sourceHeight = Belt.Int.toFloat(Dom.getHeight(logoImg))
    let logoWidth = logoHeight *. (sourceWidth /. sourceHeight)
    let logoX = Belt.Int.toFloat(canvasWidth) -. logoWidth -. marginRight
    let logoY = Belt.Int.toFloat(canvasHeight) -. logoHeight -. marginBottom
    Canvas.save(ctx)
    Canvas.setShadowColor(ctx, "rgba(0,0,0,0.35)")
    Canvas.setShadowBlur(ctx, 2.0 *. scale.uniform)
    Canvas.setShadowOffsetX(ctx, 1.0 *. scale.uniform)
    Canvas.setShadowOffsetY(ctx, 1.0 *. scale.uniform)
    drawImageScaled(ctx, logoImg, logoX, logoY, logoWidth, logoHeight)
    Canvas.restore(ctx)
  }
}

let renderRoomLabel = (
  ~ctx: Canvas.context2d,
  ~roomLabel: string,
  ~scale: hudScale,
  ~canvasWidth: int,
) => {
  let label = "# " ++ String.toUpperCase(roomLabel)
  let horizontalPadding = Constants.Teaser.HudReference.roomTagHorizontalPadding *. scale.sx
  let tagHeight = Constants.Teaser.HudReference.roomTagHeight *. scale.sy
  let tagY = Constants.Teaser.HudReference.roomTagTopInset *. scale.sy

  Canvas.save(ctx)
  Canvas.setFont(
    ctx,
    "600 " ++
    Belt.Float.toString(
      Constants.Teaser.HudReference.roomTagFontSize *. scale.uniform,
    ) ++ "px Outfit, sans-serif",
  )
  Canvas.setTextAlign(ctx, "left")
  Canvas.setTextBaseline(ctx, "middle")
  let measuredWidth = Canvas.measureText(ctx, label)->Canvas.textMetricsWidth
  let minWidth = Constants.Teaser.HudReference.roomTagMinWidth *. scale.sx
  let tagWidth = {
    let candidate = measuredWidth +. horizontalPadding *. 2.0
    if candidate > minWidth {
      candidate
    } else {
      minWidth
    }
  }
  let tagX = (Belt.Int.toFloat(canvasWidth) -. tagWidth) /. 2.0

  Canvas.setFillStyle(ctx, "rgba(0,61,165,0.85)")
  drawRoundedRect(
    ctx,
    tagX,
    tagY,
    tagWidth,
    tagHeight,
    Constants.Teaser.HudReference.roomTagBorderRadius *. scale.uniform,
  )
  Canvas.fill(ctx)

  Canvas.setLineWidth(
    ctx,
    if scale.uniform > 1.0 {
      scale.uniform
    } else {
      1.0
    },
  )
  Canvas.setStrokeStyle(ctx, "rgba(255,255,255,0.1)")
  drawRoundedRect(
    ctx,
    tagX,
    tagY,
    tagWidth,
    tagHeight,
    Constants.Teaser.HudReference.roomTagBorderRadius *. scale.uniform,
  )
  Canvas.stroke(ctx)

  Canvas.setFillStyle(ctx, "#ffffff")
  Canvas.setShadowColor(ctx, "rgba(0,0,0,0.35)")
  Canvas.setShadowBlur(ctx, 2.0 *. scale.uniform)
  Canvas.setShadowOffsetX(ctx, 0.0)
  Canvas.setShadowOffsetY(ctx, 1.0 *. scale.uniform)
  Canvas.fillText(ctx, label, tagX +. horizontalPadding, tagY +. tagHeight /. 2.0)
  Canvas.restore(ctx)
}

let renderFloorNav = (
  ~ctx: Canvas.context2d,
  ~activeFloor: string,
  ~visibleFloorIds: array<string>,
  ~scale: hudScale,
  ~canvasHeight: int,
) => {
  let floorLevels =
    Constants.Scene.floorLevels->Belt.Array.keep(level =>
      visibleFloorIds->Belt.Array.some(visibleId => visibleId == level.id)
    )
  let buttonSize = Constants.Teaser.HudReference.floorButtonSize *. scale.uniform
  let gap = Constants.Teaser.HudReference.floorGap *. scale.sy
  let bottomInset = Constants.Teaser.HudReference.floorBottomInset *. scale.sy
  let leftInset = Constants.Teaser.HudReference.floorLeftInset *. scale.sx
  let count = floorLevels->Belt.Array.length
  let labelTextForLevel = (floorLevel: Constants.Scene.floorLevel) =>
    floorLevel.short ++
    switch floorLevel.suffix {
    | Some(s) => s
    | None => ""
    }

  for idx in 0 to count - 1 {
    switch floorLevels->Belt.Array.get(idx) {
    | Some(level) =>
      let cx = leftInset +. buttonSize /. 2.0
      let y =
        Belt.Int.toFloat(canvasHeight) -.
        bottomInset -.
        buttonSize -.
        Belt.Int.toFloat(idx) *. (buttonSize +. gap)
      let cy = y +. buttonSize /. 2.0
      let isActive = level.id == activeFloor

      Canvas.save(ctx)
      Canvas.beginPath(ctx)
      Canvas.arc(ctx, cx, cy, buttonSize /. 2.0, 0.0, 6.283185307179586, false)
      Canvas.closePath(ctx)
      Canvas.setFillStyle(ctx, isActive ? "#ea580c" : "rgba(128,128,128,0.22)")
      Canvas.fill(ctx)

      Canvas.setLineWidth(
        ctx,
        isActive
          ? 2.0 *. scale.uniform
          : if scale.uniform > 1.0 {
              scale.uniform
            } else {
              1.0
            },
      )
      Canvas.setStrokeStyle(ctx, isActive ? "#ea580c" : "rgba(255,255,255,0.28)")
      Canvas.stroke(ctx)

      Canvas.setFont(
        ctx,
        "600 " ++
        Belt.Float.toString(
          Constants.Teaser.HudReference.floorButtonFontSize *. scale.uniform,
        ) ++ "px Outfit, sans-serif",
      )
      Canvas.setTextAlign(ctx, "center")
      Canvas.setTextBaseline(ctx, "middle")
      Canvas.setFillStyle(ctx, "#ffffff")
      Canvas.fillText(ctx, labelTextForLevel(level), cx, cy +. 0.5)
      Canvas.restore(ctx)
    | None => ()
    }
  }
}
