/* src/systems/Navigation.res */

open Types

/* --- HELPERS --- */

/* Calculate the intended arrival orientation for a scene */
let calculateSmartArrivalTarget = (scenes: array<scene>, targetIndex: int) => {
  let arrivalYaw = ref(0.0)
  let arrivalPitch = ref(0.0)
  let arrivalHfov = ref(90.0)

  if targetIndex >= 0 && targetIndex < Belt.Array.length(scenes) {
    let nextSceneOpt = Belt.Array.get(scenes, targetIndex)

    switch nextSceneOpt {
    | Some(nextScene) =>
      /* PRIORITY: Use creation sequence (Oldest first) logic from JS is:
           let nextHotspot = null
           if (!nextHotspot && nextScene.hotspots.length > 0) ...
           Use find explicitly.
 */
      let nextHotspot = Array.find(nextScene.hotspots, h => {
        /* !h.isReturnLink */
        switch h.isReturnLink {
        | Some(true) => false
        | _ => true
        }
      })

      let target = switch nextHotspot {
      | Some(h) => Some(h)
      | None =>
        if Belt.Array.length(nextScene.hotspots) > 0 {
          Belt.Array.get(nextScene.hotspots, 0)
        } else {
          None
        }
      }

      switch target {
      | Some(h) =>
        /* Check startYaw/Pitch definition */
        switch (h.startYaw, h.startPitch) {
        | (Some(sy), Some(sp)) =>
          arrivalYaw := sy
          arrivalPitch := sp
          switch h.startHfov {
          | Some(sh) => arrivalHfov := sh
          | _ => ()
          }
        | _ =>
          arrivalYaw := h.yaw -. 35.0
          arrivalPitch := 0.0
        }
      | None => ()
      }
    | None => ()
    }
  }

  (arrivalYaw.contents, arrivalPitch.contents, arrivalHfov.contents)
}

/* Helper to get current view safely */
let getCurrentView = () => {
  switch Nullable.toOption(ReBindings.Viewer.instance) {
  | Some(v) => (
      ReBindings.Viewer.getYaw(v),
      ReBindings.Viewer.getPitch(v),
      ReBindings.Viewer.getHfov(v),
    )
  | None => (0.0, 0.0, 90.0)
  }
}

/**
 * Finds a scene by its name in the given array of scenes.
 */
let findSceneByName = (scenes: array<Types.scene>, name: string) => {
  Belt.Array.getBy(scenes, s => s.name == name)
}

/**
 * Returns the index of the next scene in the array, wrapping around to the start.
 */
let getNextScene = (scenes: array<Types.scene>, currentIndex: int) => {
  let len = Array.length(scenes)
  if len == 0 {
    None
  } else {
    Some(mod(currentIndex + 1, len))
  }
}

/**
 * Returns the index of the previous scene in the array, wrapping around to the end.
 */
let getPreviousScene = (scenes: array<Types.scene>, currentIndex: int) => {
  let len = Array.length(scenes)
  if len == 0 {
    None
  } else {
    Some(mod(currentIndex - 1 + len, len))
  }
}

/* --- PURE PATH CALCULATION --- */

