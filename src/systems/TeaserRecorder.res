/* src/systems/TeaserRecorder.res */

/* Bindings & Imports */
let canvasWidth = Constants.Teaser.canvasWidth
let canvasHeight = Constants.Teaser.canvasHeight

/* Local Types */
type stream
type mediaRecorder
type blob = ReBindings.Blob.t

@val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

/* Stream Bindings */
@send external captureStream: (ReBindings.Dom.element, int) => stream = "captureStream"

/* MediaRecorder Bindings */
@new external createMediaRecorder: (stream, {..}) => mediaRecorder = "MediaRecorder"
@send external start: (mediaRecorder, int) => unit = "start"
@send external stop: mediaRecorder => unit = "stop"
@get external state: mediaRecorder => string = "state"
@set external ondataavailable: (mediaRecorder, {..} => unit) => unit = "ondataavailable"
@set external onstop: (mediaRecorder, unit => unit) => unit = "onstop"
@send external pause: mediaRecorder => unit = "pause"
@send external resume: mediaRecorder => unit = "resume"

/* Canvas Context Extension */
@send
external drawImageScaled: (
  ReBindings.Canvas.context2d,
  ReBindings.Dom.element,
  float,
  float,
  float,
  float,
) => unit = "drawImage"
@send
external drawImagePos: (ReBindings.Canvas.context2d, ReBindings.Dom.element, float, float) => unit =
  "drawImage"
@send
external drawImageFull: (
  ReBindings.Canvas.context2d,
  ReBindings.Dom.element,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
  float,
) => unit = "drawImage"

external asDynamic: 'a => {..} = "%identity"
external castToBlob: 'a => blob = "%identity"

/* Image Loading Helper */
type logoResult = {
  img: option<ReBindings.Dom.element>,
  loaded: bool,
}

let loadLogo = () => {
  Promise.make((resolve, _reject) => {
    let img = ReBindings.Dom.createElement("img")
    ReBindings.Dom.setAttribute(img, "src", "images/logo.png")

    let onLoad = () => resolve({img: Some(img), loaded: true})
    let onError = () => resolve({img: None, loaded: false})

    /* Quick hack for events on img element which are not bound in ReBindings generic */
    let setOnLoad = (e, f) => {
      asDynamic(e)["onload"] = f
    }
    let setOnError = (e, f) => {
      asDynamic(e)["onerror"] = f
    }

    setOnLoad(img, onLoad)
    setOnError(img, onError)
  })
}

type recorderState = {
  mutable mediaRecorder: option<mediaRecorder>,
  mutable chunks: array<blob>,
  mutable streamLoopId: option<int>,
  mutable startTime: float,
  mutable fpsBuffer: array<float>,
  mutable fadeOpacity: float,
  mutable isTeasing: bool,
  mutable ghostCanvas: option<ReBindings.Dom.element>,
  mutable ghostCtx: option<ReBindings.Canvas.context2d>,
  /* Snapshot handling */
  mutable snapshotCanvas: option<ReBindings.Dom.element>,
}

let internalState = {
  mediaRecorder: None,
  chunks: [],
  streamLoopId: None,
  startTime: 0.0,
  fpsBuffer: [],
  fadeOpacity: 0.0,
  isTeasing: false,
  ghostCanvas: None,
  ghostCtx: None,
  snapshotCanvas: None,
}

module Overlay = {
  let getOrCreate = () => {
    let id = "teaser-overlay"
    switch ReBindings.Dom.getElementById(id)->Nullable.toOption {
    | Some(d) => d
    | None =>
      let div = ReBindings.Dom.createElement("div")
      ReBindings.Dom.setId(div, id)
      ReBindings.Dom.setAttribute(
        div,
        "style",
        "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:0;transition:opacity 0.1s linear;",
      )
      ReBindings.Dom.appendChild(ReBindings.Dom.documentBody, div)
      div
    }
  }

  let setOpacity = (opacity: float) => {
    switch ReBindings.Dom.getElementById("teaser-overlay")->Nullable.toOption {
    | Some(d) =>
      ReBindings.Dom.setAttribute(
        d,
        "style",
        "position:fixed;top:0;left:0;right:0;bottom:0;pointer-events:none;z-index:9999;background:black;opacity:" ++
        Float.toString(opacity) ++ ";transition:opacity 0.1s linear;",
      )
    | None => ()
    }
  }
}

