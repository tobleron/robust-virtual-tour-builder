/* src/systems/TeaserRecorderLogic.res */

open ReBindings
open TeaserRecorderTypes

let loadLogo = () => {
  Promise.make((resolve, _reject) => {
    let img = Dom.createElement("img")
    Dom.setAttribute(img, "src", "images/logo.png")

    let onLoad = () => resolve({img: Some(img), loaded: true})
    let onError = () => resolve({img: None, loaded: false})

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

let initGhost = () => {
  switch internalState.ghostCanvas {
  | Some(_) => ()
  | None =>
    let c = Dom.createElement("canvas")
    Dom.setWidth(c, canvasWidth)
    Dom.setHeight(c, canvasHeight)
    internalState.ghostCanvas = Some(c)

    let ctx = Canvas.getContext2d(c, "2d", {"alpha": false})
    internalState.ghostCtx = Some(ctx)
  }
}

let setSnapshot = (canvas: Dom.element) => {
  internalState.snapshotCanvas = Some(canvas)
}

let renderWatermark = (ctx: Canvas.context2d, logoImg: Dom.element) => {
  let logoWidth = 150.0
  let padding = 4.0
  let margin = 32.0
  let borderRadius = 16.0

  let w = Dom.getWidth(logoImg)->Belt.Int.toFloat
  let h = Dom.getHeight(logoImg)->Belt.Int.toFloat
  let imgAspect = h /. w
  let logoHeight = logoWidth *. imgAspect

  let boxWidth = logoWidth +. padding *. 2.0
  let boxHeight = logoHeight +. padding *. 2.0

  let ghostW = canvasWidth->Belt.Int.toFloat
  let ghostH = canvasHeight->Belt.Int.toFloat

  let boxX = ghostW -. boxWidth -. margin
  let boxY = ghostH -. boxHeight -. margin

  Canvas.save(ctx)

  /* Shadow */
  Canvas.setShadowColor(ctx, "rgba(0,0,0,0.15)")
  Canvas.setShadowBlur(ctx, 10.0)
  Canvas.setShadowOffsetY(ctx, 4.0)

  /* Box */
  Canvas.setFillStyle(ctx, "var(--sidebar-bg)")
  Canvas.beginPath(ctx)
  let checkRoundRect: 'a => bool = %raw("function(x) { return typeof x === 'function'; }")
  if checkRoundRect(asDynamic(ctx)["roundRect"]) {
    let roundRect: (Canvas.context2d, float, float, float, float, float) => unit = %raw(
      "(ctx, x, y, w, h, r) => ctx.roundRect(x,y,w,h,r)"
    )
    roundRect(ctx, boxX, boxY, boxWidth, boxHeight, borderRadius)
  } else {
    Canvas.rect(ctx, boxX, boxY, boxWidth, boxHeight)
  }
  Canvas.fill(ctx)

  /* Reset Shadow */
  Canvas.setShadowColor(ctx, "transparent")
  Canvas.setShadowBlur(ctx, 0.0)
  Canvas.setShadowOffsetY(ctx, 0.0)

  /* Image */
  let imgX = boxX +. padding
  let imgY = boxY +. padding

  drawImageScaled(ctx, logoImg, imgX, imgY, logoWidth, logoHeight)

  Canvas.restore(ctx)
}

let renderFrame = (
  sourceCanvas: Dom.element,
  includeLogo: bool,
  logoState: logoResult,
) => {
  switch internalState.ghostCtx {
  | Some(ctx) =>
    let sw = Dom.getWidth(sourceCanvas)->Belt.Int.toFloat
    let sh = Dom.getHeight(sourceCanvas)->Belt.Int.toFloat

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

      Canvas.setFillStyle(ctx, "#000")
      Canvas.fillRect(ctx, 0.0, 0.0, dw, dh)

      drawImageScaled(ctx, sourceCanvas, rx, ry, rw, rh)

      /* Snapshot Overlay */
      if internalState.fadeOpacity > 0.01 {
        switch internalState.snapshotCanvas {
        | Some(snap) =>
          Canvas.save(ctx)
          Canvas.setGlobalAlpha(ctx, internalState.fadeOpacity)
          Canvas.save(ctx)
          Canvas.setGlobalAlpha(ctx, internalState.fadeOpacity)
          drawImagePos(ctx, snap, 0.0, 0.0)
          Canvas.restore(ctx)
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
}

/* Main Loop */
let startAnimationLoop = (includeLogo: bool, logoState: logoResult) => {
  let rec draw = () => {
    let sourceCanvasOpt =
      Dom.querySelector(
        Dom.documentBody,
        ".pnlm-render-container canvas",
      )->Nullable.toOption

    switch sourceCanvasOpt {
    | Some(sc) => renderFrame(sc, includeLogo, logoState)
    | None => ()
    }

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

  switch internalState.ghostCanvas {
  | None =>
    Logger.error(~module_="TeaserRecorder", ~message="GHOST_CANVAS_NOT_READY", ())
    false
  | Some(canvas) => {
      let stream = captureStream(canvas, 60)
      let userAgent = Window.navigatorUserAgent
      let mimeType = if String.includes(userAgent, "Firefox") {
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
            let _ = Array.push(internalState.chunks, b)
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
  TeaserRecorderOverlay.setOpacity(op)
}

let getGhostCanvas = () => internalState.ghostCanvas
