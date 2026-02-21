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

type headlessMotionProfile = {
  skipAutoForward: bool,
  startAtWaypoint: bool,
  includeIntroPan: bool,
}

external castHeadlessMotionProfile: 'a => headlessMotionProfile = "%identity"

let readHeadlessMotionProfile = (): headlessMotionProfile =>
  castHeadlessMotionProfile(
    %raw(`(() => {
      const p = (typeof window !== "undefined" && window.__VTB_HEADLESS_MOTION_PROFILE__) ? window.__VTB_HEADLESS_MOTION_PROFILE__ : {};
      return {
        skipAutoForward: typeof p.skipAutoForward === "boolean" ? p.skipAutoForward : false,
        startAtWaypoint: typeof p.startAtWaypoint === "boolean" ? p.startAtWaypoint : true,
        includeIntroPan: typeof p.includeIntroPan === "boolean" ? p.includeIntroPan : false
      };
    })()`),
  )

let resolveTeaserStartView = (state: state): option<(float, float, float)> => {
  Belt.Array.get(state.scenes, state.activeIndex)->Option.flatMap(scene => {
    let waypointCandidates = scene.hotspots->Belt.Array.keep(h =>
      switch h.waypoints {
      | Some(w) => Belt.Array.length(w) > 0
      | None => false
      }
    )
    let candidate =
      waypointCandidates
      ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
      ->Option.orElse(waypointCandidates->Belt.Array.get(0))
      ->Option.orElse(
        scene.hotspots
        ->Belt.Array.getBy(h => h.isReturnLink != Some(true))
        ->Option.orElse(scene.hotspots->Belt.Array.get(0)),
      )

    candidate->Option.map(h => (
      h.startYaw->Option.getOr(h.yaw),
      h.startPitch->Option.getOr(h.pitch),
      h.startHfov->Option.getOr(h.targetHfov->Option.getOr(ViewerSystem.getCorrectHfov())),
    ))
  })
}

