/* src/systems/TeaserLogic.res */

open ReBindings
open Types
external identity: 'a => 'b = "%identity"

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

// --- MODULE ALIASES (extracted for testability) ---
module Recorder = TeaserRecorder.Recorder
module Pathfinder = TeaserPathfinder
module Server = ServerTeaser.Server

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

// --- MODULE: PLAYBACK ---
module Playback = {
  let waitForViewerReady = async (sceneId: string) => {
    let start = Date.now()
    let rec check = async () => {
      if Date.now() -. start > 30000.0 {
        Logger.error(
          ~module_="TeaserLogic",
          ~message="WAIT_FOR_VIEWER_TIMEOUT",
          ~data=Some({"targetSceneId": sceneId}),
          (),
        )
        false
      } else {
        switch ViewerSystem.getActiveViewer()->Nullable.toOption {
        | Some(v) if Viewer.isLoaded(v) =>
          let currentId = ViewerSystem.Adapter.getMetaData(v, "sceneId")
          if currentId == Some(identity(sceneId)) {
            await wait(200)
            true
          } else {
            await wait(100)
            await check()
          }
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
        ViewerSystem.getActiveViewer()
        ->Nullable.toOption
        ->Option.forEach(v => {
          Viewer.setYaw(v, fromYaw +. (toYaw -. fromYaw) *. p, false)
          Viewer.setPitch(v, pitch, false)
        })
        await wait(16)
        await loop()
      } else {
        ViewerSystem.getActiveViewer()
        ->Nullable.toOption
        ->Option.forEach(v => {
          Viewer.setYaw(v, toYaw, false)
          Viewer.setPitch(v, pitch, false)
        })
      }
    }
    await loop()
  }

  let prepareFirstScene = async (
    step: Pathfinder.step,
    style,
    config: State.teaserConfig,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
  ) => {
    let (iy, ip) = if style == "punchy" || style == "cinematic" {
      (step.arrivalView.yaw, step.arrivalView.pitch)
    } else {
      step.transitionTarget
      ->Option.map(t => (t.yaw -. config.cameraPanOffset, t.pitch))
      ->Option.getOr((0.0, 0.0))
    }
    let scenes = getState().scenes
    switch Belt.Array.get(scenes, step.idx) {
    | Some(scene) =>
      dispatch(Actions.SetActiveScene(step.idx, iy, ip, None))
      await wait(500)
      let _ = await waitForViewerReady(scene.id)
      ViewerSystem.getActiveViewer()
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
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
  ) => {
    let internalState = Recorder.internalState
    internalState.contents.ghostCanvas->Option.forEach(g =>
      internalState := {...internalState.contents, snapshotCanvas: Some(g)}
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
    let scenes = getState().scenes
    switch Belt.Array.get(scenes, nextStep.idx) {
    | Some(scene) =>
      dispatch(Actions.SetActiveScene(nextStep.idx, ny, np, None))
      await wait(500)
      let _ = await waitForViewerReady(scene.id)
      ViewerSystem.getActiveViewer()
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

// --- MODULE: MANAGER ---
module Manager = {
  let signalIsAborted = signal =>
    switch signal {
    | Some(sig) => BrowserBindings.AbortSignal.aborted(sig)
    | None => false
    }

  let throwIfCancelled = (~signal: option<BrowserBindings.AbortSignal.t>=?) =>
    signal->Option.forEach(sig => {
      if BrowserBindings.AbortSignal.aborted(sig) {
        JsError.throwWithMessage("AbortError")
      }
    })

  let finalizeTeaser = async (format, baseName) => {
    let chunks = Recorder.getRecordedBlobs()
    if Array.length(chunks) > 0 {
      let blob = Blob.newBlob(chunks, {"type": "video/webm"})
      if format == "webm" {
        DownloadSystem.saveBlob(blob, baseName ++ ".webm")
      } else {
        let res = await VideoEncoder.transcodeWebMToMP4(blob, baseName, None)
        switch res {
        | Ok(_) => ()
        | Error(msg) =>
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("teaser"),
            message: "MP4 encoding failed (" ++ msg ++ "). Downloading WebM source instead.",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
          DownloadSystem.saveBlob(blob, baseName ++ ".webm")
        }
      }
    }
  }

  let startCinematicTeaser = async (
    includeLogo,
    format,
    skipAutoForward,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
  ) => {
    let logoState = await Recorder.loadLogo()
    Recorder.startAnimationLoop(includeLogo, logoState)
    if Recorder.startRecording() {
      dispatch(Actions.StartAutoPilot(getState().navigationState.currentJourneyId, skipAutoForward))
      let rec check = async () => {
        await wait(1000)
        if getState().simulation.status == Running {
          await check()
        }
      }
      await check()
      await wait(500)
      Recorder.stopRecording()
      let safeName =
        String.replaceRegExp(getState().tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
      await finalizeTeaser(format, "Teaser_Cinematic_" ++ safeName)
    }
  }

  let startAutoTeaser = async (
    style,
    includeLogo,
    format,
    skipAutoForward,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ) => {
    let state = getState()
    if state.isLinking {
      Logger.warn(~module_="TeaserLogic", ~message="TEASER_BLOCKED_BY_LINKING", ())
    } else if Array.length(state.scenes) == 0 {
      ()
    } else if style == "cinematic" && format == "mp4" {
      if signalIsAborted(signal) {
        ()
      } else {
        dispatch(Actions.SetIsTeasing(true))
        ProgressBar.updateProgressBar(
          0.0,
          "Server Generating...",
          ~visible=true,
          ~title="Uploading",
          (),
        )
        let _ = await Server.generateServerTeaser(
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
          ~signal?,
        )->Promise.then(res => {
          dispatch(Actions.SetIsTeasing(false))
          ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
          if signalIsAborted(signal) {
            Promise.resolve()
          } else {
            switch res {
            | Ok(blob) =>
              DownloadSystem.saveBlob(
                blob,
                "Cinematic_" ++ String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_") ++ ".mp4",
              )
            | Error(msg) =>
              if msg == "AbortError" {
                ()
              } else {
                NotificationManager.dispatch({
                  id: "",
                  importance: Error,
                  context: Operation("teaser"),
                  message: "Server Generation Failed: " ++ msg,
                  details: None,
                  action: None,
                  duration: NotificationTypes.defaultTimeoutMs(Error),
                  dismissible: true,
                  createdAt: Date.now(),
                })
              }
            }
            Promise.resolve()
          }
        })
      }
    } else {
      let config = State.getConfigForStyle(style)
      let logoState = await Recorder.loadLogo()
      let pathResult = await Pathfinder.getWalkPath(state.scenes, skipAutoForward, ~signal?)
      switch pathResult {
      | Ok(steps) =>
        Recorder.startAnimationLoop(includeLogo, logoState)
        if Recorder.startRecording() {
          throwIfCancelled(~signal?)
          try {
            await Playback.prepareFirstScene(
              steps[0]->Option.getOrThrow,
              style,
              config,
              ~getState,
              ~dispatch,
            )
            throwIfCancelled(~signal?)
            for i in 0 to Array.length(steps) - 1 {
              await Playback.recordShot(i, steps[i]->Option.getOrThrow, style, config)
              throwIfCancelled(~signal?)
              if i < Array.length(steps) - 1 {
                await Playback.transitionToNextShot(
                  i,
                  steps[i + 1]->Option.getOrThrow,
                  style,
                  config,
                  ~getState,
                  ~dispatch,
                )
                throwIfCancelled(~signal?)
              }
            }
            throwIfCancelled(~signal?)
            Recorder.stopRecording()
            await wait(500)
            throwIfCancelled(~signal?)
            let safeName =
              String.replaceRegExp(getState().tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
            await finalizeTeaser(format, "Teaser_" ++ style ++ "_" ++ safeName)
          } catch {
          | err =>
            Recorder.stopRecording()
            let msg = switch JsExn.fromException(err) {
            | Some(jsErr) => JsExn.message(jsErr)->Option.getOr("")
            | None => ""
            }
            if msg != "AbortError" {
              ()
            }
          }
        }
      | Error(msg) =>
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("teaser"),
          message: "Failed to generate path: " ++ msg,
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
    }
  }
}
