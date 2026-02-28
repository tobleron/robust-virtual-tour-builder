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

type marketingBannerData = {
  showRent: bool,
  showSale: bool,
  body: string,
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

type bannerSegmentKind = Rent | Sale | Body

type bannerSegment = {
  kind: bannerSegmentKind,
  text: string,
  mutable width: float,
}

let drawRoundedRectCorners = (
  ctx,
  x: float,
  y: float,
  width: float,
  height: float,
  ~topLeft: float=0.0,
  ~topRight: float=0.0,
  ~bottomRight: float=0.0,
  ~bottomLeft: float=0.0,
) => {
  let halfW = width /. 2.0
  let halfH = height /. 2.0
  let maxRadius = if halfW < halfH {
    halfW
  } else {
    halfH
  }
  let clampCorner = (corner: float): float => {
    let nonNegative = if corner < 0.0 {
      0.0
    } else {
      corner
    }
    if nonNegative > maxRadius {
      maxRadius
    } else {
      nonNegative
    }
  }
  let tl = clampCorner(topLeft)
  let tr = clampCorner(topRight)
  let br = clampCorner(bottomRight)
  let bl = clampCorner(bottomLeft)

  Canvas.beginPath(ctx)
  Canvas.moveTo(ctx, x +. tl, y)
  Canvas.lineTo(ctx, x +. width -. tr, y)
  if tr > 0.0 {
    Canvas.arcTo(ctx, x +. width, y, x +. width, y +. tr, tr)
  } else {
    Canvas.lineTo(ctx, x +. width, y)
  }
  Canvas.lineTo(ctx, x +. width, y +. height -. br)
  if br > 0.0 {
    Canvas.arcTo(ctx, x +. width, y +. height, x +. width -. br, y +. height, br)
  } else {
    Canvas.lineTo(ctx, x +. width, y +. height)
  }
  Canvas.lineTo(ctx, x +. bl, y +. height)
  if bl > 0.0 {
    Canvas.arcTo(ctx, x, y +. height, x, y +. height -. bl, bl)
  } else {
    Canvas.lineTo(ctx, x, y +. height)
  }
  Canvas.lineTo(ctx, x, y +. tl)
  if tl > 0.0 {
    Canvas.arcTo(ctx, x, y, x +. tl, y, tl)
  } else {
    Canvas.lineTo(ctx, x, y)
  }
  Canvas.closePath(ctx)
}

let renderMarketingBanner = (
  ~ctx: Canvas.context2d,
  ~data: marketingBannerData,
  ~scale: hudScale,
  ~canvasWidth: int,
  ~canvasHeight: int,
) => {
  let bodyText = data.body->String.trim
  if !data.showRent && !data.showSale && bodyText == "" {
    ()
  } else {
    let fontSize = 9.0 *. scale.uniform
    let chipPadX = 6.0 *. scale.sx
    let bodyPadX = 10.0 *. scale.sx
    let segmentHeight = 19.0 *. scale.sy
    let radius = 5.0 *. scale.uniform
    let lineWidth = if scale.uniform > 1.0 {
      scale.uniform
    } else {
      1.0
    }

    let segmentItems = Belt.Array.concatMany([
      if data.showRent {
        [{kind: Rent, text: "RENT", width: 0.0}]
      } else {
        []
      },
      if data.showSale {
        [{kind: Sale, text: "SALE", width: 0.0}]
      } else {
        []
      },
      if bodyText != "" {
        [{kind: Body, text: bodyText, width: 0.0}]
      } else {
        []
      },
    ])

    Canvas.save(ctx)
    Canvas.setFont(
      ctx,
      "700 " ++ Belt.Float.toString(fontSize) ++ "px \"Open Sans\", Outfit, sans-serif",
    )
    Canvas.setTextBaseline(ctx, "middle")
    Canvas.setTextAlign(ctx, "left")

    segmentItems->Belt.Array.forEach(segment => {
      let pad = switch segment.kind {
      | Body => bodyPadX
      | _ => chipPadX
      }
      segment.width = Canvas.measureText(ctx, segment.text)->Canvas.textMetricsWidth +. pad *. 2.0
    })

    let maxTotalWidth = {
      let byCanvasRatio = Belt.Int.toFloat(canvasWidth) *. (525.0 /. hdReferenceWidth)
      let byHdAbsolute = 525.0 *. scale.sx
      if byCanvasRatio < byHdAbsolute {
        byCanvasRatio
      } else {
        byHdAbsolute
      }
    }
    let totalWidth = segmentItems->Belt.Array.reduce(0.0, (acc, segment) => acc +. segment.width)
    if totalWidth > maxTotalWidth {
      let fixedWidth = segmentItems->Belt.Array.reduce(0.0, (acc, segment) =>
        switch segment.kind {
        | Body => acc
        | _ => acc +. segment.width
        }
      )
      let maxBodyWidth = maxTotalWidth -. fixedWidth
      segmentItems->Belt.Array.forEach(segment =>
        switch segment.kind {
        | Body =>
          segment.width = if maxBodyWidth > 40.0 *. scale.sx {
            maxBodyWidth
          } else {
            40.0 *. scale.sx
          }
        | _ => ()
        }
      )
    }

    let adjustedTotalWidth =
      segmentItems->Belt.Array.reduce(0.0, (acc, segment) => acc +. segment.width)
    let startX = (Belt.Int.toFloat(canvasWidth) -. adjustedTotalWidth) /. 2.0
    let startY = Belt.Int.toFloat(canvasHeight) -. segmentHeight -. lineWidth *. 0.5

    let cursorX = ref(startX)
    let count = segmentItems->Belt.Array.length
    let fitTextToWidth = (rawText: string, maxWidth: float): string => {
      if maxWidth <= 0.0 {
        ""
      } else {
        let rawWidth = Canvas.measureText(ctx, rawText)->Canvas.textMetricsWidth
        if rawWidth <= maxWidth {
          rawText
        } else {
          let ellipsis = "..."
          let ellipsisWidth = Canvas.measureText(ctx, ellipsis)->Canvas.textMetricsWidth
          if ellipsisWidth > maxWidth {
            ""
          } else {
            let rec trim = (candidate: string): string => {
              if candidate == "" {
                ellipsis
              } else {
                let fitted = candidate ++ ellipsis
                if Canvas.measureText(ctx, fitted)->Canvas.textMetricsWidth <= maxWidth {
                  fitted
                } else {
                  let next = String.slice(candidate, ~start=0, ~end=String.length(candidate) - 1)
                  trim(next)
                }
              }
            }
            trim(rawText)
          }
        }
      }
    }

    for i in 0 to count - 1 {
      switch segmentItems->Belt.Array.get(i) {
      | Some(segment) =>
        let x = cursorX.contents
        let w = segment.width
        let isFirst = i == 0
        let isLast = i == count - 1

        let bgColor = switch segment.kind {
        | Rent => "#0e2d52"
        | Sale => "#ea580c"
        | Body => "#facc15"
        }
        let textColor = switch segment.kind {
        | Body => "#000000"
        | _ => "#ffffff"
        }
        let topLeftRadius = if isFirst {
          radius
        } else {
          0.0
        }
        let topRightRadius = if isLast {
          radius
        } else {
          0.0
        }

        drawRoundedRectCorners(
          ctx,
          x,
          startY,
          w,
          segmentHeight,
          ~topLeft=topLeftRadius,
          ~topRight=topRightRadius,
          ~bottomRight=0.0,
          ~bottomLeft=0.0,
        )
        Canvas.setFillStyle(ctx, bgColor)
        Canvas.fill(ctx)
        Canvas.setLineWidth(ctx, lineWidth)
        Canvas.setStrokeStyle(ctx, "rgba(0,0,0,0.12)")
        Canvas.stroke(ctx)

        let pad = switch segment.kind {
        | Body => bodyPadX
        | _ => chipPadX
        }
        let textX = x +. pad
        let textY = startY +. segmentHeight /. 2.0
        Canvas.setFillStyle(ctx, textColor)
        if segment.kind == Body {
          let bodyTextMaxWidth = w -. pad *. 2.0
          Canvas.setTextAlign(ctx, "left")
          Canvas.fillText(ctx, fitTextToWidth(segment.text, bodyTextMaxWidth), textX, textY)
        } else {
          Canvas.setTextAlign(ctx, "center")
          Canvas.fillText(ctx, segment.text, x +. w /. 2.0, textY)
        }
        cursorX := cursorX.contents +. w
      | None => ()
      }
    }
    Canvas.restore(ctx)
  }
}
