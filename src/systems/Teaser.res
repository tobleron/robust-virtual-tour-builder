/* src/systems/Teaser.res - Consolidated Teaser System */

open ReBindings
open Types
open EventBus

// --- CONSTANTS ---

let canvasWidth = Constants.Teaser.canvasWidth
let canvasHeight = Constants.Teaser.canvasHeight

// --- BINDINGS (INTERNAL) ---

@val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"
@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

/* Helper to wait */
let wait = (ms: int) =>
  Promise.make((resolve, _) => {
    let _ = setTimeout(() => resolve(), ms)
  })

// --- MODULE: RECORDER ---

module Recorder = {
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
      switch Dom.querySelector(
        Dom.documentBody,
        ".pnlm-render-container canvas",
      )->Nullable.toOption {
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
    internalState := {...internalState.contents, isTeasing: false}
    internalState.contents.mediaRecorder->Option.forEach(r =>
      if state(r) != "inactive" {
        stop(r)
      }
    )
    internalState.contents.streamLoopId->Option.forEach(cancelAnimationFrame)
  }

  let pause = () =>
    internalState.contents.mediaRecorder->Option.forEach(r =>
      if state(r) == "recording" {
        pause(r)
      }
    )
  let resume = () =>
    internalState.contents.mediaRecorder->Option.forEach(r =>
      if state(r) == "paused" {
        resume(r)
      }
    )
  let setFadeOpacity = op => {
    internalState := {...internalState.contents, fadeOpacity: op}
    Overlay.setOpacity(op)
  }
}

// --- MODULE: STATE/CONFIG ---

module State = {
  type teaserConfig = {clipDuration: float, transitionDuration: float, cameraPanOffset: float}
  let fastConfig = {clipDuration: 2500.0, transitionDuration: 1000.0, cameraPanOffset: 20.0}
  let slowConfig = {clipDuration: 4000.0, transitionDuration: 1500.0, cameraPanOffset: 30.0}
  let punchyConfig = {clipDuration: 1800.0, transitionDuration: 600.0, cameraPanOffset: 0.0}
  let getConfigForStyle = (style: string) => {
    switch style {
    | "punchy" => punchyConfig
    | "slow" => slowConfig
    | _ => fastConfig
    }
  }
}

// --- MODULE: PATHFINDER ---

module Pathfinder = {
  type step = BackendApi.step
  let getWalkPath = (scenes, skipAutoForward) =>
    BackendApi.calculatePath({type_: "walk", scenes, skipAutoForward})
  let getTimelinePath = (timeline, scenes, skipAutoForward) =>
    BackendApi.calculatePath({type_: "timeline", timeline, scenes, skipAutoForward})
}

// --- MODULE: PLAYBACK ---

module Playback = {
  let waitForViewerReady = async (sceneId: string) => {
    let start = Date.now()
    let rec check = async () => {
      if Date.now() -. start > 12000.0 {
        false
      } else {
        switch Viewer.instance->Nullable.toOption {
        | Some(v) if Viewer.isLoaded(v) && Viewer.getScene(v) == sceneId =>
          await wait(200)
          true
        | _ =>
          await wait(100)
          await check()
        }
      }
    }
    await check()
  }

  let animatePan = async (fromYaw, toYaw, pitch, duration) => {
    let start = Date.now()
    let rec loop = async () => {
      let p = (Date.now() -. start) /. duration
      if p < 1.0 {
        Viewer.instance
        ->Nullable.toOption
        ->Option.forEach(v => {
          Viewer.setYaw(v, fromYaw +. (toYaw -. fromYaw) *. p, false)
          Viewer.setPitch(v, pitch, false)
        })
        await wait(16)
        await loop()
      } else {
        Viewer.instance
        ->Nullable.toOption
        ->Option.forEach(v => {
          Viewer.setYaw(v, toYaw, false)
          Viewer.setPitch(v, pitch, false)
        })
      }
    }
    await loop()
  }

