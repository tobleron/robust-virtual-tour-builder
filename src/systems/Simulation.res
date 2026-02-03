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
      let runTick = async () => {
        let currentIndex = stateRef.current.activeIndex
        Logger.debug(
          ~module_="Simulation",
          ~message="TICK_CHECK",
          ~data=Some({
            "currentIndex": currentIndex,
            "advancingForIndex": advancingForIndex.current,
            "willRun": advancingForIndex.current != currentIndex,
          }),
          (),
        )
        if advancingForIndex.current != currentIndex {
          advancingForIndex.current = currentIndex
          let s = stateRef.current
          if !Array.includes(s.simulation.visitedScenes, s.activeIndex) {
            dispatch(AddVisitedScene(s.activeIndex))
          }

          let delay = if s.simulation.skipAutoForwardGlobal {
            switch Belt.Array.get(s.scenes, s.activeIndex) {
            | Some(scene) if scene.isAutoForward => 0
            | _ => Constants.Simulation.stepDelay
            }
          } else {
            Constants.Simulation.stepDelay
          }

          Logger.debug(
            ~module_="Simulation",
            ~message="SIM_TICK_WAIT",
            ~data=Some({"sceneIndex": currentIndex, "delay": delay}),
            (),
          )

          let _ = await Promise.make((resolve, _) => {
            let _ = setTimeout(resolve, delay)
          })

          if (
            !cancel.contents &&
            stateRef.current.simulation.status == Running &&
            !stateRef.current.simulation.stoppingOnArrival
          ) {
            try {
              Logger.debug(~module_="Simulation", ~message="SIM_WAIT_FOR_VIEWER", ())
              let waitResult = await Navigation.waitForViewerScene(
                stateRef.current.activeIndex,
                () => !cancel.contents && stateRef.current.simulation.status == Running,
                (),
              )
              switch waitResult {
              | Ok() =>
                if (
                  stateRef.current.navigation == Idle &&
                  !cancel.contents &&
                  stateRef.current.simulation.status == Running
                ) {
                  let move = Logic.getNextMove(stateRef.current)
                  Logger.debug(
                    ~module_="Simulation",
                    ~message="SIM_NEXT_MOVE",
                    ~data=Some({"move": "TODO"}),
                    (),
                  )
                  switch move {
                  | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
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
                    EventBus.dispatch(ShowNotification("Simulation Complete", #Success, None))
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
                } else {
                  Logger.debug(
                    ~module_="Simulation",
                    ~message="SIM_TICK_SKIP",
                    ~data=Some({
                      "nav": stateRef.current.navigation == Idle ? "Idle" : "Busy",
                      "cancel": cancel.contents,
                      "status": stateRef.current.simulation.status == Running
                        ? "Running"
                        : "Stopped",
                    }),
                    (),
                  )
                }
              | Error(msg) =>
                Logger.error(
                  ~module_="Simulation",
                  ~message="SIM_TICK_ERROR",
                  ~data={"error": msg},
                  (),
                )
                EventBus.dispatch(
                  ShowNotification(
                    "Simulation error: " ++ msg,
                    #Error,
                    Some(Logger.castToJson({"error": msg})),
                  ),
                )
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
              dispatch(StopAutoPilot)
            }
          }
          Logger.debug(
            ~module_="Simulation",
            ~message="TICK_COMPLETE",
            ~data=Some({
              "currentIndex": currentIndex,
              "advancingForIndex": advancingForIndex.current,
              "willReset": advancingForIndex.current == currentIndex,
            }),
            (),
          )
          if advancingForIndex.current == currentIndex {
            advancingForIndex.current = -1
          }
        }
      }
      let _ = runTick()
    } else {
      advancingForIndex.current = -1
    }

    Some(() => {cancel := true})
  }, (simulation.status, activeIndex))

  React.null
}
