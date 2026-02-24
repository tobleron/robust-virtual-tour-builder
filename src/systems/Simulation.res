/* src/systems/Simulation.res - Consolidated Simulation System */

open Types
open Actions
include SimulationLogic

// --- BINDINGS (INTERNAL) ---
@val external setTimeout: (unit => 'a, int) => int = "setTimeout"

// --- REACT COMPONENT: DRIVER ---

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  // DEBUG PROBE
  let isInvalid = %raw(`function(s) { return typeof s === 'undefined' || s === null || typeof s.simulation === 'undefined' || s.simulation === null }`)(
    state,
  )
  if isInvalid {
    Logger.error(
      ~module_="Simulation",
      ~message="CRITICAL: Simulation loaded with invalid state",
      (),
    )
  }

  // Safe access pattern
  let simulation = if isInvalid {
    State.initialState.simulation
  } else {
    state.simulation
  }
  let activeIndex = if isInvalid {
    -1
  } else {
    state.activeIndex
  }
  let stateRef = React.useRef(state)
  let runIdRef = React.useRef(0)
  let opIdRef = React.useRef(None)

  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])

  // Operation Lifecycle Sync
  React.useEffect1(() => {
    if simulation.status == Running {
      if opIdRef.current == None {
        opIdRef.current = Some(
          OperationLifecycle.start(~type_=Simulation, ~scope=Ambient, ~phase="Running", ()),
        )
      }
    } else {
      switch opIdRef.current {
      | Some(id) =>
        OperationLifecycle.complete(id, ())
        opIdRef.current = None
      | None => ()
      }
    }
    None
  }, [simulation.status])

  let advancingForIndex = React.useRef(-1)

  React.useEffect2(() => {
    let cancel = ref(false)

    Logger.debug(
      ~module_="Simulation",
      ~message="EFFECT_RUN",
      ~data=Some({
        "status": simulation.status == Running ? "Running" : "Stopped",
        "activeIndex": state.activeIndex,
        "advancingForIndex": advancingForIndex.current,
      }),
      (),
    )

    if simulation.status == Running {
      runIdRef.current = runIdRef.current + 1
      let currentRunId = runIdRef.current
      let runTick = async () => {
        let isCurrentRun = () => !cancel.contents && runIdRef.current == currentRunId
        let s = stateRef.current
        let scenes = SceneInventory.getActiveScenes(s.inventory, s.sceneOrder)
        let currentSceneId = scenes->Belt.Array.get(s.activeIndex)->Option.map(ss => ss.id)

        switch currentSceneId {
        | None => ()
        | Some(sceneId) =>
          if advancingForIndex.current != stateRef.current.activeIndex {
            advancingForIndex.current = stateRef.current.activeIndex

            // Note: visitedLinkIds tracking is now handled by SimulationMainLogic.getNextMove()
            // which dispatches AddVisitedLink(hotspot.linkId) when traversing each link
            // This removed the duplicate scene-index based tracking

            let delay = if stateRef.current.simulation.skipAutoForwardGlobal {
              switch scenes->Belt.Array.getBy(ss => ss.id == sceneId) {
              | Some(scene) =>
                // Check if any hotspot in this scene has isAutoForward (link-level)
                let hasAutoForwardLink = Belt.Array.some(scene.hotspots, h =>
                  switch h.isAutoForward {
                  | Some(true) => true
                  | _ => false
                  }
                )
                if hasAutoForwardLink || scene.isAutoForward {
                  0
                } else {
                  Constants.Simulation.stepDelay
                }
              | _ => Constants.Simulation.stepDelay
              }
            } else {
              Constants.Simulation.stepDelay
            }

            Logger.debug(
              ~module_="Simulation",
              ~message="SIM_TICK_WAIT",
              ~data=Some({"sceneId": sceneId, "delay": delay}),
              (),
            )

            let sAfterInitial = stateRef.current
            let stillRunning =
              isCurrentRun() &&
              sAfterInitial.simulation.status == Running &&
              !sAfterInitial.simulation.stoppingOnArrival
            let stillInSameScene =
              scenes
              ->Belt.Array.get(sAfterInitial.activeIndex)
              ->Option.map(ss => ss.id) == Some(sceneId)

            if stillRunning && stillInSameScene {
              try {
                Logger.debug(~module_="Simulation", ~message="SIM_WAIT_FOR_VIEWER", ())
                let waitResult = await Navigation.waitForViewerScene(
                  stateRef.current.activeIndex,
                  () => isCurrentRun() && stateRef.current.simulation.status == Running,
                  ~currentRunId,
                  ~getRunId=() => runIdRef.current,
                  ~getState=() => stateRef.current,
                  (),
                )

                // Re-resolve state after delay
                let sAfterWait = stateRef.current
                let stillOk =
                  isCurrentRun() &&
                  sAfterWait.simulation.status == Running &&
                  scenes
                  ->Belt.Array.get(sAfterWait.activeIndex)
                  ->Option.map(ss => ss.id) == Some(sceneId)

                if stillOk {
                  // Check if this is the first link traversed (for intro pan timing)
                  let isFirstLink = sAfterWait.simulation.visitedLinkIds->Belt.Array.length <= 1
                  let delay = if sAfterWait.simulation.skipAutoForwardGlobal {
                    switch scenes->Belt.Array.getBy(ss => ss.id == sceneId) {
                    | Some(scene) =>
                      // Check if any hotspot has isAutoForward (link-level takes priority)
                      let hasAutoForwardLink = Belt.Array.some(scene.hotspots, h =>
                        switch h.isAutoForward {
                        | Some(true) => true
                        | _ => false
                        }
                      )
                      if hasAutoForwardLink || scene.isAutoForward {
                        isFirstLink ? 3000 : 0
                      } else {
                        Constants.Simulation.stepDelay
                      }
                    | _ => Constants.Simulation.stepDelay
                    }
                  } else {
                    // Even if not skipping, first scene should have a healthy delay for the pan (min 3s)
                    Math.max(Constants.Simulation.stepDelay->Int.toFloat, 3000.0)->Float.toInt
                  }

                  if delay > 0 {
                    Logger.debug(
                      ~module_="Simulation",
                      ~message="SIM_TICK_WAIT",
                      ~data=Some({"sceneId": sceneId, "delay": delay}),
                      (),
                    )

                    let _ = await Promise.make((resolve, _) => {
                      let _ = setTimeout(resolve, delay)
                    })
                  }
                }

                // Final check before advancing
                let sFinal = stateRef.current
                let finalOk =
                  isCurrentRun() &&
                  sFinal.simulation.status == Running &&
                  scenes
                  ->Belt.Array.get(sFinal.activeIndex)
                  ->Option.map(ss => ss.id) == Some(sceneId)

                switch waitResult {
                | Ok()
                  if finalOk &&
                  sFinal.navigationState.navigationFsm == IdleFsm &&
                  !OperationLifecycle.isBusy(~type_=Navigation, ()) =>
                  let move = Logic.getNextMove(sFinal)
                  switch move {
                  | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
                    Logger.info(
                      ~module_="Simulation",
                      ~message="SIM_ADVANCING",
                      ~data=Some({
                        "from": sFinal.activeIndex,
                        "to": targetIndex,
                        "hotspotIndex": hotspotIndex,
                      }),
                      (),
                    )
                    triggerActions->Belt.Array.forEach(a => dispatch(a))
                    Scene.Switcher.navigateToScene(
                      dispatch,
                      stateRef.current,
                      targetIndex,
                      stateRef.current.activeIndex,
                      hotspotIndex,
                      ~targetYaw=yaw,
                      ~targetPitch=pitch,
                      ~targetHfov=hfov,
                      (),
                    )
                  | Complete({reason}) =>
                    Logger.info(
                      ~module_="Simulation",
                      ~message="SIM_COMPLETE",
                      ~data=Some({"reason": reason}),
                      (),
                    )
                    NotificationManager.dispatch({
                      id: "",
                      importance: Success,
                      context: Operation("simulation"),
                      message: "Simulation Complete",
                      details: None,
                      action: None,
                      duration: NotificationTypes.defaultTimeoutMs(Success),
                      dismissible: true,
                      createdAt: Date.now(),
                    })
                    let _ = await Promise.make((resolve, _) => {
                      let _ = setTimeout(resolve, Constants.Simulation.stepDelay)
                    })
                    if !cancel.contents {
                      Scene.Switcher.cancelNavigation()
                      dispatch(StopAutoPilot)
                    }
                  | None =>
                    Logger.warn(~module_="Simulation", ~message="SIM_NO_MOVE", ())
                    Scene.Switcher.cancelNavigation()
                    dispatch(StopAutoPilot)
                  }
                | Ok() =>
                  // Re-arm current scene when navigation is still busy so we can retry on IdleFsm.
                  advancingForIndex.current = -1
                  Logger.debug(
                    ~module_="Simulation",
                    ~message="SIM_TICK_ABORTED_OR_BUSY",
                    ~data=Some({
                      "stillOk": stillOk,
                      "fsmState": switch sAfterWait.navigationState.navigationFsm {
                      | IdleFsm => "IdleFsm"
                      | Preloading(_) => "Preloading"
                      | Transitioning(_) => "Transitioning"
                      | Stabilizing(_) => "Stabilizing"
                      | ErrorFsm(_) => "ErrorFsm"
                      },
                      "activeIndex": sAfterWait.activeIndex,
                    }),
                    (),
                  )
                | Error(msg) =>
                  Logger.error(
                    ~module_="Simulation",
                    ~message="SIM_TICK_ERROR",
                    ~data={"error": msg},
                    (),
                  )
                  NotificationManager.dispatch({
                    id: "",
                    importance: Error,
                    context: Operation("simulation"),
                    message: "Simulation error: " ++ msg,
                    details: None,
                    action: None,
                    duration: NotificationTypes.defaultTimeoutMs(Error),
                    dismissible: true,
                    createdAt: Date.now(),
                  })
                  advancingForIndex.current = -1
                  Scene.Switcher.cancelNavigation()
                  dispatch(StopAutoPilot)
                }
              } catch {
              | err =>
                let (msg, stack) = LoggerCommon.getErrorDetails(err)
                Logger.error(
                  ~module_="Simulation",
                  ~message="SIM_TICK_EXCEPTION",
                  ~data={"error": msg, "stack": stack},
                  (),
                )
                advancingForIndex.current = -1
                dispatch(StopAutoPilot)
              }
            } else if isCurrentRun() {
              // No-op wait cycle on same scene; allow re-check on next effect pass.
              advancingForIndex.current = -1
            }
          }
        }
      }
      let _ = runTick()
    } else {
      runIdRef.current = runIdRef.current + 1
      advancingForIndex.current = -1
    }

    Some(
      () => {
        cancel := true
      },
    )
  }, (simulation.status, activeIndex))

  // Cleanup on unmount
  React.useEffect0(() => {
    Some(
      () => {
        switch opIdRef.current {
        | Some(id) =>
          OperationLifecycle.cancel(id)
          opIdRef.current = None
        | None => ()
        }
      },
    )
  })

  React.null
}