let calculatePathData = (
  state: state,
  sourceSceneIndex: int,
  sourceHotspotIndex: int,
  targetIndex: int,
  targetYaw: float,
  targetPitch: float,
  targetHfov: float,
  currentView: (float, float, float),
) => {
  let sourceSceneOpt = Belt.Array.get(state.scenes, sourceSceneIndex)
  switch sourceSceneOpt {
  | Some(sourceScene) =>
    let hotspotOpt = Belt.Array.get(sourceScene.hotspots, sourceHotspotIndex)
    switch hotspotOpt {
    | Some(hotspot) =>
      let (curYaw, curPitch, curHfov) = currentView

      let (arrYaw, arrPitch, arrHfov) = if state.simulation.status == Running {
        calculateSmartArrivalTarget(state.scenes, targetIndex)
      } else {
        (targetYaw, targetPitch, targetHfov)
      }

      /* Determine start params */
      let startPitch = switch hotspot.startPitch {
      | Some(p) => p
      | _ => curPitch
      }
      let startYaw = switch hotspot.startYaw {
      | Some(y) => y
      | _ => curYaw
      }

      /* Determine target pan params */
      let (tYawPan, tPitchPan) = switch hotspot.viewFrame {
      | Some(vf) => (vf.yaw, vf.pitch)
      | _ => (targetYaw, targetPitch)
      }

      /* Generate Control Points */
      let p0: PathInterpolation.point = {yaw: startYaw, pitch: startPitch}
      let pEnd: PathInterpolation.point = {yaw: tYawPan, pitch: tPitchPan}

      let waypointsRaw = switch hotspot.waypoints {
      | Some(w) => w
      | None => []
      }
      let waypoints: array<PathInterpolation.point> = Belt.Array.map(waypointsRaw, w => {
        PathInterpolation.yaw: w.yaw,
        pitch: w.pitch,
      })

      let controlPoints = if Array.length(waypoints) > 0 {
        Belt.Array.concat([p0], Belt.Array.concat(waypoints, [pEnd]))
      } else {
        [p0, pEnd]
      }

      /* Path generation - match HotspotLine.res logic */
      let path = if Array.length(waypoints) > 0 {
        PathInterpolation.getCatmullRomSpline(controlPoints, 100)
      } else {
        PathInterpolation.getFloorProjectedPath(p0, pEnd, 100)
      }

      /* Calculate segments and total distance */
      let totalDistance = ref(0.0)
      let segments = []

      if Array.length(path) >= 2 {
        for i in 0 to Array.length(path) - 2 {
          switch (Belt.Array.get(path, i), Belt.Array.get(path, i + 1)) {
          | (Some(p1_orig), Some(p2_orig)) =>
            let p1: pathPoint = {yaw: p1_orig.yaw, pitch: p1_orig.pitch}
            let p2: pathPoint = {yaw: p2_orig.yaw, pitch: p2_orig.pitch}

            let yawDiff = ref(p2.yaw -. p1.yaw)
            while yawDiff.contents > 180.0 {
              yawDiff := yawDiff.contents -. 360.0
            }
            while yawDiff.contents < -180.0 {
              yawDiff := yawDiff.contents +. 360.0
            }

            let pitchDiff = p2.pitch -. p1.pitch
            let dist = Math.sqrt(yawDiff.contents *. yawDiff.contents +. pitchDiff *. pitchDiff)

            let segment: pathSegment = {
              dist,
              yawDiff: yawDiff.contents,
              pitchDiff,
              p1,
              p2,
            }
            let _ = Array.push(segments, segment)
            totalDistance := totalDistance.contents +. dist
          | _ => ()
          }
        }
      }

      let panDuration = Math.min(
        Math.max(
          totalDistance.contents /. Constants.panningVelocity *. 1000.0,
          Constants.panningMinDuration,
        ),
        Constants.panningMaxDuration,
      )

      Some({
        startPitch,
        startYaw,
        startHfov: curHfov,
        targetPitchForPan: tPitchPan,
        targetYawForPan: tYawPan,
        targetHfovForPan: arrHfov,
        totalPathDistance: totalDistance.contents,
        segments,
        waypoints: Belt.Array.map(waypoints, p => {yaw: p.yaw, pitch: p.pitch}),
        panDuration,
        arrivalYaw: arrYaw,
        arrivalPitch: arrPitch,
        arrivalHfov: arrHfov,
      })
    | None => None
    }
  | None => None
  }
}

/* --- ORCHESTRATION --- */

let navStartTime = ref(0.0)

