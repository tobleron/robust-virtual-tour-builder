/* src/systems/TeaserLogic.res */

open ReBindings
open Types

// --- MODULE ALIASES (extracted for testability) ---
module Recorder = TeaserRecorder.Recorder
module Pathfinder = TeaserPathfinder
module Server = ServerTeaser.Server
module State = TeaserStyleConfig
module Playback = TeaserPlayback
module Manager = TeaserManagerLogic.Manager

type headlessMotionProfile = TeaserLogicHelpers.headlessMotionProfile

let readHeadlessMotionProfile = (): headlessMotionProfile => {
  TeaserLogicHelpers.readHeadlessMotionProfile()
}

let readMotionManifest = (): option<motionManifest> => {
  TeaserLogicHelpers.readMotionManifest()
}

let resolveTeaserStartView = (state: state): option<(float, float, float)> => {
  TeaserLogicHelpers.resolveTeaserStartView(state)
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
