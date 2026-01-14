/* src/systems/NavigationRenderer.res */

open ReBindings

/* --- TYPES --- */

type segment = {
  "dist": float,
  "yawDiff": float,
  "pitchDiff": float,
  "p1": PathInterpolation.point,
  "p2": PathInterpolation.point,
}

type pathData = {
  "startPitch": float,
  "startYaw": float,
  "startHfov": float,
  "targetPitchForPan": float,
  "targetYawForPan": float,
  "targetHfovForPan": float,
  "segments": array<segment>,
  "totalPathDistance": float,
  "panDuration": float,
  "waypoints": array<PathInterpolation.point>,
  "arrivalYaw": float,
  "arrivalPitch": float,
  "arrivalHfov": float,
}

type navStartPayload = {
  "journeyId": int,
  "targetIndex": int,
  "sourceIndex": int,
  "hotspotIndex": int,
  "previewOnly": bool,
  "pathData": pathData,
}

type navCompletedPayload = {
  "journeyId": int,
  "targetIndex": int,
  "sourceIndex": int,
  "hotspotIndex": int,
  "arrivalYaw": float,
  "arrivalPitch": float,
  "arrivalHfov": float,
  "previewOnly": bool,
}

/* --- STATE --- */

let activeJourneyId = ref(None)

/* Constants that match JS */
let blinkDurationPreview = 1000.0
let blinkDurationSimulation = 2000.0
let blinkRatePreview = 200.0
let blinkRateSimulation = 400.0

/* --- LOGIC --- */

