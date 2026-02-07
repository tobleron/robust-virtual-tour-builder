/* src/systems/TeaserLogic.res */

open ReBindings
open Types

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

// --- MODULE: MANAGER ---
module Manager = {
  let finalizeTeaser = async (format, baseName) => {
    let chunks = Recorder.getRecordedBlobs()
    if Array.length(chunks) > 0 {
      let blob = Blob.newBlob(chunks, {"type": "video/webm"})
      if format == "webm" {
        DownloadSystem.saveBlob(blob, baseName ++ ".webm")
      } else {
        let res = await VideoEncoder.transcodeWebMToMP4(blob, baseName, None)
        if res == Error("failed") {
          NotificationManager.dispatch({
            id: "",
            importance: Error,
            context: Operation("teaser"),
            message: "Video transcoding failed",
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
