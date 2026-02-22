/* src/systems/TeaserLogic.res */

open ReBindings
open Types

// --- MODULE ALIASES (extracted for testability) ---
module Recorder = TeaserRecorder.Recorder
module Pathfinder = TeaserPathfinder
module Server = ServerTeaser.Server
module State = TeaserStyleConfig
module Playback = TeaserPlayback
module StyleCatalog = TeaserStyleCatalog
module RenderRegistry = TeaserRendererRegistry
module OfflineCfrRenderer = TeaserOfflineCfrRenderer

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

let readMotionManifest = (): option<motionManifest> => {
  let raw = %raw(`window.__VTB_MOTION_MANIFEST__`)
  if %raw(`(m => m !== null && typeof m === 'object')(raw)`) {
    switch JsonCombinators.Json.decode(raw, JsonParsers.Domain.motionManifest) {
    | Ok(m) => Some(m)
    | Error(msg) =>
      Logger.error(
        ~module_="TeaserLogic",
        ~message="MANIFEST_DECODE_FAILED",
        ~data=Some(Logger.castToJson({"error": msg})),
        (),
      )
      None
    }
  } else {
    None
  }
}

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

  let startHeadlessTeaserWithStyle = async (
    format: string,
    ~styleId: option<string>,
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
      let selectedStyle =
        styleId
        ->Option.map(raw => StyleCatalog.fromString(raw))
        ->Option.getOr(StyleCatalog.defaultStyle)
      if !StyleCatalog.isAvailable(selectedStyle) {
        NotificationManager.dispatch({
          id: "",
          importance: Warning,
          context: Operation("teaser"),
          message: StyleCatalog.label(selectedStyle) ++ " teaser style is not available yet.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Warning),
          dismissible: true,
          createdAt: Date.now(),
        })
        ()
      } else {
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
            "format": format,
            "style": StyleCatalog.toString(selectedStyle),
            "sceneCount": Belt.Array.length(state.scenes),
          }),
          (),
        )
        onCancel->Option.forEach(cb => OperationLifecycle.registerCancel(opId, cb))

        dispatch(Actions.SetIsTeasing(true))
        ProgressBar.updateProgressBar(
          0.0,
          "Calculating teaser path...",
          ~visible=true,
          ~title="Teaser",
          (),
        )

        try {
          OperationLifecycle.progress(
            opId,
            5.0,
            ~message="Building simulation motion manifest|Preparing deterministic timeline",
            ~phase="Preparing",
            (),
          )
          ProgressBar.updateProgressBar(
            5.0,
            "Building " ++
            StyleCatalog.label(
              selectedStyle,
            ) ++ " motion manifest|Preparing deterministic timeline",
            ~visible=true,
            ~title="Teaser",
            (),
          )
          switch RenderRegistry.buildManifestForStyle(
            state,
            ~style=selectedStyle,
            ~skipAutoForward=Constants.Teaser.HeadlessMotion.skipAutoForward,
            ~includeIntroPan=Constants.Teaser.HeadlessMotion.includeIntroPan,
          ) {
          | Error(reason) =>
            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.fail(opId, reason)
            }
            dispatch(Actions.SetIsTeasing(false))
            ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
          | Ok(manifest) =>
            let success = await OfflineCfrRenderer.renderWebMDeterministic(
              manifest,
              true,
              ~getState,
              ~dispatch,
              ~signal?,
              ~onProgress=(pct, msg, phaseName) => {
                OperationLifecycle.progress(opId, pct, ~message=msg, ~phase=phaseName, ())
                ProgressBar.updateProgressBar(pct, msg, ~visible=true, ~title="Teaser", ())
              },
            )

            if success {
              OperationLifecycle.progress(
                opId,
                99.0,
                ~message="Finalizing teaser package|Almost done",
                ~phase="Finalizing",
                (),
              )
              ProgressBar.updateProgressBar(
                99.0,
                "Finalizing teaser package|Almost done",
                ~visible=true,
                ~title="Teaser",
                (),
              )

              let safeName =
                String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
              await finalizeTeaser(
                format,
                "Teaser_" ++ StyleCatalog.toString(selectedStyle) ++ "_" ++ safeName,
              )

              if OperationLifecycle.isActive(opId) {
                OperationLifecycle.complete(opId, ~result="Teaser ready", ())
              }
            } else if OperationLifecycle.isActive(opId) {
              OperationLifecycle.fail(opId, "Rendering failed")
            }
            dispatch(Actions.SetIsTeasing(false))
            ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
          }
        } catch {
        | exn =>
          dispatch(Actions.SetIsTeasing(false))
          ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
          Recorder.stopRecording()

          let (msg, _) = Logger.getErrorDetails(exn)
          if String.includes(msg, "AbortError") || signalIsAborted(signal) {
            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.cancel(opId)
            }
          } else {
            Logger.error(
              ~module_="TeaserLogic",
              ~message="TEASER_FAILED",
              ~data=Some(Logger.castToJson({"error": msg})),
              (),
            )
            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.fail(opId, "Teaser generation failed: " ++ msg)
            }
          }
        }
      }
    }
  }

  let startHeadlessTeaser = (
    format: string,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onCancel: option<unit => unit>=?,
  ) =>
    startHeadlessTeaserWithStyle(format, ~styleId=None, ~getState, ~dispatch, ~signal?, ~onCancel?)

  let startAutoTeaser = (
    format: string,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onCancel: option<unit => unit>=?,
  ) => startHeadlessTeaser(format, ~getState, ~dispatch, ~signal?, ~onCancel?)
}

let startHeadlessTeaserForWindow = (_includeLogo: bool, _format: string, skipAutoForward: bool) => {
  let getState = AppContext.getBridgeState
  let dispatch = AppContext.getBridgeDispatch()
  if getState().simulation.status == Running {
    Promise.resolve()
  } else {
    let manifest = readMotionManifest()
    let profile = readHeadlessMotionProfile()
    let effectiveSkipAutoForward = skipAutoForward || profile.skipAutoForward

    let run = async () => {
      dispatch(Actions.SetIsTeasing(true))

      switch manifest {
      | Some(m) => await Playback.playManifest(m, ~getState, ~dispatch)
      | None =>
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
            Promise.resolve()
          } else if Date.now() -. startedAt > 120000.0 {
            Promise.resolve()
          } else {
            Playback.wait(120)->Promise.then(_ => waitForCompletion(false))
          }
        }

        await waitForCompletion(false)
      }

      dispatch(Actions.SetIsTeasing(false))
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
