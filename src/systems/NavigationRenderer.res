/* src/systems/NavigationRenderer.res */

open ReBindings
open Types

/* --- STATE --- */

let activeJourneyId = ref(None)

/* Constants that match JS */
/* Use Centralized Constants */
let blinkDurationPreview = Float.fromInt(Constants.blinkDurationPreview)
let blinkDurationSimulation = Float.fromInt(Constants.blinkDurationSimulation)
let blinkRatePreview = Float.fromInt(Constants.blinkRatePreview)
let blinkRateSimulation = Float.fromInt(Constants.blinkRateSimulation)

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

    // Pre-calculated optimized segments and waypoints
    let arrowSegments =
      pathData.segments->Belt.Array.map(seg => (
        seg.dist,
        seg.yawDiff,
        seg.pitchDiff,
        ({PathInterpolation.yaw: seg.p1.yaw, pitch: seg.p1.pitch}: PathInterpolation.point),
        ({PathInterpolation.yaw: seg.p2.yaw, pitch: seg.p2.pitch}: PathInterpolation.point),
      ))
    let arrowWaypoints: array<PathInterpolation.point> = pathData.waypoints->Belt.Array.map(w => {
      PathInterpolation.yaw: w.yaw,
      pitch: w.pitch,
    })

    // Performance tracking
    let maxWorkTime = ref(0.0)
    let frameCount = ref(0)
    let totalWorkTime = ref(0.0)

    let rec animLoop = () => {
      let frameStart = Date.now()
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
        | Some(_) => SvgManager.hide("sim_arrow")
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
        | Some(_) => SvgManager.hide("sim_arrow")
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

            if HotspotLine.isViewerReady(v) {
              HotspotLine.updateSimulationArrow(
                v,
                arrowStartPitch,
                arrowStartYaw,
                pathData.targetPitchForPan,
                pathData.targetYawForPan,
                1.0,
                ~opacity,
                ~waypoints=arrowWaypoints,
                ~colorOverride?,
                ~preComputedSegments=arrowSegments,
                ~preComputedTotalDistance=pathData.totalPathDistance,
                (),
              )
            }

            let _ = Window.requestAnimationFrame(animLoop)
            let duration = Date.now() -. frameStart
            totalWorkTime := totalWorkTime.contents +. duration
            frameCount := frameCount.contents + 1
            if duration > maxWorkTime.contents {
              maxWorkTime := duration
            }
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
            let avgTime =
              frameCount.contents > 0
                ? totalWorkTime.contents /. Belt.Int.toFloat(frameCount.contents)
                : 0.0
            Logger.info(
              ~module_="NavRenderer",
              ~message="JOURNEY_COMPLETE",
              ~data=Some({
                "journeyId": data.journeyId,
                "durationMs": Date.now() -. startTime,
                "perf": {
                  "maxFrameWorkMs": maxWorkTime.contents,
                  "avgFrameWorkMs": avgTime,
                  "frameCount": frameCount.contents,
                },
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

          // Only draw if viewer is valid
          if HotspotLine.isViewerReady(v) {
            // PERFORMANCE: Direct DOM access to bypass Facade overhead
            // We implement "Cinema Mode" here: We strictly draw ONLY the arrow.
            // We intentionally skip HotspotLine.updateLines() which draws static markers,
            // as redrawing them 60fps causes massive layout thrashing.
            let svgOpt = Dom.getElementById("viewer-hotspot-lines")
            switch Nullable.toOption(svgOpt) {
            | Some(svg) =>
              // 1. Get Layout (Fast, no DOM clearing)
              let rect = Dom.getBoundingClientRect(svg)

              if rect.width > 0.0 {
                // 2. Get Camera State
                let cam = HotspotLineLogic.getCamState(v, rect)

                // 3. Update Arrow directly
                HotspotLineLogic.updateSimulationArrow(
                  cam,
                  arrowStartPitch,
                  arrowStartYaw,
                  pathData.targetPitchForPan,
                  pathData.targetYawForPan,
                  progress,
                  rect,
                  ~opacity=1.0,
                  ~waypoints=arrowWaypoints,
                  ~preComputedSegments=arrowSegments,
                  ~preComputedTotalDistance=pathData.totalPathDistance,
                  (),
                )
              }
            | None => ()
            }
          }
          let _ = Window.requestAnimationFrame(animLoop)
          let duration = Date.now() -. frameStart
          totalWorkTime := totalWorkTime.contents +. duration
          frameCount := frameCount.contents + 1
          if duration > maxWorkTime.contents {
            maxWorkTime := duration
          }
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
      | Some(_) => SvgManager.hide("sim_arrow")
      | None => ()
      }
    | _ => ()
    }
  })
}