let startJourney = (data: navStartPayload) => {
  let viewer = switch Viewer.instance {
  | Nullable.Value(v) => Some(v)
  | _ => None
  }

  // Check viewer availability
  switch viewer {
  | None =>
    Logger.error(~module_="NavRenderer", ~message="VIEWER_NOT_READY", ())
    PubSub.publish(PubSub.navCancelled, {"journeyId": data["journeyId"]})
  | Some(v) =>
    activeJourneyId := Some(data["journeyId"])
    let startTime = Date.now()
    let blinkStartTime = ref(None)
    let crossfadeTriggered = ref(false)
    let pathData = data["pathData"]

    Logger.info(
      ~module_="NavRenderer",
      ~message="JOURNEY_START",
      ~data=Some({
        "targetYaw": pathData["arrivalYaw"],
        "targetPitch": pathData["arrivalPitch"],
        "duration": pathData["panDuration"],
      }),
      (),
    )

    // Set starting position
    Viewer.setPitch(v, pathData["startPitch"], false)
    Viewer.setYaw(v, pathData["startYaw"], false)
    Viewer.setHfov(v, pathData["startHfov"], false)

    let arrowStartPitch = pathData["startPitch"]
    let arrowStartYaw = pathData["startYaw"]

    let rec animLoop = () => {
      // Check cancellation
      let currentActive = activeJourneyId.contents
      let shouldContinue = switch currentActive {
      | Some(id) => id == data["journeyId"]
      | None => false
      }

      if !shouldContinue {
        Logger.warn(~module_="NavRenderer", ~message="JOURNEY_CANCELLED", ~data=Some({"journeyId": data["journeyId"]}), ())
      } else if crossfadeTriggered.contents {
        // Clear UI and stop
        let svgOpt = Dom.getElementById("viewer-hotspot-lines")
        switch Nullable.toOption(svgOpt) {
        | Some(svg) => Dom.setInnerHTML(svg, "")
        | None => ()
        }
      } else {
        let elapsed = Date.now() -. startTime
        let progress = Math.min(elapsed /. pathData["panDuration"], 1.0)

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
          let isPreview = data["previewOnly"]
          let duration = isPreview ? blinkDurationPreview : blinkDurationSimulation
          let rate = isPreview ? blinkRatePreview : blinkRateSimulation

          Viewer.setPitch(v, pathData["targetPitchForPan"], false)
          Viewer.setYaw(v, pathData["targetYawForPan"], false)
          Viewer.setHfov(v, pathData["targetHfovForPan"], false)

          if blinkElapsed < duration {
            let blinkState = mod(Belt.Float.toInt(blinkElapsed /. rate), 2)
            let opacity = blinkState == 0 ? 1.0 : 0.0
            let colorOverride = isPreview ? Some("red") : None

            let state = GlobalStateBridge.getState()
            HotspotLine.updateLines(v, state, ())

            HotspotLine.drawSimulationArrow(
              v,
              arrowStartPitch,
              arrowStartYaw,
              pathData["targetPitchForPan"],
              pathData["targetYawForPan"],
              1.0,
              ~opacity,
              ~waypoints=pathData["waypoints"],
              ~colorOverride?,
              (),
            )

            let _ = Window.requestAnimationFrame(animLoop)
          } else {
            // COMPLETE
            crossfadeTriggered := true
            let payload: navCompletedPayload = {
              "journeyId": data["journeyId"],
              "targetIndex": data["targetIndex"],
              "sourceIndex": data["sourceIndex"],
              "hotspotIndex": data["hotspotIndex"],
              "arrivalYaw": pathData["arrivalYaw"],
              "arrivalPitch": pathData["arrivalPitch"],
              "arrivalHfov": pathData["arrivalHfov"],
              "previewOnly": data["previewOnly"],
            }
            PubSub.publish(PubSub.navCompleted, payload)
            Logger.info(
              ~module_="NavRenderer",
              ~message="JOURNEY_COMPLETE",
              ~data=Some({
                "journeyId": data["journeyId"],
                "durationMs": Date.now() -. startTime,
              }),
              (),
            )
          }
        } else {
          // Interpolate phase
          let targetDist = progress *. pathData["totalPathDistance"]
          let camPitch = ref(pathData["startPitch"])
          let camYaw = ref(pathData["startYaw"])

          let segments = pathData["segments"]
          if pathData["totalPathDistance"] > 0.0 && Array.length(segments) > 0 {
            let covered = ref(0.0)
            let found = ref(false)

            for i in 0 to Array.length(segments) - 1 {
              if !found.contents {
                let seg = Belt.Array.getExn(segments, i)
                if targetDist <= covered.contents +. seg["dist"] {
                  let segProgress = if seg["dist"] > 0.0 {
                    (targetDist -. covered.contents) /. seg["dist"]
                  } else {
                    0.0
                  }
                  camPitch := seg["p1"].pitch +. seg["pitchDiff"] *. segProgress
                  camYaw := seg["p1"].yaw +. seg["yawDiff"] *. segProgress
                  found := true
                }
                covered := covered.contents +. seg["dist"]

                if !found.contents {
                  camPitch := seg["p2"].pitch
                  camYaw := seg["p2"].yaw
                }
              }
            }
          }

          Viewer.setPitch(v, camPitch.contents, false)
          Viewer.setYaw(v, camYaw.contents, false)
          let hfovProgress =
            pathData["startHfov"] +.
            (pathData["targetHfovForPan"] -. pathData["startHfov"]) *. progress
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

          let state = GlobalStateBridge.getState()
          HotspotLine.updateLines(v, state, ())

          HotspotLine.drawSimulationArrow(
            v,
            arrowStartPitch,
            arrowStartYaw,
            pathData["targetPitchForPan"],
            pathData["targetYawForPan"],
            progress,
            ~opacity=1.0,
            ~waypoints=pathData["waypoints"],
            (),
          )

          let _ = Window.requestAnimationFrame(animLoop)
        }
      }
    }

    let _ = Window.requestAnimationFrame(animLoop)
  }
}

let init = () => {
  let _ = PubSub.subscribe(PubSub.navStart, (data: navStartPayload) => {
    startJourney(data)
  })

  let _ = PubSub.subscribe(PubSub.navCancelled, (data: {..}) => {
    // data might be null or have journeyId
    // In ReScript, untyped object data handling
    let jIdOpt = try {
      Some(data["journeyId"])
    } catch {
    | _ => None
    }

    switch (activeJourneyId.contents, jIdOpt) {
    | (Some(active), Some(cancelled)) =>
      if active == cancelled {
        activeJourneyId := None
      }
    | _ =>
      // Global cancellation if no specific ID or data is empty/null which might be passed as generic object
      activeJourneyId := None
    }
  })

  let _ = PubSub.subscribe(PubSub.clearSimUi, _ => {
    let svgOpt = Dom.getElementById("viewer-hotspot-lines")
    switch Nullable.toOption(svgOpt) {
    | Some(svg) => Dom.setInnerHTML(svg, "")
    | None => ()
    }
  })
}
