// @efficiency-role: domain-logic

open ReBindings

@send
external drawImageScaled: (Canvas.context2d, Dom.element, float, float, float, float) => unit =
  "drawImage"
@send external drawImagePos: (Canvas.context2d, Dom.element, float, float) => unit = "drawImage"
external asDynamic: 'a => {..} = "%identity"

type logoResult = TeaserRecorderTypes.logoResult

let overlayStyle = (opacity: float) =>
  "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:" ++
  Float.toString(opacity) ++ ";transition:opacity 0.1s linear;"

let getOrCreateOverlay = () => {
  let id = "teaser-overlay"
  switch Dom.getElementById(id)->Nullable.toOption {
  | Some(d) => d
  | None =>
    let div = Dom.createElement("div")
    Dom.setId(div, id)
    Dom.setAttribute(div, "style", overlayStyle(0.0))
    Dom.appendChild(Dom.documentBody, div)
    div
  }
}

let setOverlayOpacity = (opacity: float) => {
  switch Dom.getElementById("teaser-overlay")->Nullable.toOption {
  | Some(d) => Dom.setAttribute(d, "style", overlayStyle(opacity))
  | None => ()
  }
}

let clearOverlay = () => {
  switch Dom.getElementById("teaser-overlay")->Nullable.toOption {
  | Some(d) => Dom.setAttribute(d, "style", overlayStyle(0.0))
  | None => ()
  }
}

let loadLogo = (logo: option<Types.file>) => {
  Promise.make((resolve, _) => {
    let src = switch logo {
    | Some(f) => Types.fileToUrl(f)
    | None => Constants.defaultLogoPath
    }
    let img = Dom.createElement("img")
    Dom.setAttribute(img, "src", src)
    asDynamic(img)["onload"] = () => resolve(({img: Some(img), loaded: true}: logoResult))
    asDynamic(img)["onerror"] = () => resolve(({img: None, loaded: false}: logoResult))
  })
}

let copySnapshot = (~snapshotCanvas: Dom.element, ~sourceCanvas: Dom.element) => {
  let ctx = Canvas.getContext2d(snapshotCanvas, "2d", {"alpha": false})
  drawImagePos(ctx, sourceCanvas, 0.0, 0.0)
}

let resolveSourceCanvas = (): option<Dom.element> => {
  switch Dom.querySelector(Dom.documentBody, ".panorama-layer.active canvas")->Nullable.toOption {
  | Some(canvas) => Some(canvas)
  | None =>
    switch Dom.querySelector(Dom.documentBody, ".panorama-layer canvas")->Nullable.toOption {
    | Some(canvas) => Some(canvas)
    | None =>
      Dom.querySelector(Dom.documentBody, ".pnlm-render-container canvas")->Nullable.toOption
    }
  }
}

let renderFrame = (
  ~ctx: Canvas.context2d,
  ~sourceCanvas: Dom.element,
  ~canvasWidth: int,
  ~canvasHeight: int,
  ~fadeOpacity: float,
  ~snapshotCanvas: option<Dom.element>,
  ~renderOverlay: unit => unit,
  ~renderLogo: unit => unit,
) => {
  let sw = Belt.Int.toFloat(Dom.getWidth(sourceCanvas))
  let sh = Belt.Int.toFloat(Dom.getHeight(sourceCanvas))
  if sw <= 0.0 || sh <= 0.0 {
    ()
  } else {
    let dw = Belt.Int.toFloat(canvasWidth)
    let dh = Belt.Int.toFloat(canvasHeight)
    let (rw, rh, rx, ry) = if sw /. sh > dw /. dh {
      (dh *. (sw /. sh), dh, (dw -. dh *. (sw /. sh)) /. 2.0, 0.0)
    } else {
      (dw, dw /. (sw /. sh), 0.0, (dh -. dw /. (sw /. sh)) /. 2.0)
    }
    Canvas.setFillStyle(ctx, "#000")
    Canvas.fillRect(ctx, 0.0, 0.0, dw, dh)
    drawImageScaled(ctx, sourceCanvas, rx, ry, rw, rh)
    if fadeOpacity > 0.01 {
      switch snapshotCanvas {
      | Some(snap) =>
        Canvas.save(ctx)
        Canvas.setGlobalAlpha(ctx, fadeOpacity)
        drawImagePos(ctx, snap, 0.0, 0.0)
        Canvas.restore(ctx)
      | None => ()
      }
    }
    renderOverlay()
    renderLogo()
  }
}
