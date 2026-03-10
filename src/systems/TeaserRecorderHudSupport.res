// @efficiency-role: domain-logic

open ReBindings

type hudScale = TeaserRecorderHudTypes.hudScale
type marketingBannerData = TeaserRecorderHudTypes.marketingBannerData
type bannerSegment = TeaserRecorderHudTypes.bannerSegment
type bannerSegmentKind = TeaserRecorderHudTypes.bannerSegmentKind

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
  let maxRadius = if halfW < halfH { halfW } else { halfH }
  let clampCorner = (corner: float): float => {
    let nonNegative = if corner < 0.0 { 0.0 } else { corner }
    if nonNegative > maxRadius { maxRadius } else { nonNegative }
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

let fitTextToWidth = (~ctx, ~rawText: string, ~maxWidth: float): string => {
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

let renderMarketingBanner = (
  ~ctx: Canvas.context2d,
  ~data: marketingBannerData,
  ~scale: hudScale,
  ~canvasWidth: int,
  ~canvasHeight: int,
  ~hdReferenceWidth: float,
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
    let lineWidth = if scale.uniform > 1.0 { scale.uniform } else { 1.0 }

    let segmentItems: array<bannerSegment> = Belt.Array.concatMany([
      if data.showRent {
        [({kind: TeaserRecorderHudTypes.Rent, text: "RENT", width: 0.0}: bannerSegment)]
      } else {
        []
      },
      if data.showSale {
        [({kind: TeaserRecorderHudTypes.Sale, text: "SALE", width: 0.0}: bannerSegment)]
      } else {
        []
      },
      if bodyText != "" {
        [({kind: TeaserRecorderHudTypes.Body, text: bodyText, width: 0.0}: bannerSegment)]
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
      | TeaserRecorderHudTypes.Body => bodyPadX
      | _ => chipPadX
      }
      segment.width = Canvas.measureText(ctx, segment.text)->Canvas.textMetricsWidth +. pad *. 2.0
    })

    let maxTotalWidth = {
      let byCanvasRatio = Belt.Int.toFloat(canvasWidth) *. (525.0 /. hdReferenceWidth)
      let byHdAbsolute = 525.0 *. scale.sx
      if byCanvasRatio < byHdAbsolute { byCanvasRatio } else { byHdAbsolute }
    }
    let totalWidth = segmentItems->Belt.Array.reduce(0.0, (acc, segment) => acc +. segment.width)
    if totalWidth > maxTotalWidth {
      let fixedWidth = segmentItems->Belt.Array.reduce(0.0, (acc, segment) =>
        switch segment.kind {
        | TeaserRecorderHudTypes.Body => acc
        | _ => acc +. segment.width
        }
      )
      let maxBodyWidth = maxTotalWidth -. fixedWidth
      segmentItems->Belt.Array.forEach(segment =>
        switch segment.kind {
        | TeaserRecorderHudTypes.Body =>
          segment.width = if maxBodyWidth > 40.0 *. scale.sx { maxBodyWidth } else { 40.0 *. scale.sx }
        | _ => ()
        }
      )
    }

    let adjustedTotalWidth = segmentItems->Belt.Array.reduce(0.0, (acc, segment) => acc +. segment.width)
    let startX = (Belt.Int.toFloat(canvasWidth) -. adjustedTotalWidth) /. 2.0
    let startY = Belt.Int.toFloat(canvasHeight) -. segmentHeight -. lineWidth *. 0.5
    let cursorX = ref(startX)
    let count = segmentItems->Belt.Array.length

    for i in 0 to count - 1 {
      switch segmentItems->Belt.Array.get(i) {
      | Some(segment) =>
        let x = cursorX.contents
        let w = segment.width
        let isFirst = i == 0
        let isLast = i == count - 1

        let bgColor = switch segment.kind {
        | TeaserRecorderHudTypes.Rent => "#0e2d52"
        | TeaserRecorderHudTypes.Sale => "#ea580c"
        | TeaserRecorderHudTypes.Body => "#facc15"
        }
        let textColor = switch segment.kind {
        | TeaserRecorderHudTypes.Body => "#000000"
        | _ => "#ffffff"
        }
        let topLeftRadius = if isFirst { radius } else { 0.0 }
        let topRightRadius = if isLast { radius } else { 0.0 }

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
        | TeaserRecorderHudTypes.Body => bodyPadX
        | _ => chipPadX
        }
        let textX = x +. pad
        let textY = startY +. segmentHeight /. 2.0
        Canvas.setFillStyle(ctx, textColor)
        if segment.kind == TeaserRecorderHudTypes.Body {
          let bodyTextMaxWidth = w -. pad *. 2.0
          Canvas.setTextAlign(ctx, "left")
          Canvas.fillText(
            ctx,
            fitTextToWidth(~ctx, ~rawText=segment.text, ~maxWidth=bodyTextMaxWidth),
            textX,
            textY,
          )
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
