/* src/systems/NavigationController.res */

open Types
open ReBindings

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  let activeJourneyId = React.useRef(None)
  let requestRef = React.useRef(None)

  React.useEffect1(() => {
    switch state.navigation {
    | Navigating(journey) =>
      if activeJourneyId.current != Some(journey.journeyId) {
        activeJourneyId.current = Some(journey.journeyId)

        let viewer = switch Viewer.instance {
        | Nullable.Value(v) => Some(v)
        | _ => None
        }

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

                  // Use hot reload friendly update
                  HotspotLine.updateLines(v, state, ())

                  HotspotLine.drawSimulationArrow(
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

                  requestRef.current = Some(Window.requestAnimationFrame(animLoop))
                } else {
                  // COMPLETE
                  crossfadeTriggered := true
                  dispatch(Actions.NavigationCompleted(journey))
                }
              } else {
                // Interpolate phase
                let targetDist = progress *. pd.totalPathDistance
                let camPitch = ref(pd.startPitch)
                let camYaw = ref(pd.startYaw)

                let segments = pd.segments
                if pd.totalPathDistance > 0.0 && Array.length(segments) > 0 {
                  let covered = ref(0.0)
                  let found = ref(false)

                  for i in 0 to Array.length(segments) - 1 {
                    if !found.contents {
                      let seg = Belt.Array.getExn(segments, i)
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
                    }
                  }
                }

                Viewer.setPitch(v, camPitch.contents, false)
                Viewer.setYaw(v, camYaw.contents, false)
                let hfovProgress = pd.startHfov +. (pd.targetHfovForPan -. pd.startHfov) *. progress
                Viewer.setHfov(v, hfovProgress, false)

                HotspotLine.updateLines(v, state, ())

                HotspotLine.drawSimulationArrow(
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
