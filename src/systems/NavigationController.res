/* src/systems/NavigationController.res */

open Types
open ReBindings

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let activeJourneyId = React.useRef(None)
  let requestRef = React.useRef(None)

  // v4.7.12 - Finite State Machine Orchestration
  React.useEffect1(() => {
    Logger.debug(
      ~module_="NavController",
      ~message="FSM_PROCESS",
      ~data=Some({"state": NavigationFSM.toString(state.navigationFsm)}),
      (),
    )
    switch state.navigationFsm {
    | Preloading({targetSceneId, isAnticipatory}) =>
      let targetIndex = Belt.Array.getIndexBy(state.scenes, s => s.id == targetSceneId)
      switch targetIndex {
      | Some(idx) =>
        let prevId = switch Belt.Array.get(state.scenes, state.activeIndex) {
        | Some(s) => Some(s.id)
        | None => None
        }
        // Reaction to Preloading: Trigger the imperative loader if it hasn't started
        Scene.Loader.loadNewScene(prevId, Some(idx), ~isAnticipatory)
      | None => ()
      }
    | Transitioning({toSceneId: _toSceneId, progress}) =>
      // If no animation is active (status == Idle), skip straight to Stabilizing
      if state.navigation == Idle && progress == 0.0 {
        dispatch(DispatchNavigationFsmEvent(TransitionComplete))
      }
    | Stabilizing({targetSceneId}) =>
      // FSM standard: Stabilizing ensures texture execution.
      // We wait for 1 animation frame for "Deep Render" stabilization (v4.7.12)
      let _ = Window.requestAnimationFrame(() => {
        let targetScene = Belt.Array.getBy(state.scenes, s => s.id == targetSceneId)
        switch targetScene {
        | Some(ts) =>
          // Perform the actual viewer swap
          Scene.Transition.performSwap(ts, 0.0)
        | None => dispatch(DispatchNavigationFsmEvent(Reset))
        }
      })
    | Idle =>
      // Finalize navigation state when FSM reaches Idle
      switch state.navigation {
      | Navigating(journey) => dispatch(NavigationCompleted(journey))
      | _ => ()
      }
    | _ => ()
    }
    None
  }, [state.navigationFsm])

  React.useEffect1(() => {
    switch state.navigation {
    | Navigating(journey) =>
      if activeJourneyId.current != Some(journey.journeyId) {
        activeJourneyId.current = Some(journey.journeyId)

        let viewer = ViewerSystem.getActiveViewer()->Nullable.toOption

        switch (viewer, journey.pathData) {
        | (Some(v), Some(pd)) =>
          let startTime = Date.now()
          let blinkStartTime = ref(None)
          let crossfadeTriggered = ref(false)

          // Set starting position
          Viewer.setPitch(v, pd.startPitch, false)
          Viewer.setYaw(v, pd.startYaw, false)
          Viewer.setHfov(v, pd.startHfov, false)

          let rec animLoop = () => {
            if crossfadeTriggered.contents {
              // Clear UI and stop
              let svgOpt = Dom.getElementById("viewer-hotspot-lines")
              switch Nullable.toOption(svgOpt) {
              | Some(svg) => Dom.setInnerHTML(svg, "")
              | None => ()
              }
            } else {
              let elapsed = Date.now() -. startTime
              let progress = Math.min(elapsed /. pd.panDuration, 1.0)

              if progress >= 1.0 {
                // Blink / Finish phase
                let startBlink = switch blinkStartTime.contents {
                | Some(t) => t
                | None =>
                  let now = Date.now()
                  blinkStartTime := Some(now)
                  now
                }

                let blinkElapsed = Date.now() -. startBlink
                let isPreview = journey.previewOnly
                let duration = isPreview ? 1000.0 : 2000.0
                let rate = isPreview ? 200.0 : 400.0

                Viewer.setPitch(v, pd.targetPitchForPan, false)
                Viewer.setYaw(v, pd.targetYawForPan, false)
                Viewer.setHfov(v, pd.targetHfovForPan, false)

                if blinkElapsed < duration {
                  let blinkState = mod(Belt.Float.toInt(blinkElapsed /. rate), 2)
                  let opacity = blinkState == 0 ? 1.0 : 0.0
                  let colorOverride = isPreview ? Some("red") : None

                  // Only draw if viewer is valid AND active (prevents stale camera data)
                  if ViewerSystem.isViewerReady(v) {
                    HotspotLine.updateLines(v, state, ())

                    HotspotLine.updateSimulationArrow(
                      v,
                      pd.startPitch,
                      pd.startYaw,
                      pd.targetPitchForPan,
                      pd.targetYawForPan,
                      1.0,
                      ~opacity,
                      ~waypoints=(pd.waypoints :> array<PathInterpolation.point>),
                      ~colorOverride?,
                      (),
                    )
                  }

                  requestRef.current = Some(Window.requestAnimationFrame(animLoop))
                } else {
                  // COMPLETE
                  crossfadeTriggered := true
                  dispatch(DispatchNavigationFsmEvent(TransitionComplete))
                }
              } else {
                // Interpolate phase
                let targetDist = progress *. pd.totalPathDistance

                // Drive the FSM progress
                dispatch(DispatchNavigationFsmEvent(AnimationProgress(progress)))

                let camPitch = ref(pd.startPitch)
                let camYaw = ref(pd.startYaw)

                let segments = pd.segments
                if pd.totalPathDistance > 0.0 && Array.length(segments) > 0 {
                  let covered = ref(0.0)
                  let found = ref(false)

                  for i in 0 to Array.length(segments) - 1 {
                    if !found.contents {
                      switch Belt.Array.get(segments, i) {
                      | Some(seg) =>
                        if targetDist <= covered.contents +. seg.dist {
                          let segProgress = if seg.dist > 0.0 {
                            (targetDist -. covered.contents) /. seg.dist
                          } else {
                            0.0
                          }
                          camPitch := seg.p1.pitch +. seg.pitchDiff *. segProgress
                          camYaw := seg.p1.yaw +. seg.yawDiff *. segProgress
                          found := true
                        }
                        covered := covered.contents +. seg.dist

                        if !found.contents {
                          camPitch := seg.p2.pitch
                          camYaw := seg.p2.yaw
                        }
                      | None => ()
                      }
                    }
                  }
                }

                Viewer.setPitch(v, camPitch.contents, false)
                Viewer.setYaw(v, camYaw.contents, false)
                let hfovProgress = pd.startHfov +. (pd.targetHfovForPan -. pd.startHfov) *. progress
                Viewer.setHfov(v, hfovProgress, false)

                // Only draw if viewer is valid AND active (prevents stale camera data)
                if ViewerSystem.isViewerReady(v) {
                  HotspotLine.updateLines(v, state, ())

                  HotspotLine.updateSimulationArrow(
                    v,
                    pd.startPitch,
                    pd.startYaw,
                    pd.targetPitchForPan,
                    pd.targetYawForPan,
                    progress,
                    ~opacity=1.0,
                    ~waypoints=(pd.waypoints :> array<PathInterpolation.point>),
                    (),
                  )
                }

                requestRef.current = Some(Window.requestAnimationFrame(animLoop))
              }
            }
          }

          requestRef.current = Some(Window.requestAnimationFrame(animLoop))
        | _ =>
          // Fallback or immediate finish if viewer/pathData missing
          dispatch(Actions.SetNavigationStatus(Idle))
        }
      }
    | Idle =>
      // Cancel animation if idle
      activeJourneyId.current = None
      switch requestRef.current {
      | Some(id) => Window.cancelAnimationFrame(id)
      | None => ()
      }
      requestRef.current = None
    | Previewing(_) => () // Animation handled elsewhere or needs update
    }

    Some(
      () => {
        switch requestRef.current {
        | Some(id) => Window.cancelAnimationFrame(id)
        | None => ()
        }
      },
    )
  }, [state.navigation])

  React.null
}
