/* src/systems/NavigationRenderer.res */

open ReBindings
open Types

/* --- STATE --- */

let activeJourneyId = ref(None)

/* Constants that match JS */
let blinkDurationPreview = 1000.0
let blinkDurationSimulation = 2000.0
let blinkRatePreview = 200.0
let blinkRateSimulation = 400.0

/* --- LOGIC --- */

let startJourney = (data: EventBus.navStartPayload) => {
  let viewer = switch Viewer.instance {
  | Nullable.Value(v) => Some(v)
  | _ => None
  }

  // Check viewer availability
  switch viewer {
  | None =>
    Logger.error(~module_="NavRenderer", ~message="VIEWER_NOT_READY", ())
    EventBus.dispatch(NavCancelled)
  | Some(v) =>
    activeJourneyId := Some(data.journeyId)
    let startTime = Date.now()
    let blinkStartTime = ref(None)
    let crossfadeTriggered = ref(false)
    let pathData = data.pathData

    Logger.info(
      ~module_="NavRenderer",
      ~message="JOURNEY_START",
      ~data=Some({
        "targetYaw": pathData.arrivalYaw,
        "targetPitch": pathData.arrivalPitch,
        "duration": pathData.panDuration,
      }),
      (),
    )

    // Set starting position
    Viewer.setPitch(v, pathData.startPitch, false)
    Viewer.setYaw(v, pathData.startYaw, false)
    Viewer.setHfov(v, pathData.startHfov, false)

    let arrowStartPitch = pathData.startPitch
    let arrowStartYaw = pathData.startYaw

    let rec animLoop = () => {
      // Check cancellation
      let currentActive = activeJourneyId.contents
      let shouldContinue = switch currentActive {
      | Some(id) => id == data.journeyId
      | None => false
      }

      if !shouldContinue {
        // Clear UI on cancellation to prevent stuck waypoints
        let svgOpt = Dom.getElementById("viewer-hotspot-lines")
        switch Nullable.toOption(svgOpt) {
        | Some(svg) => Dom.setInnerHTML(svg, "")
        | None => ()
        }
        Logger.warn(
          ~module_="NavRenderer",
          ~message="JOURNEY_CANCELLED",
          ~data=Some({"journeyId": data.journeyId}),
          (),
        )
      } else if crossfadeTriggered.contents {
        // Clear UI and stop
        let svgOpt = Dom.getElementById("viewer-hotspot-lines")
        switch Nullable.toOption(svgOpt) {
        | Some(svg) => Dom.setInnerHTML(svg, "")
        | None => ()
        }
      } else {
        let elapsed = Date.now() -. startTime
        let progress = Math.min(elapsed /. pathData.panDuration, 1.0)

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
          let isPreview = data.previewOnly
          let duration = isPreview ? blinkDurationPreview : blinkDurationSimulation
          let rate = isPreview ? blinkRatePreview : blinkRateSimulation

          Viewer.setPitch(v, pathData.targetPitchForPan, false)
          Viewer.setYaw(v, pathData.targetYawForPan, false)
          Viewer.setHfov(v, pathData.targetHfovForPan, false)

          if blinkElapsed < duration {
            let blinkState = mod(Belt.Float.toInt(blinkElapsed /. rate), 2)
            let opacity = blinkState == 0 ? 1.0 : 0.0
            let colorOverride = isPreview ? Some("red") : None

            // Only draw if viewer is valid AND active (prevents stale camera data)
            if HotspotLine.isViewerReady(v) {
              let state = GlobalStateBridge.getState()
              HotspotLine.updateLines(v, state, ())

              HotspotLine.drawSimulationArrow(
                v,
                arrowStartPitch,
                arrowStartYaw,
                pathData.targetPitchForPan,
                pathData.targetYawForPan,
                1.0,
                ~opacity,
                ~waypoints=Obj.magic(pathData.waypoints),
                ~colorOverride?,
                (),
              )
            } else {
              Logger.debug(
                ~module_="NavRenderer",
                ~message="BLINK_SKIP_NOT_READY",
                ~data=Some({"journeyId": data.journeyId}),
                (),
              )
            }

            let _ = Window.requestAnimationFrame(animLoop)
          } else {
            // COMPLETE
            crossfadeTriggered := true
            let payload: journeyData = {
              journeyId: data.journeyId,
              targetIndex: data.targetIndex,
              sourceIndex: data.sourceIndex,
              hotspotIndex: data.hotspotIndex,
              arrivalYaw: pathData.arrivalYaw,
              arrivalPitch: pathData.arrivalPitch,
              arrivalHfov: pathData.arrivalHfov,
              previewOnly: data.previewOnly,
              pathData: None,
            }
            EventBus.dispatch(NavCompleted(payload))
            Logger.info(
              ~module_="NavRenderer",
              ~message="JOURNEY_COMPLETE",
              ~data=Some({
                "journeyId": data.journeyId,
                "durationMs": Date.now() -. startTime,
              }),
              (),
            )
          }
        } else {
          // Interpolate phase
          let targetDist = progress *. pathData.totalPathDistance
          let camPitch = ref(pathData.startPitch)
          let camYaw = ref(pathData.startYaw)

          let segments = pathData.segments
          if pathData.totalPathDistance > 0.0 && Array.length(segments) > 0 {
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
          let hfovProgress =
            pathData.startHfov +. (pathData.targetHfovForPan -. pathData.startHfov) *. progress
          Viewer.setHfov(v, hfovProgress, false)

          Logger.trace(
            ~module_="NavRenderer",
            ~message="FRAME",
            ~data=Some({
              "progress": progress,
              "currentYaw": camYaw.contents,
              "currentPitch": camPitch.contents,
            }),
            (),
          )

          // Only draw if viewer is valid AND active (prevents stale camera data)
          if HotspotLine.isViewerReady(v) {
            let state = GlobalStateBridge.getState()
            HotspotLine.updateLines(v, state, ())

            HotspotLine.drawSimulationArrow(
              v,
              arrowStartPitch,
              arrowStartYaw,
              pathData.targetPitchForPan,
              pathData.targetYawForPan,
              progress,
              ~opacity=1.0,
              ~waypoints=Obj.magic(pathData.waypoints),
              (),
            )
          } else {
            Logger.debug(
              ~module_="NavRenderer",
              ~message="DRAW_SKIP_NOT_READY",
              ~data=Some({"journeyId": data.journeyId, "progress": progress}),
              (),
            )
          }

          let _ = Window.requestAnimationFrame(animLoop)
        }
      }
    }

    let _ = Window.requestAnimationFrame(animLoop)
  }
}

let init = () => {
  let _ = EventBus.subscribe(event => {
    switch event {
    | NavStart(data) => startJourney(data)
    | NavCancelled => activeJourneyId := None
    | ClearSimUi =>
      let svgOpt = Dom.getElementById("viewer-hotspot-lines")
      switch Nullable.toOption(svgOpt) {
      | Some(svg) => Dom.setInnerHTML(svg, "")
      | None => ()
      }
    | _ => ()
    }
  })
}