let navigateToScene = (
  dispatch: Actions.action => unit,
  state: state,
  targetIndex: int,
  sourceSceneIndex: int,
  sourceHotspotIndex: int,
  ~targetYaw: float=0.0,
  ~targetPitch: float=0.0,
  ~targetHfov: float=90.0,
  ~previewOnly: bool=false,
  (),
) => {
  navStartTime := Date.now()
  Logger.startOperation(
    ~module_="Navigation",
    ~operation="NAV",
    ~data={
      "targetIndex": targetIndex,
      "previewOnly": previewOnly,
    },
    (),
  )
  if (
    switch state.navigation {
    | Navigating(_) => true
    | _ => false
    }
  ) {
    Logger.warn(
      ~module_="Navigation",
      ~message="NAV_BLOCKED",
      ~data={"reason": "Navigation already in progress"},
      (),
    )
  } else {
    let newJourneyId = state.currentJourneyId + 1
    dispatch(IncrementJourneyId)

    let currentView = getCurrentView()

    if previewOnly {
      dispatch(
        SetNavigationStatus(
          Previewing({sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex}),
        ),
      )
    }

    let shouldAnimate = state.simulation.status == Running || previewOnly

    if shouldAnimate {
      let pathData = calculatePathData(
        state,
        sourceSceneIndex,
        sourceHotspotIndex,
        targetIndex,
        targetYaw,
        targetPitch,
        targetHfov,
        currentView,
      )

      let journey: journeyData = {
        journeyId: newJourneyId,
        targetIndex,
        sourceIndex: sourceSceneIndex,
        hotspotIndex: sourceHotspotIndex,
        arrivalYaw: targetYaw, // Default if pathData None
        arrivalPitch: targetPitch,
        arrivalHfov: targetHfov,
        previewOnly,
        pathData,
      }

      // If pathData is some, adjust arrival from pathData
      let finalJourney = switch pathData {
      | Some(pd) => {
          ...journey,
          arrivalYaw: pd.arrivalYaw,
          arrivalPitch: pd.arrivalPitch,
          arrivalHfov: pd.arrivalHfov,
        }
      | None => journey
      }

      dispatch(SetNavigationStatus(Navigating(finalJourney)))

      // Dispatch via typed EventBus
      switch pathData {
      | Some(pd) =>
        let payload: EventBus.navStartPayload = {
          journeyId: newJourneyId,
          targetIndex,
          sourceIndex: sourceSceneIndex,
          hotspotIndex: sourceHotspotIndex,
          previewOnly,
          pathData: pd,
        }
        EventBus.dispatch(NavStart(payload))
      | None => ()
      }
    } else {
      /* Manual Jump */
      let (arrYaw, arrPitch, _arrHfov) = calculateSmartArrivalTarget(state.scenes, targetIndex)

      dispatch(
        SetIncomingLink(Some({sceneIndex: sourceSceneIndex, hotspotIndex: sourceHotspotIndex})),
      )

      let transition: transition = {
        type_: Some("link"),
        targetHotspotIndex: -1,
        fromSceneName: None,
      }

      dispatch(SetActiveScene(targetIndex, arrYaw, arrPitch, Some(transition)))

      Logger.endOperation(
        ~module_="Navigation",
        ~operation="NAV",
        ~data={
          "targetIndex": targetIndex,
          "type": "manual_jump",
          "durationMs": Date.now() -. navStartTime.contents,
        },
        (),
      )
      // In simulation mode, we might need to trigger arrival callback
      // For now, dispathing SetActiveScene should handle it in components
    }
  }
}