let centerViewerAtWaypointStart = async (~getState: unit => state) => {
  switch resolveTeaserStartView(getState()) {
  | Some((yaw, pitch, hfov)) =>
    let rec applyWhenReady = async (attemptsLeft: int) => {
      switch ViewerSystem.getActiveViewer()->Nullable.toOption {
      | Some(v) if ViewerSystem.isViewerReady(v) =>
        Viewer.setYaw(v, yaw, false)
        Viewer.setPitch(v, pitch, false)
        Viewer.setHfov(v, hfov, false)
      | _ if attemptsLeft > 0 =>
        await Playback.wait(80)
        await applyWhenReady(attemptsLeft - 1)
      | _ => ()
      }
    }

    await applyWhenReady(20)
    await Playback.wait(60)
  | None => ()
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

  let startHeadlessTeaser = async (
    format: string,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onCancel: option<unit => unit>=?,
  ) => {
    let state = getState()
    if state.isLinking {
      Logger.warn(~module_="TeaserLogic", ~message="TEASER_BLOCKED_BY_LINKING", ())
    } else if Array.length(state.scenes) == 0 {
      ()
    } else if signalIsAborted(signal) {
      ()
    } else {
      let safeFormat = switch format {
      | "mp4" => "mp4"
      | _ => "webm"
      }
      let safeName = String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_")
      let filename = "Teaser_" ++ safeName ++ "." ++ safeFormat
      let canCancel = switch onCancel {
      | Some(_) => true
      | None => false
      }
      let opId = OperationLifecycle.start(
        ~type_=OperationLifecycle.Teaser,
        ~scope=Ambient,
        ~phase="Preparing",
        ~cancellable=canCancel,
        ~visibleAfterMs=250,
        ~meta=Logger.castToJson({
          "format": safeFormat,
          "sceneCount": Belt.Array.length(state.scenes),
        }),
        (),
      )
      onCancel->Option.forEach(cb => OperationLifecycle.registerCancel(opId, cb))

      dispatch(Actions.SetIsTeasing(true))
      ProgressBar.updateProgressBar(0.0, "Preparing teaser...", ~visible=true, ~title="Teaser", ())

      let result = await Server.generateServerTeaser(
        state,
        safeFormat,
        Some(
          (pct, msg) => {
            let phase = if pct < 25 {
              "Uploading"
            } else if pct < 95 {
              "Processing"
            } else {
              "Finalizing"
            }
            let pctF = Belt.Int.toFloat(pct)
            OperationLifecycle.progress(opId, pctF, ~message=msg, ~phase, ())
            ProgressBar.updateProgressBar(
              Belt.Int.toFloat(pct),
              msg,
              ~visible=true,
              ~title=phase,
              (),
            )
          },
        ),
        ~signal?,
      )

      dispatch(Actions.SetIsTeasing(false))
      ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())

      if signalIsAborted(signal) {
        if OperationLifecycle.isActive(opId) {
          OperationLifecycle.cancel(opId)
        }
        ()
      } else {
        switch result {
        | Ok(blob) =>
          if OperationLifecycle.isActive(opId) {
            OperationLifecycle.complete(opId, ~result="Teaser ready", ())
          }
          DownloadSystem.saveBlob(blob, filename)
        | Error(msg) =>
          if msg == "AbortError" {
            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.cancel(opId)
            }
            ()
          } else {
            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.fail(opId, msg)
            }
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
      }
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
    if style == "fast" && format == "webm" {
      await startHeadlessTeaser(format, ~getState, ~dispatch, ~signal?)
      ()
    } else {
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
            format,
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
                  "Cinematic_" ++
                  String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_") ++ ".mp4",
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
}

let startHeadlessTeaserForWindow = (_includeLogo: bool, _format: string, skipAutoForward: bool) => {
  let getState = AppContext.getBridgeState
  let dispatch = AppContext.getBridgeDispatch()
  if getState().simulation.status == Running {
    Promise.resolve()
  } else {
    let profile = readHeadlessMotionProfile()
    let effectiveSkipAutoForward = skipAutoForward || profile.skipAutoForward
    let run = async () => {
      dispatch(Actions.SetIsTeasing(true))

      if profile.startAtWaypoint && !profile.includeIntroPan {
        await centerViewerAtWaypointStart(~getState)
      }

      dispatch(
        Actions.StartAutoPilot(
          getState().navigationState.currentJourneyId,
          effectiveSkipAutoForward,
        ),
      )

      let startedAt = Date.now()
      let rec waitForCompletion = (didStart: bool) => {
        let status = getState().simulation.status
        if status == Running {
          Playback.wait(250)->Promise.then(_ => waitForCompletion(true))
        } else if didStart {
          dispatch(Actions.SetIsTeasing(false))
          Promise.resolve()
        } else if Date.now() -. startedAt > 120000.0 {
          dispatch(Actions.SetIsTeasing(false))
          Promise.resolve()
        } else {
          Playback.wait(120)->Promise.then(_ => waitForCompletion(false))
        }
      }

      await waitForCompletion(false)
    }

    run()
  }
}

let startCinematicTeaserForWindow = (includeLogo: bool, format: string, skipAutoForward: bool) => {
  startHeadlessTeaserForWindow(includeLogo, format, skipAutoForward)
}

let isAutoPilotActiveForWindow = () => AppContext.getBridgeState().simulation.status == Running

let _ = %raw(`
  ((startHeadlessTeaser, startCinematicTeaser, isAutoPilotActive) => {
    if (typeof window !== "undefined") {
      window.startHeadlessTeaser = startHeadlessTeaser
      window.startCinematicTeaser = startCinematicTeaser
      window.__VTB_START_TEASER__ = startHeadlessTeaser
      window.isAutoPilotActive = isAutoPilotActive
    }
  })
`)(startHeadlessTeaserForWindow, startCinematicTeaserForWindow, isAutoPilotActiveForWindow)