let initGhost = () => {
  switch internalState.ghostCanvas {
  | Some(_) => ()
  | None =>
    let c = ReBindings.Dom.createElement("canvas")
    ReBindings.Dom.setWidth(c, canvasWidth)
    ReBindings.Dom.setHeight(c, canvasHeight)
    internalState.ghostCanvas = Some(c)

    let ctx = ReBindings.Canvas.getContext2d(c, "2d", {"alpha": false})
    internalState.ghostCtx = Some(ctx)
  }
}

let setSnapshot = (canvas: ReBindings.Dom.element) => {
  internalState.snapshotCanvas = Some(canvas)
}

let renderWatermark = (ctx: ReBindings.Canvas.context2d, logoImg: ReBindings.Dom.element) => {
  let logoWidth = 150.0
  let padding = 4.0
  let margin = 32.0
  let borderRadius = 16.0

  let w = ReBindings.Dom.getWidth(logoImg)->Belt.Int.toFloat
  let h = ReBindings.Dom.getHeight(logoImg)->Belt.Int.toFloat
  let imgAspect = h /. w
  let logoHeight = logoWidth *. imgAspect

  let boxWidth = logoWidth +. padding *. 2.0
  let boxHeight = logoHeight +. padding *. 2.0

  let ghostW = canvasWidth->Belt.Int.toFloat
  let ghostH = canvasHeight->Belt.Int.toFloat

  let boxX = ghostW -. boxWidth -. margin
  let boxY = ghostH -. boxHeight -. margin

  ReBindings.Canvas.save(ctx)

  /* Shadow */
  ReBindings.Canvas.setShadowColor(ctx, "rgba(0,0,0,0.15)")
  ReBindings.Canvas.setShadowBlur(ctx, 10.0)
  ReBindings.Canvas.setShadowOffsetY(ctx, 4.0)

  /* Box */
  ReBindings.Canvas.setFillStyle(ctx, "#ffffff")
  ReBindings.Canvas.beginPath(ctx)
  let checkRoundRect: 'a => bool = %raw("function(x) { return typeof x === 'function'; }")
  if checkRoundRect(asDynamic(ctx)["roundRect"]) {
    let roundRect: (ReBindings.Canvas.context2d, float, float, float, float, float) => unit = %raw(
      "(ctx, x, y, w, h, r) => ctx.roundRect(x,y,w,h,r)"
    )
    roundRect(ctx, boxX, boxY, boxWidth, boxHeight, borderRadius)
  } else {
    ReBindings.Canvas.rect(ctx, boxX, boxY, boxWidth, boxHeight)
  }
  ReBindings.Canvas.fill(ctx)

  /* Reset Shadow */
  ReBindings.Canvas.setShadowColor(ctx, "transparent")
  ReBindings.Canvas.setShadowBlur(ctx, 0.0)
  ReBindings.Canvas.setShadowOffsetY(ctx, 0.0)

  /* Image */
  let imgX = boxX +. padding
  let imgY = boxY +. padding

  drawImageScaled(ctx, logoImg, imgX, imgY, logoWidth, logoHeight)

  ReBindings.Canvas.restore(ctx)
}

let renderFrame = (
  sourceCanvas: ReBindings.Dom.element,
  includeLogo: bool,
  logoState: logoResult,
) => {
  switch internalState.ghostCtx {
  | Some(ctx) =>
    let sw = ReBindings.Dom.getWidth(sourceCanvas)->Belt.Int.toFloat
    let sh = ReBindings.Dom.getHeight(sourceCanvas)->Belt.Int.toFloat

    if sw > 0.0 {
      let dw = canvasWidth->Belt.Int.toFloat
      let dh = canvasHeight->Belt.Int.toFloat

      let sourceAspect = sw /. sh
      let destAspect = dw /. dh

      let (rw, rh, rx, ry) = if sourceAspect > destAspect {
        let h = dh
        let w = dh *. sourceAspect
        let x = (dw -. w) /. 2.0
        (w, h, x, 0.0)
      } else {
        let w = dw
        let h = dw /. sourceAspect
        let y = (dh -. h) /. 2.0
        (w, h, 0.0, y)
      }

      ReBindings.Canvas.setFillStyle(ctx, "#000")
      ReBindings.Canvas.fillRect(ctx, 0.0, 0.0, dw, dh)

      drawImageScaled(ctx, sourceCanvas, rx, ry, rw, rh)

      /* Snapshot Overlay */
      if internalState.fadeOpacity > 0.01 {
        switch internalState.snapshotCanvas {
        | Some(snap) =>
          ReBindings.Canvas.save(ctx)
          ReBindings.Canvas.setGlobalAlpha(ctx, internalState.fadeOpacity)
          ReBindings.Canvas.save(ctx)
          ReBindings.Canvas.setGlobalAlpha(ctx, internalState.fadeOpacity)
          drawImagePos(ctx, snap, 0.0, 0.0)
          ReBindings.Canvas.restore(ctx)
        | None => ()
        }
      }

      /* Watermark */
      if includeLogo && logoState.loaded {
        switch logoState.img {
        | Some(img) => renderWatermark(ctx, img)
        | None => ()
        }
      }
    }
  | None => ()
  }
  Logger.trace(~module_="TeaserRecorder", ~message="FRAME_RENDERED", ())
}

