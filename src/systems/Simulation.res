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
  let simulation = state.simulation
  let stateRef = React.useRef(state)

  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])

  let advancingForIndex = React.useRef(-1)

  React.useEffect2(() => {
    let cancel = ref(false)

    if simulation.status == Running {
      let runTick = async () => {
        let currentIndex = stateRef.current.activeIndex
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

          let _ = await Promise.make((resolve, _) => {
            let _ = setTimeout(resolve, delay)
          })

          if (
            !cancel.contents &&
            stateRef.current.simulation.status == Running &&
            !stateRef.current.simulation.stoppingOnArrival
          ) {
            try {
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
                  | Complete({reason: _reason}) =>
                    EventBus.dispatch(ShowNotification("Simulation Complete", #Success))
                    let _ = await Promise.make((resolve, _) => {
                      let _ = setTimeout(resolve, Constants.Simulation.stepDelay)
                    })
                    if !cancel.contents {
                      Scene.Switcher.cancelNavigation()
                      dispatch(StopAutoPilot)
                    }
                  | None =>
                    Scene.Switcher.cancelNavigation()
                    dispatch(StopAutoPilot)
                  }
                }
              | Error(msg) =>
                EventBus.dispatch(ShowNotification("Simulation error: " ++ msg, #Error))
                Scene.Switcher.cancelNavigation()
                dispatch(StopAutoPilot)
              }
            } catch {
            | _ => dispatch(StopAutoPilot)
            }
          }
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
  }, (simulation.status, state.activeIndex))

  React.null
}
