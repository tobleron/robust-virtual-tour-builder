/* src/systems/TeaserRecorder.res */
open ReBindings

let canvasWidth = Constants.Teaser.canvasWidth
let canvasHeight = Constants.Teaser.canvasHeight

@val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

type stream
type mediaRecorder
type blob = Blob.t

@send external captureStream: (Dom.element, int) => stream = "captureStream"
@new external createMediaRecorder: (stream, {..}) => mediaRecorder = "MediaRecorder"
@send external start: (mediaRecorder, int) => unit = "start"
@send external stop: mediaRecorder => unit = "stop"
@get external state: mediaRecorder => string = "state"
@set external ondataavailable: (mediaRecorder, {..} => unit) => unit = "ondataavailable"
@set external onstop: (mediaRecorder, unit => unit) => unit = "onstop"
@send external pause: mediaRecorder => unit = "pause"
@send external resume: mediaRecorder => unit = "resume"
@send
external drawImageScaled: (Canvas.context2d, Dom.element, float, float, float, float) => unit =
  "drawImage"
@send external drawImagePos: (Canvas.context2d, Dom.element, float, float) => unit = "drawImage"

external asDynamic: 'a => {..} = "%identity"
external castToBlob: 'a => blob = "%identity"

type logoResult = {img: option<Dom.element>, loaded: bool}

type recorderState = {
  mediaRecorder: option<mediaRecorder>,
  chunks: array<blob>,
  streamLoopId: option<int>,
  startTime: float,
  fadeOpacity: float,
  isTeasing: bool,
  ghostCanvas: option<Dom.element>,
  ghostCtx: option<Canvas.context2d>,
  snapshotCanvas: option<Dom.element>,
}

let internalState = ref({
  mediaRecorder: (None: option<mediaRecorder>),
  chunks: ([]: array<blob>),
  streamLoopId: (None: option<int>),
  startTime: 0.0,
  fadeOpacity: 0.0,
  isTeasing: false,
  ghostCanvas: (None: option<Dom.element>),
  ghostCtx: (None: option<Canvas.context2d>),
  snapshotCanvas: (None: option<Dom.element>),
})

module Overlay = {
  let getOrCreate = () => {
    let id = "teaser-overlay"
    switch Dom.getElementById(id)->Nullable.toOption {
    | Some(d) => d
    | None =>
      let div = Dom.createElement("div")
      Dom.setId(div, id)
      Dom.setAttribute(
        div,
        "style",
        "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:0;transition:opacity 0.1s linear;",
      )
      Dom.appendChild(Dom.documentBody, div)
      div
    }
  }
  let setOpacity = (opacity: float) => {
    switch Dom.getElementById("teaser-overlay")->Nullable.toOption {
    | Some(d) =>
      Dom.setAttribute(
        d,
        "style",
        "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:" ++
        Float.toString(opacity) ++ ";transition:opacity 0.1s linear;",
      )
    | None => ()
    }
  }
}

let loadLogo = () =>
  Promise.make((resolve, _) => {
    let img = Dom.createElement("img")
    Dom.setAttribute(img, "src", "images/logo.png")
    asDynamic(img)["onload"] = () => resolve({img: Some(img), loaded: true})
    asDynamic(img)["onerror"] = () => resolve({img: None, loaded: false})
  })

let initGhost = () => {
  if internalState.contents.ghostCanvas == None {
    let c = Dom.createElement("canvas")
    Dom.setWidth(c, canvasWidth)
    Dom.setHeight(c, canvasHeight)
    internalState := {
        ...internalState.contents,
        ghostCanvas: Some(c),
        ghostCtx: Some(Canvas.getContext2d(c, "2d", {"alpha": false})),
      }
  }
}

let renderWatermark = (ctx, logoImg) => {
  let logoWidth = 150.0
  let padding = 4.0
  let margin = 32.0
  let borderRadius = 16.0
  let logoHeight =
    logoWidth *.
    (Belt.Int.toFloat(Dom.getHeight(logoImg)) /.
    Belt.Int.toFloat(Dom.getWidth(logoImg)))
  let boxWidth = logoWidth +. padding *. 2.0
  let boxHeight = logoHeight +. padding *. 2.0
  let boxX = Belt.Int.toFloat(canvasWidth) -. boxWidth -. margin
  let boxY = Belt.Int.toFloat(canvasHeight) -. boxHeight -. margin
  Canvas.save(ctx)
  Canvas.setShadowColor(ctx, "rgba(0,0,0,0.15)")
  Canvas.setShadowBlur(ctx, 10.0)
  Canvas.setShadowOffsetY(ctx, 4.0)
  Canvas.setFillStyle(ctx, "var(--sidebar-bg)")
  Canvas.beginPath(ctx)
  let checkRoundRect: 'a => bool = %raw("function(x) { return typeof x === 'function'; }")
  if checkRoundRect(asDynamic(ctx)["roundRect"]) {
    let rr: (Canvas.context2d, float, float, float, float, float) => unit = %raw(
      "(ctx, x, y, w, h, r) => ctx.roundRect(x,y,w,h,r)"
    )
    rr(ctx, boxX, boxY, boxWidth, boxHeight, borderRadius)
  } else {
    Canvas.rect(ctx, boxX, boxY, boxWidth, boxHeight)
  }
  Canvas.fill(ctx)
  Canvas.setShadowColor(ctx, "transparent")
  Canvas.setShadowBlur(ctx, 0.0)
  Canvas.setShadowOffsetY(ctx, 0.0)
  drawImageScaled(ctx, logoImg, boxX +. padding, boxY +. padding, logoWidth, logoHeight)
  Canvas.restore(ctx)
}