/* Main Loop */
let startAnimationLoop = (includeLogo: bool, logoState: logoResult) => {
  let rec draw = () => {
    let sourceCanvasOpt =
      ReBindings.Dom.querySelector(
        ReBindings.Dom.documentBody,
        ".pnlm-render-container canvas",
      )->Nullable.toOption

    switch sourceCanvasOpt {
    | Some(sc) => renderFrame(sc, includeLogo, logoState)
    | None => ()
    }

    /* FPS Calc - optional, kept for tracking */

    internalState.streamLoopId = Some(requestAnimationFrame(draw))
  }

  switch internalState.streamLoopId {
  | Some(id) => cancelAnimationFrame(id)
  | None => ()
  }

  internalState.streamLoopId = Some(requestAnimationFrame(draw))
}

let startRecording = () => {
  initGhost()

  /* Capture stream from GHOST canvas, not source */
  /* If ghost canvas is not ready, error out */
  switch internalState.ghostCanvas {
  | None =>
    Logger.error(~module_="TeaserRecorder", ~message="GHOST_CANVAS_NOT_READY", ())
    false
  | Some(canvas) => {
      let stream = captureStream(canvas, 60)
      let userAgent = ReBindings.Window.navigatorUserAgent
      let mimeType = if Js.String.includes("Firefox", userAgent) {
        "video/webm;codecs=vp8"
      } else {
        "video/webm;codecs=vp9,opus"
      }

      Logger.info(
        ~module_="TeaserRecorder",
        ~message="RECORDING_START",
        ~data={
          "width": canvasWidth,
          "height": canvasHeight,
          "mimeType": mimeType,
        },
        (),
      )

      let options = {"mimeType": mimeType, "videoBitsPerSecond": 10000000}

      try {
        let recorder = createMediaRecorder(stream, options)

        internalState.chunks = []
        internalState.mediaRecorder = Some(recorder)
        internalState.startTime = Date.now()
        internalState.isTeasing = true

        recorder->ondataavailable(event => {
          if event["data"]["size"] > 0 {
            let b = castToBlob(event["data"])
            Logger.trace(
              ~module_="TeaserRecorder",
              ~message="DATA_AVAILABLE",
              ~data={"size": event["data"]["size"]},
              (),
            )
            let _ = Js.Array.push(b, internalState.chunks)
          }
        })

        recorder->start(100)
        true
      } catch {
      | JsExn(e) => {
          let msg = e->JsExn.message->Option.getOr("Unknown")
          Logger.error(
            ~module_="TeaserRecorder",
            ~message="RECORDING_FAILED",
            ~data={"error": msg},
            (),
          )
          false
        }
      | _ => {
          Logger.error(
            ~module_="TeaserRecorder",
            ~message="RECORDING_FAILED",
            ~data={"error": "Unknown"},
            (),
          )
          false
        }
      }
    }
  }
}

let pauseRecording = () => {
  switch internalState.mediaRecorder {
  | Some(r) =>
    let state = state(r)
    if state == "recording" {
      pause(r)
    }
  | None => ()
  }
}

let resumeRecording = () => {
  switch internalState.mediaRecorder {
  | Some(r) =>
    let state = state(r)
    if state == "paused" {
      resume(r)
    }
  | None => ()
  }
}

let stopRecording = () => {
  internalState.isTeasing = false
  switch internalState.mediaRecorder {
  | Some(recorderInst) =>
    if state(recorderInst) != "inactive" {
      stop(recorderInst)
      Logger.info(
        ~module_="TeaserRecorder",
        ~message="RECORDING_STOP",
        ~data={"chunkCount": Array.length(internalState.chunks)},
        (),
      )
    }
  | None => ()
  }

  switch internalState.streamLoopId {
  | Some(id) => cancelAnimationFrame(id)
  | None => ()
  }
}

let getRecordedBlobs = () => internalState.chunks

let setFadeOpacity = (op: float) => {
  internalState.fadeOpacity = op
  Overlay.setOpacity(op)
}

let getGhostCanvas = () => internalState.ghostCanvas
