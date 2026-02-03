/* src/systems/Navigation/NavigationRenderer.res */

open Types
open ReBindings

let setupBlinks = () => (
  Float.fromInt(Constants.blinkDurationPreview),
  Float.fromInt(Constants.blinkDurationSimulation),
  Float.fromInt(Constants.blinkRatePreview),
  Float.fromInt(Constants.blinkRateSimulation),
)

let activeJourneyId = ref(None)

module AnimationLoop = {
  let rec loop = (
    v,
    j: journeyData,
    pd: Types.pathData,
    st,
    bst,
    cft,
    dispatch,
    req: React.ref<option<int>>,
    (),
  ) => {
    let state = GlobalStateBridge.getState()
    if activeJourneyId.contents == Some(j.journeyId) && !cft.contents {
      try {
        let prog = Math.min((Date.now() -. st) /. pd.panDuration, 1.0)
        if prog >= 1.0 {
          let sb = bst.contents->Option.getOr({
            let n = Date.now()
            bst := Some(n)
            n
          })
          let bel = Date.now() -. sb

          let (bdP, bdS, brP, brS) = setupBlinks()
          let dur = j.previewOnly ? bdP : bdS
          let rate = j.previewOnly ? brP : brS

          if ViewerSystem.isViewerReady(v) {
            Viewer.setPitch(v, pd.targetPitchForPan, false)
            Viewer.setYaw(v, pd.targetYawForPan, false)
            Viewer.setHfov(v, pd.targetHfovForPan, false)

            HotspotLine.updateLines(v, state, ())
            HotspotLine.updateSimulationArrow(
              v,
              pd.startPitch,
              pd.startYaw,
              pd.targetPitchForPan,
              pd.targetYawForPan,
              1.0,
              ~opacity=mod(Belt.Float.toInt(bel /. rate), 2) == 0 ? 1.0 : 0.0,
              ~waypoints=pd.waypoints->Belt.Array.map((w): PathInterpolation.point => {
                PathInterpolation.yaw: w.yaw,
                pitch: w.pitch,
              }),
              ~colorOverride=?j.previewOnly ? Some("red") : None,
              (),
            )
          }

          if bel < dur {
            req.current = Some(
              Window.requestAnimationFrame(() => loop(v, j, pd, st, bst, cft, dispatch, req, ())),
            )
          } else {
            // SYNC GUARD: Only finalize if FSM has moved past Preloading (i.e. texture is loaded)
            let currentFsm = state.navigationFsm
            switch currentFsm {
            | NavigationFSM.Transitioning(_) | NavigationFSM.Stabilizing(_) =>
              Logger.debug(
                ~module_="NavigationRenderer",
                ~message="FINALIZE_TRANSITION",
                ~data=Some({
                  "journeyId": j.journeyId,
                }),
                (),
              )
              cft := true
              dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
            | NavigationFSM.Idle =>
              // Already idle, just stop the loop
              cft := true
            | NavigationFSM.Error(_) =>
              // Error occurred (e.g. timeout), stop blinking and cancel
              cft := true
              EventBus.dispatch(NavCancelled)
            | _ =>
              // Texture not loaded yet (Preloading), keep blinking at the waypoint
              req.current = Some(
                Window.requestAnimationFrame(() => loop(v, j, pd, st, bst, cft, dispatch, req, ())),
              )
            }
          }
        } else {
          dispatch(Actions.DispatchNavigationFsmEvent(AnimationProgress(prog)))
          let (cp, cy) = NavigationLogic.calculateCameraPosition(~progress=prog, ~pathData=pd)

          if ViewerSystem.isViewerReady(v) {
            Viewer.setPitch(v, cp, false)
            Viewer.setYaw(v, cy, false)
            Viewer.setHfov(v, pd.startHfov +. (pd.targetHfovForPan -. pd.startHfov) *. prog, false)
            HotspotLine.updateLines(v, state, ())
            HotspotLine.updateSimulationArrow(
              v,
              pd.startPitch,
              pd.startYaw,
              pd.targetPitchForPan,
              pd.targetYawForPan,
              prog,
              ~opacity=1.0,
              ~waypoints=pd.waypoints->Belt.Array.map((w): PathInterpolation.point => {
                PathInterpolation.yaw: w.yaw,
                pitch: w.pitch,
              }),
              (),
            )
          }

          req.current = Some(
            Window.requestAnimationFrame(() => loop(v, j, pd, st, bst, cft, dispatch, req, ())),
          )
        }
      } catch {
      | exn => {
          let (msg, _) = Logger.getErrorDetails(exn)
          Logger.error(
            ~module_="NavigationRenderer",
            ~message="LOOP_CRASH_RECOVERED",
            ~data={"error": msg},
            (),
          )

          // Always attempt to continue the loop unless journey changed
          req.current = Some(
            Window.requestAnimationFrame(() => loop(v, j, pd, st, bst, cft, dispatch, req, ())),
          )
        }
      }
    } else {
      Logger.debug(
        ~module_="NavigationRenderer",
        ~message="LOOP_TERMINATED",
        ~data=Some({
          "journeyId": j.journeyId,
          "activeJourneyId": activeJourneyId.contents,
          "cft": cft.contents,
        }),
        (),
      )
    }
  }

  let startLoop = (
    v,
    j: journeyData,
    pd: Types.pathData,
    dispatch,
    req: React.ref<option<int>>,
  ) => {
    activeJourneyId := Some(j.journeyId)
    let st = Date.now()
    let bst = ref(None)
    let cft = ref(false)
    Viewer.setPitch(v, pd.startPitch, false)
    Viewer.setYaw(v, pd.startYaw, false)
    Viewer.setHfov(v, pd.startHfov, false)

    req.current = Some(
      Window.requestAnimationFrame(() => loop(v, j, pd, st, bst, cft, dispatch, req, ())),
    )
  }
}