  let prepareFirstScene = async (step: Pathfinder.step, style, config: State.teaserConfig) => {
    let (iy, ip) = if style == "punchy" || style == "cinematic" {
      (step.arrivalView.yaw, step.arrivalView.pitch)
    } else {
      step.transitionTarget
      ->Option.map(t => (t.yaw -. config.cameraPanOffset, t.pitch))
      ->Option.getOr((0.0, 0.0))
    }
    let scenes = GlobalStateBridge.getState().scenes
    switch Belt.Array.get(scenes, step.idx) {
    | Some(scene) =>
      GlobalStateBridge.dispatch(SetActiveScene(step.idx, iy, ip, None))
      await wait(500)
      let _ = await waitForViewerReady(scene.id)
      Viewer.instance
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, iy, false)
        Viewer.setPitch(v, ip, false)
      })
      await wait(500)
    | None => ()
    }
  }

  let recordShot = async (_i, step: Pathfinder.step, style, config: State.teaserConfig) => {
    if style == "punchy" || style == "cinematic" {
      await wait(Belt.Int.fromFloat(config.clipDuration))
    } else {
      switch step.transitionTarget {
      | Some(t) =>
        await animatePan(t.yaw -. config.cameraPanOffset, t.yaw, t.pitch, config.clipDuration)
      | None => await wait(Belt.Int.fromFloat(config.clipDuration))
      }
    }
  }

  let transitionToNextShot = async (
    _i,
    nextStep: Pathfinder.step,
    style,
    config: State.teaserConfig,
  ) => {
    Recorder.internalState.contents.ghostCanvas->Option.forEach(g =>
      Recorder.internalState := {...Recorder.internalState.contents, snapshotCanvas: Some(g)}
    )
    Recorder.setFadeOpacity(1.0)
    await wait(50)
    Recorder.pause()
    let (ny, np) = if style == "punchy" {
      (nextStep.arrivalView.yaw, nextStep.arrivalView.pitch)
    } else {
      nextStep.transitionTarget
      ->Option.map(t => (t.yaw -. config.cameraPanOffset, t.pitch))
      ->Option.getOr((nextStep.arrivalView.yaw, nextStep.arrivalView.pitch))
    }
    let scenes = GlobalStateBridge.getState().scenes
    switch Belt.Array.get(scenes, nextStep.idx) {
    | Some(scene) =>
      GlobalStateBridge.dispatch(SetActiveScene(nextStep.idx, ny, np, None))
      await wait(500)
      let _ = await waitForViewerReady(scene.id)
      Viewer.instance
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, ny, false)
        Viewer.setPitch(v, np, false)
      })
      await wait(500)
    | None => ()
    }
    Recorder.resume()
    let startD = Date.now()
    let rec fade = async () => {
      let p = (Date.now() -. startD) /. config.transitionDuration
      if p < 1.0 {
        Recorder.setFadeOpacity(1.0 -. p)
        await wait(16)
        await fade()
      } else {
        Recorder.setFadeOpacity(0.0)
      }
    }
    await fade()
  }
}

// --- MODULE: SERVER ---

module Server = {
  let generateServerTeaser = (state: state, onProgress) => {
    let progress = (p, m) => onProgress->Option.forEach(cb => cb(p, m))
    progress(0, "Preparing Project Data...")
    let projectData = ProjectData.toJSON(state)
    let formData = FormData.newFormData()
    FormData.append(formData, "project_data", JSON.stringify(Obj.magic(projectData)))
    FormData.append(formData, "width", "1920")
    FormData.append(formData, "height", "1080")
    let added = ref(0)
    state.scenes->Belt.Array.forEach(s => {
      switch s.file {
      | File(f) =>
        FormData.appendWithFilename(formData, "files", f, s.name)
        added := added.contents + 1
      | Blob(f) =>
        FormData.appendWithFilename(formData, "files", f, s.name)
        added := added.contents + 1
        FormData.appendWithFilename(formData, "files", f, s.name)
        added := added.contents + 1
      | _ => ()
      }
    })
    progress(10, "Uploading " ++ Belt.Int.toString(added.contents) ++ " scenes...")
    RequestQueue.schedule(() => {
      Fetch.fetch(
        Constants.backendUrl ++ "/api/media/generate-teaser",
        Fetch.requestInit(~method="POST", ~body=formData, ()),
      )
      ->Promise.then(BackendApi.handleResponse)
      ->Promise.then(resResult => {
        switch resResult {
        | Ok(res) =>
          progress(50, "Rendering on Server...")
          Fetch.blob(res)->Promise.then(blob => Promise.resolve(Ok(blob)))
        | Error(msg) => Promise.resolve(Error(msg))
        }
      })
    })
    ->Promise.then(blobRes => {
      switch blobRes {
      | Ok(blob) =>
        progress(100, "Done!")
        Promise.resolve(Ok(blob))
      | Error(msg) => Promise.resolve(Error(msg))
      }
    })
    ->Promise.catch(err => {
      let (msg, _) = Logger.getErrorDetails(err)
      Promise.resolve(Error(msg))
    })
  }
}

