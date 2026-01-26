/* src/systems/SimulationDriver.res */
open Types
open Actions

@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

/* Helper for async waiting */
let wait = ms =>
  Promise.make((resolve, _) => {
    let _ = setTimeout(resolve, ms)
  })

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let simulation = state.simulation

  // Ref to track latest state to avoid stale closures in async ticks
  let stateRef = React.useRef(state)
  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])

  // Ref to track if we are currently executing an async advance to prevent overlapping
  // We now also track which index we are advancing for to avoid skipping legit changes
  let advancingForIndex = React.useRef(-1)

  // Simulation Loop
  React.useEffect2(() => {
    let cancel = ref(false)

    if simulation.status == Running {
      let runTick = async () => {
        let currentIndex = stateRef.current.activeIndex

        if advancingForIndex.current == currentIndex {
          Logger.debug(
            ~module_="Simulation",
            ~message="SIM_TICK_SKIPPED",
            ~data=Some({"reason": "Already advancing", "index": currentIndex}),
            (),
          )
          ()
        } else {
          advancingForIndex.current = currentIndex

          let s = stateRef.current

          // Ensure current scene is in visited scenes
          if !Array.includes(s.simulation.visitedScenes, s.activeIndex) {
            dispatch(AddVisitedScene(s.activeIndex))
          }

          let delay = if s.simulation.skipAutoForwardGlobal {
            // Check if current scene is auto-forward (bridge)
            let currentScene = Belt.Array.get(s.scenes, s.activeIndex)
            switch currentScene {
            | Some(scene) if scene.isAutoForward => 0
            | _ => Constants.Simulation.stepDelay
            }
          } else {
            Constants.Simulation.stepDelay
          }

          // Initial Delay
          let _ = await wait(delay)

          if (
            !cancel.contents &&
            stateRef.current.simulation.status == Running &&
            !stateRef.current.simulation.stoppingOnArrival
          ) {
            try {
              // Wait for viewer to load the CURRENT scene
              // Use latest state index in case it changed during wait
              let waitResult = await SimulationNavigation.waitForViewerScene(
                stateRef.current.activeIndex,
                () => !cancel.contents && stateRef.current.simulation.status == Running,
                (),
              )

              switch waitResult {
              | Ok() =>
                // Also wait for any ongoing navigation to complete
                // Use latest state to check navigation status
                if (
                  stateRef.current.navigation == Idle &&
                  !cancel.contents &&
                  stateRef.current.simulation.status == Running
                ) {
                  // Calculate Next Move using latest state
                  let move = SimulationLogic.getNextMove(stateRef.current)

                  switch move {
                  | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
                    // Exec Actions
                    triggerActions->Belt.Array.forEach(a => dispatch(a))

                    Logger.info(
                      ~module_="Simulation",
                      ~message="SIM_NAVIGATING",
                      ~data=Some({"from": stateRef.current.activeIndex, "to": targetIndex}),
                      (),
                    )

                    // Exec Navigation - this triggers the animation and viewer swap
                    SceneSwitcher.navigateToScene(
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
                    EventBus.dispatch(ShowNotification("Simulation Complete", #Success))

                    // Wait a bit then stop
                    let _ = await wait(Constants.Simulation.stepDelay)
                    if !cancel.contents {
                      SceneSwitcher.cancelNavigation()
                      dispatch(StopAutoPilot)
                    }
                  | None =>
                    Logger.info(
                      ~module_="Simulation",
                      ~message="SIM_STOPPED",
                      ~data=Some({"reason": "No valid move"}),
                      (),
                    )
                    SceneSwitcher.cancelNavigation()
                    dispatch(StopAutoPilot)
                  }
                }
              | Error(msg) => {
                  Logger.error(
                    ~module_="Simulation",
                    ~message="VIEWER_WAIT_FAILED",
                    ~data=Some({"error": msg}),
                    (),
                  )
                  EventBus.dispatch(ShowNotification("Simulation error: " ++ msg, #Error))
                  SceneSwitcher.cancelNavigation()
                  dispatch(StopAutoPilot)
                }
              }
            } catch {
            | _ =>
              Logger.error(~module_="Simulation", ~message="SIM_ERROR", ())
              dispatch(StopAutoPilot)
            }
          }
          if advancingForIndex.current == currentIndex {
            advancingForIndex.current = -1
          }
        }
      }

      // Trigger the tick
      let _ = runTick()
    } else {
      // Reset advancing ref if stopped
      advancingForIndex.current = -1
    }

    Some(
      () => {
        cancel := true
      },
    )
  }, (simulation.status, state.activeIndex))

  React.null
}
