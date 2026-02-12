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

  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])

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
        let currentSceneId = s.scenes->Belt.Array.get(s.activeIndex)->Option.map(ss => ss.id)

        switch currentSceneId {
        | None => ()
        | Some(sceneId) =>
          if advancingForIndex.current != stateRef.current.activeIndex {
            advancingForIndex.current = stateRef.current.activeIndex

            if (
              !Array.includes(
                stateRef.current.simulation.visitedScenes,
                stateRef.current.activeIndex,
              )
            ) {
              dispatch(AddVisitedScene(stateRef.current.activeIndex))
            }

            let delay = if stateRef.current.simulation.skipAutoForwardGlobal {
              switch stateRef.current.scenes->Belt.Array.getBy(ss => ss.id == sceneId) {
              | Some(scene) if scene.isAutoForward => 0
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

            let _ = await Promise.make((resolve, _) => {
              let _ = setTimeout(resolve, delay)
            })

            // Re-resolve state after delay
            let sAfterDelay = stateRef.current
            let stillRunning =
              isCurrentRun() &&
              sAfterDelay.simulation.status == Running &&
              !sAfterDelay.simulation.stoppingOnArrival
            let stillInSameScene =
              sAfterDelay.scenes
              ->Belt.Array.get(sAfterDelay.activeIndex)
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

                // Re-resolve again after viewer wait
                let sAfterWait = stateRef.current
                let stillOk =
                  isCurrentRun() &&
                  sAfterWait.simulation.status == Running &&
                  sAfterWait.scenes
                  ->Belt.Array.get(sAfterWait.activeIndex)
                  ->Option.map(ss => ss.id) == Some(sceneId)

                switch waitResult {
                | Ok() if stillOk && sAfterWait.navigationState.navigationFsm == IdleFsm =>
                  Logger.debug(
                    ~module_="Simulation",
                    ~message="SIM_READY_TO_ADVANCE",
                    ~data=Some({
                      "activeIndex": sAfterWait.activeIndex,
                      "sceneId": sceneId,
                      "fsmState": "IdleFsm",
                    }),
                    (),
                  )
                  let move = Logic.getNextMove(sAfterWait)
                  switch move {
                  | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
                    Logger.info(
                      ~module_="Simulation",
                      ~message="SIM_ADVANCING",
                      ~data=Some({
                        "from": sAfterWait.activeIndex,
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
              | _err =>
                Logger.error(
                  ~module_="Simulation",
                  ~message="SIM_TICK_EXCEPTION",
                  ~data={"error": "TODO"},
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

    Some(() => {cancel := true})
  }, (simulation.status, activeIndex))

  React.null
}