// --- MODULE: MANAGER ---

module Manager = {
  let finalizeTeaser = async (format, baseName) => {
    let chunks = Recorder.internalState.contents.chunks
    if Array.length(chunks) > 0 {
      let blob = Blob.newBlob(chunks, {"type": "video/webm"})
      if format == "webm" {
        DownloadSystem.saveBlob(blob, baseName ++ ".webm")
      } else {
        let res = await VideoEncoder.transcodeWebMToMP4(blob, baseName, None)
        if res == Error("failed") {
          EventBus.dispatch(ShowNotification("Video transcoding failed", #Error))
        }
      }
    }
  }

  let startCinematicTeaser = async (includeLogo, format, skipAutoForward) => {
    let logoState = await Recorder.loadLogo()
    Recorder.startAnimationLoop(includeLogo, logoState)
    if Recorder.startRecording() {
      GlobalStateBridge.dispatch(
        StartAutoPilot(GlobalStateBridge.getState().currentJourneyId, skipAutoForward),
      )
      let rec check = async () => {
        await wait(1000)
        if GlobalStateBridge.getState().simulation.status == Running {
          await check()
        }
      }
      await check()
      await wait(500)
      Recorder.stopRecording()
      let safeName =
        String.replaceRegExp(
          GlobalStateBridge.getState().tourName,
          /[^a-z0-9]/gi,
          "_",
        )->String.toLowerCase
      await finalizeTeaser(format, "Teaser_Cinematic_" ++ safeName)
    }
  }

  let startAutoTeaser = async (style, includeLogo, format, skipAutoForward) => {
    let state = GlobalStateBridge.getState()
    if Array.length(state.scenes) == 0 {
      ()
    } else if style == "cinematic" && format == "mp4" {
      GlobalStateBridge.dispatch(SetIsTeasing(true))
      ProgressBar.updateProgressBar(
        0.0,
        "Server Generating...",
        ~visible=true,
        ~title="Uploading",
        (),
      )
      Server.generateServerTeaser(
        state,
        Some(
          (pct, msg) => {
            ProgressBar.updateProgressBar(
              Belt.Int.toFloat(pct),
              msg,
              ~visible=true,
              ~title=pct < 50 ? "Uploading" : "Processing",
              (),
            )
          },
        ),
      )
      ->Promise.then(res => {
        GlobalStateBridge.dispatch(SetIsTeasing(false))
        ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
        switch res {
        | Ok(blob) =>
          DownloadSystem.saveBlob(
            blob,
            "Cinematic_" ++ String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_") ++ ".mp4",
          )
        | Error(msg) =>
          EventBus.dispatch(ShowNotification("Server Generation Failed: " ++ msg, #Error))
        }
        Promise.resolve()
      })
      ->ignore
    } else {
      let config = State.getConfigForStyle(style)
      let logoState = await Recorder.loadLogo()
      let pathResult = await Pathfinder.getWalkPath(state.scenes, skipAutoForward)
      switch pathResult {
      | Ok(steps) =>
        Recorder.startAnimationLoop(includeLogo, logoState)
        if Recorder.startRecording() {
          try {
            await Playback.prepareFirstScene(steps[0]->Option.getOrThrow, style, config)
            for i in 0 to Array.length(steps) - 1 {
              await Playback.recordShot(i, steps[i]->Option.getOrThrow, style, config)
              if i < Array.length(steps) - 1 {
                await Playback.transitionToNextShot(
                  i,
                  steps[i + 1]->Option.getOrThrow,
                  style,
                  config,
                )
              }
            }
            Recorder.stopRecording()
            let safeName =
              String.replaceRegExp(
                GlobalStateBridge.getState().tourName,
                /[^a-z0-9]/gi,
                "_",
              )->String.toLowerCase
            await finalizeTeaser(format, "Teaser_" ++ style ++ "_" ++ safeName)
          } catch {
          | _ => Recorder.stopRecording()
          }
        }
      | Error(msg) =>
        EventBus.dispatch(ShowNotification("Failed to generate path: " ++ msg, #Error))
      }
    }
  }
}

// --- FACADE (TOP LEVEL) ---

let startAutoTeaser = Manager.startAutoTeaser
let startCinematicTeaser = Manager.startCinematicTeaser

// --- COMPATIBILITY ALIASES ---
module TeaserRecorder = Recorder
module TeaserManager = Manager
module TeaserState = State
module TeaserPlayback = Playback
module TeaserPathfinder = Pathfinder
