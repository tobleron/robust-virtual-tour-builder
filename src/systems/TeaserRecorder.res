/* src/systems/TeaserRecorder.res */
open ReBindings

let canvasWidth = Constants.Teaser.canvasWidth
let canvasHeight = Constants.Teaser.canvasHeight

@val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"

type stream
type track
type mediaRecorder
type blob = Blob.t

@send external captureStream: (Dom.element, int) => stream = "captureStream"
@send external getTracks: stream => array<track> = "getTracks"
@send external requestFrame: track => unit = "requestFrame"
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
type teaserHudOverlay = {
  roomLabel: option<string>,
  activeFloor: string,
  visibleFloorIds: array<string>,
}
type hudScale = {
  sx: float,
  sy: float,
  uniform: float,
}

type recorderState = {
  mediaRecorder: option<mediaRecorder>,
  currentStream: option<stream>,
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
  currentStream: (None: option<stream>),
  chunks: ([]: array<blob>),
  streamLoopId: (None: option<int>),
  startTime: 0.0,
  fadeOpacity: 0.0,
  isTeasing: false,
  ghostCanvas: (None: option<Dom.element>),
  ghostCtx: (None: option<Canvas.context2d>),
  snapshotCanvas: (None: option<Dom.element>),
})

let requestDeterministicFrame = () => {
  internalState.contents.currentStream->Option.forEach(s => {
    let tracks = getTracks(s)
    tracks->Belt.Array.forEach(requestFrame)
  })
}

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

let loadLogo = (logo: option<Types.file>) =>
  Promise.make((resolve, _) => {
    let src = switch logo {
    | Some(f) => Types.fileToUrl(f)
    | None => "images/logo.png"
    }
    let img = Dom.createElement("img")
    Dom.setAttribute(img, "src", src)
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

let hdReferenceWidth = Constants.Teaser.HudReference.stageWidth
let hdReferenceHeight = Constants.Teaser.HudReference.stageHeight

let getHudScale = (): hudScale => {
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

let renderWatermark = (ctx, logoImg, scale: hudScale) => {
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

let renderRoomLabel = (ctx, roomLabel: string, scale: hudScale) => {
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
  ctx,
  activeFloor: string,
  visibleFloorIds: array<string>,
  scale: hudScale,
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

let renderFrame = (
  sourceCanvas,
  includeLogo,
  logoState: logoResult,
  ~overlay: option<teaserHudOverlay>=?,
) => {
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
      let hudScale = getHudScale()
      overlay->Option.forEach(data => {
        data.roomLabel->Option.forEach(roomLabel => {
          if roomLabel->String.trim != "" {
            renderRoomLabel(ctx, roomLabel, hudScale)
          }
        })
        renderFloorNav(ctx, data.activeFloor, data.visibleFloorIds, hudScale)
      })
      if includeLogo && logoState.loaded {
        switch logoState.img {
        | Some(img) => renderWatermark(ctx, img, hudScale)
        | None => ()
        }
      }
    }
  | None => ()
  }
}

let startAnimationLoop = (includeLogo, logoState) => {
  let rec draw = () => {
    switch Dom.querySelector(Dom.documentBody, ".panorama-layer.active canvas")->Nullable.toOption {
    | Some(sc) => renderFrame(sc, includeLogo, logoState)
    | None => ()
    }
    internalState := {...internalState.contents, streamLoopId: Some(requestAnimationFrame(draw))}
  }
  internalState.contents.streamLoopId->Option.forEach(cancelAnimationFrame)
  internalState := {...internalState.contents, streamLoopId: Some(requestAnimationFrame(draw))}
}

let startRecording = (~deterministic=false, ()) => {
  initGhost()
  let _ = Overlay.getOrCreate()
  switch internalState.contents.ghostCanvas {
  | None =>
    Logger.error(~module_="TeaserRecorder", ~message="GHOST_CANVAS_NOT_READY", ())
    false
  | Some(canvas) =>
    let fps = deterministic ? 0 : 60
    let stream = captureStream(canvas, fps)
    let mimeType = if String.includes(Window.navigatorUserAgent, "Firefox") {
      "video/webm;codecs=vp8"
    } else if (
      String.includes(Window.navigatorUserAgent, "Safari") &&
      !String.includes(Window.navigatorUserAgent, "Chrome")
    ) {
      "video/webm"
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
        "deterministic": deterministic,
      },
      (),
    )
    try {
      let r = createMediaRecorder(stream, {"mimeType": mimeType, "videoBitsPerSecond": 10000000})
      internalState := {
          ...internalState.contents,
          chunks: [],
          mediaRecorder: Some(r),
          currentStream: Some(stream),
          startTime: Date.now(),
          isTeasing: true,
        }
      r->ondataavailable(e => {
        let size = e["data"]["size"]
        if size > 0 {
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

    // Defer logging to see if chunks come in
    let _ = setTimeout(() => {
      Logger.info(
        ~module_="TeaserRecorder",
        ~message="RECORDING_STOP_ASYNC",
        ~data={"chunkCount": Array.length(internalState.contents.chunks)},
        (),
      )
    }, 200)

    Logger.info(~module_="TeaserRecorder", ~message="RECORDING_STOP_SENT", ())
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
  let snap = switch internalState.contents.snapshotCanvas {
  | Some(s) => s
  | None =>
    let c = Dom.createElement("canvas")
    Dom.setWidth(c, canvasWidth)
    Dom.setHeight(c, canvasHeight)
    internalState := {...internalState.contents, snapshotCanvas: Some(c)}
    c
  }
  switch Canvas.getContext2d(snap, "2d", {"alpha": false}) {
  | ctx => drawImagePos(ctx, canvas, 0.0, 0.0)
  }
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
  let requestDeterministicFrame = requestDeterministicFrame
  let renderFrame = renderFrame
  let internalState = internalState
}
