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
    state,
    j: journeyData,
    pd: Types.pathData,
    st,
    bst,
    cft,
    dispatch,
    req: React.ref<option<int>>,
    (),
  ) => {
    if activeJourneyId.contents == Some(j.journeyId) && !cft.contents {
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

        Viewer.setPitch(v, pd.targetPitchForPan, false)
        Viewer.setYaw(v, pd.targetYawForPan, false)
        Viewer.setHfov(v, pd.targetHfovForPan, false)
        if bel < dur {
          if ViewerSystem.isViewerReady(v) {
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
          req.current = Some(
            Window.requestAnimationFrame(() =>
              loop(v, state, j, pd, st, bst, cft, dispatch, req, ())
            ),
          )
        } else {
          // SYNC GUARD: Only finalize if FSM has moved past Preloading (i.e. texture is loaded)
          let currentFsm = GlobalStateBridge.getState().navigationFsm
          switch currentFsm {
          | NavigationFSM.Transitioning(_) | NavigationFSM.Stabilizing(_) =>
            Logger.debug(
              ~module_="NavigationRenderer",
              ~message="FINALIZE_TRANSITION",
              ~data=Some({
                "journeyId": j.journeyId,
                "fsmState": NavigationFSM.toString(currentFsm),
              }),
              (),
            )
            cft := true
            dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
          | NavigationFSM.Idle =>
            // Already idle, just stop the loop
            cft := true
          | _ =>
            // Texture not loaded yet (Preloading or Error), keep blinking at the waypoint
            Logger.debug(
              ~module_="NavigationRenderer",
              ~message="WAITING_FOR_TEXTURE",
              ~data=Some({"fsmState": NavigationFSM.toString(currentFsm)}),
              (),
            )
            req.current = Some(
              Window.requestAnimationFrame(() =>
                loop(v, state, j, pd, st, bst, cft, dispatch, req, ())
              ),
            )
          }
        }
      } else {
        dispatch(Actions.DispatchNavigationFsmEvent(AnimationProgress(prog)))
        let (cp, cy) = NavigationLogic.calculateCameraPosition(~progress=prog, ~pathData=pd)
        Viewer.setPitch(v, cp, false)
        Viewer.setYaw(v, cy, false)
        Viewer.setHfov(v, pd.startHfov +. (pd.targetHfovForPan -. pd.startHfov) *. prog, false)
        if ViewerSystem.isViewerReady(v) {
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
          Window.requestAnimationFrame(() =>
            loop(v, state, j, pd, st, bst, cft, dispatch, req, ())
          ),
        )
      }
    } else {
      // Stop this loop instance
      ()
    }
  }

  let startLoop = (
    v,
    state,
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
      Window.requestAnimationFrame(() => loop(v, state, j, pd, st, bst, cft, dispatch, req, ())),
    )
  }
}