let handleAutoForward = (dispatch: Actions.action => unit, state: state, currentScene: scene) => {
  /* Recursion / Logic port from JS */
  if state.simulation.status == Running {
    /* Skipped in Sim Mode */
    ()
  } else if currentScene.isAutoForward {
    if !state.isLinking {
      Logger.debug(
        ~module_="Navigation",
        ~message="AUTO_FORWARD_CHECK",
        ~data={"sceneName": currentScene.name},
        (),
      )

      /* Chain Logic */
      let chain = state.autoForwardChain
      if Array.length(chain) == 0 {
        switch state.incomingLink {
        | Some(l) => dispatch(AddToAutoForwardChain(l.sceneIndex))
        | None => ()
        }
      }

      if Array.includes(chain, state.activeIndex) {
        Logger.warn(
          ~module_="Navigation",
          ~message="LOOP_DETECTED",
          ~data={"sceneName": currentScene.name},
          (),
        )
        dispatch(ResetAutoForwardChain)
        EventBus.dispatch(ShowNotification("Loop detected", #Warning))
      } else {
        dispatch(AddToAutoForwardChain(state.activeIndex))

        /* Find best forward link */
        let nextLink = Belt.Array.getBy(currentScene.hotspots, h => {
          switch h.isReturnLink {
          | Some(true) => false
          | _ => true
          }
        })

        switch nextLink {
        | Some(h) =>
          switch Belt.Array.getIndexBy(state.scenes, s => s.name == h.target) {
          | Some(targetIdx) =>
            let hIdx =
              Belt.Array.getIndexBy(currentScene.hotspots, hh =>
                hh.linkId == h.linkId
              )->Belt.Option.getWithDefault(0)

            Logger.info(
              ~module_="Navigation",
              ~message="AUTO_FORWARD_JUMP",
              ~data={"from": currentScene.name, "to": h.target},
              (),
            )

            // Wait a small delay to allow viewer to stabilize if needed, but JS was immediate
            navigateToScene(dispatch, state, targetIdx, state.activeIndex, hIdx, ())
          | None =>
            Logger.error(
              ~module_="Navigation",
              ~message="AUTO_FORWARD_FAILED",
              ~data={"reason": "Target not found", "target": h.target},
              (),
            )
          }
        | None =>
          Logger.warn(
            ~module_="Navigation",
            ~message="AUTO_FORWARD_FAILED",
            ~data={"reason": "No forward link found"},
            (),
          )
        }
      }
    }
  }
}

let setSimulationMode = (dispatch: Actions.action => unit, state: state, val: bool) => {
  dispatch(SetSimulationMode(val))
  Logger.info(~module_="Navigation", ~message="SIMULATION_MODE_CHANGED", ~data={"enabled": val}, ())

  dispatch(ResetAutoForwardChain)
  dispatch(SetIncomingLink(None))
  dispatch(IncrementJourneyId)
  EventBus.dispatch(ClearSimUi)
  dispatch(SetNavigationStatus(Idle))

  if val {
    if state.activeIndex >= 0 {
      /* Timeout 100ms logic */
      let _ = ReBindings.Window.setTimeout(() => {
        switch Belt.Array.get(state.scenes, state.activeIndex) {
        | Some(scene) => handleAutoForward(dispatch, state, scene)
        | None => ()
        }
      }, 100)
    }
  }
}

/* Initialization */

let cancelNavigation = () => {
  Logger.info(~module_="Navigation", ~message="NAV_CANCELLED", ())
  EventBus.dispatch(NavCancelled)
}

let initNavigation = (dispatch: Actions.action => unit) => {
  dispatch(SetSimulationMode(false))
  dispatch(SetCurrentJourneyId(0))
  dispatch(SetNavigationStatus(Idle))
  dispatch(SetIncomingLink(None))
  dispatch(ResetAutoForwardChain)

  /* Subscribe */
  /* Subscribe via EventBus */
  let _ = EventBus.subscribe(event => {
    switch event {
    | NavCompleted(journey) =>
      dispatch(NavigationCompleted(journey))
      Logger.endOperation(
        ~module_="Navigation",
        ~operation="NAV",
        ~data={
          "targetIndex": journey.targetIndex,
          "journeyId": journey.journeyId,
          "durationMs": Date.now() -. navStartTime.contents,
        },
        (),
      )
    | NavCancelled =>
      dispatch(SetNavigationStatus(Idle))
      Logger.info(~module_="Navigation", ~message="NAV_CANCELLED_CLEANUP", ())
    | _ => ()
    }
  })

  Logger.initialized(~module_="Navigation")
}
