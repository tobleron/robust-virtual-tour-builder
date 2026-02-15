/* src/systems/TeaserLogic.res */

open ReBindings
open Types

// --- CONSTANTS ---
let canvasWidth = Constants.Teaser.canvasWidth
let canvasHeight = Constants.Teaser.canvasHeight

// --- BINDINGS (INTERNAL) ---
@val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
@val external cancelAnimationFrame: int => unit = "cancelAnimationFrame"
@val external clearTimeout: int => unit = "clearTimeout"

// --- MODULE ALIASES (extracted for testability) ---
module Recorder = TeaserRecorder.Recorder
module Pathfinder = TeaserPathfinder
module Server = ServerTeaser.Server
module State = TeaserStyleConfig
module Playback = TeaserPlayback

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
        await Playback.wait(1000)
        if getState().simulation.status == Running {
          await check()
        }
      }
      await check()
      await Playback.wait(500)
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
            await Playback.wait(500)
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
