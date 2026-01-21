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

  // Ref to track if we are currently executing an async advance to prevent overlapping
  let isAdvancing = React.useRef(false)

  // Simulation Loop
  React.useEffect2(() => {
    let cancel = ref(false)

    if simulation.status == Running {
      // Logic:
      // 1. If we just arrived (or started), we wait a delay.
      // 2. Then we wait for viewer to load the current scene.
      // 3. Then we calculate next move.
      // 4. Then we execute.

      let runTick = async () => {
        if isAdvancing.current {
          () // Already advancing
        } else {
          isAdvancing.current = true

          let delay = if simulation.skipAutoForwardGlobal {
            // Check if current scene is auto-forward (bridge)
            let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
            switch currentScene {
            | Some(s) if s.isAutoForward => 0
            | _ => 800
            }
          } else {
            800
          }

          // Initial Delay
          let _ = await wait(delay)

          if (
            !cancel.contents &&
            state.simulation.status == Running &&
            !state.simulation.stoppingOnArrival
          ) {
            try {
              // Wait for viewer
              let waitResult = await SimulationNavigation.waitForViewerScene(
                state.activeIndex,
                () => !cancel.contents,
                (),
              )

              switch waitResult {
              | Ok() =>
                if !cancel.contents && state.simulation.status == Running {
                  // Calculate Next Move
                  let move = SimulationLogic.getNextMove(state)

                  switch move {
                  | Move({targetIndex, hotspotIndex, yaw, pitch, hfov, triggerActions}) =>
                    // Exec Actions
                    triggerActions->Belt.Array.forEach(a => dispatch(a))

                    // Exec Navigation
                    Navigation.navigateToScene(
                      dispatch,
                      state,
                      targetIndex,
                      state.activeIndex,
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
                    let _ = await wait(800)
                    if !cancel.contents {
                      dispatch(StopAutoPilot)
                    }
                  | None =>
                    Logger.info(
                      ~module_="Simulation",
                      ~message="SIM_STOPPED",
                      ~data=Some({"reason": "No valid move"}),
                      (),
                    )
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
                  dispatch(StopAutoPilot)
                }
              }
            } catch {
            | _ =>
              Logger.error(~module_="Simulation", ~message="SIM_ERROR", ())
              dispatch(StopAutoPilot)
            }
          }
          isAdvancing.current = false
        }
      }

      // We trigger the tick when activeIndex changes or we just started.
      // But React effects fire on mount/update.
      // If we rely on this effect running on `state.activeIndex`, it works.
      let _ = runTick()
    } else {
      // Reset advancing flag if stopped
      isAdvancing.current = false
    }

    Some(
      () => {
        cancel := true
      },
    )
  }, (simulation.status, state.activeIndex))

  React.null
}