let renderFrame = (sourceCanvas, includeLogo, logoState: logoResult) => {
  switch internalState.contents.ghostCtx {
  | Some(ctx) =>
    let sw = Belt.Int.toFloat(Dom.getWidth(sourceCanvas))
    let sh = Belt.Int.toFloat(Dom.getHeight(sourceCanvas))
    if sw > 0.0 {
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
      if internalState.contents.fadeOpacity > 0.01 {
        switch internalState.contents.snapshotCanvas {
        | Some(snap) =>
          Canvas.save(ctx)
          Canvas.setGlobalAlpha(ctx, internalState.contents.fadeOpacity)
          drawImagePos(ctx, snap, 0.0, 0.0)
          Canvas.restore(ctx)
        | None => ()
        }
      }
      if includeLogo && logoState.loaded {
        switch logoState.img {
        | Some(img) => renderWatermark(ctx, img)
        | None => ()
        }
      }
    }
  | None => ()
  }
}

let startAnimationLoop = (includeLogo, logoState) => {
  let rec draw = () => {
    switch Dom.querySelector(Dom.documentBody, ".pnlm-render-container canvas")->Nullable.toOption {
    | Some(sc) => renderFrame(sc, includeLogo, logoState)
    | None => ()
    }
    internalState := {...internalState.contents, streamLoopId: Some(requestAnimationFrame(draw))}
  }
  internalState.contents.streamLoopId->Option.forEach(cancelAnimationFrame)
  internalState := {...internalState.contents, streamLoopId: Some(requestAnimationFrame(draw))}
}

let startRecording = () => {
  initGhost()
  switch internalState.contents.ghostCanvas {
  | None => false
  | Some(canvas) =>
    let stream = captureStream(canvas, 60)
    let mimeType = if String.includes(Window.navigatorUserAgent, "Firefox") {
      "video/webm;codecs=vp8"
    } else {
      "video/webm;codecs=vp9,opus"
    }
    try {
      let r = createMediaRecorder(stream, {"mimeType": mimeType, "videoBitsPerSecond": 10000000})
      internalState := {
          ...internalState.contents,
          chunks: [],
          mediaRecorder: Some(r),
          startTime: Date.now(),
          isTeasing: true,
        }
      r->ondataavailable(e => {
        if e["data"]["size"] > 0 {
          let b = castToBlob(e["data"])
          internalState := {
              ...internalState.contents,
              chunks: Array.concat(internalState.contents.chunks, [b]),
            }
        }
      })
      r->start(100)
      true
    } catch {
    | _ => false
    }
  }
}

let stopRecording = () => {
  switch internalState.contents.mediaRecorder {
  | Some(r) =>
    r->stop
    internalState := {...internalState.contents, isTeasing: false}
    internalState.contents.streamLoopId->Option.forEach(cancelAnimationFrame)
    internalState := {...internalState.contents, streamLoopId: None}
  | None => ()
  }
}

let pauseRecording = () => {
  switch internalState.contents.mediaRecorder {
  | Some(r) => r->pause
  | None => ()
  }
}

let resumeRecording = () => {
  switch internalState.contents.mediaRecorder {
  | Some(r) => r->resume
  | None => ()
  }
}

let getGhostCanvas = () => internalState.contents.ghostCanvas->Nullable.fromOption
let getRecordedBlobs = () => internalState.contents.chunks

let setSnapshot = (canvas: Dom.element) => {
  internalState := {...internalState.contents, snapshotCanvas: Some(canvas)}
}

let setFadeOpacity = (opacity: float) => {
  internalState := {...internalState.contents, fadeOpacity: opacity}
  Overlay.setOpacity(opacity)
}

module Recorder = {
  let startRecording = startRecording
  let stopRecording = stopRecording
  let pause = pauseRecording
  let resume = resumeRecording
  let getGhostCanvas = getGhostCanvas
  let getRecordedBlobs = getRecordedBlobs
  let setSnapshot = setSnapshot
  let setFadeOpacity = setFadeOpacity
  let loadLogo = loadLogo
  let startAnimationLoop = startAnimationLoop
  let internalState = internalState
}
