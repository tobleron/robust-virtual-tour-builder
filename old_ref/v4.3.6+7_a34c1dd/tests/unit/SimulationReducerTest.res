/* tests/unit/SimulationReducerTest.res */
open Types
open Actions

let run = () => {
  Console.log("Running SimulationReducer tests...")

  let initialState = State.initialState

  // Helper to extract simulation state
  let getSimState = (state: state) => state.simulation

  // Test StartAutoPilot
  // Note: Reducer returns option<state>
  let resultStart = SimulationReducer.reduce(initialState, StartAutoPilot(42, false))

  switch resultStart {
  | Some(newState) =>
    let sim = getSimState(newState)
    assert(sim.status == Running)
    assert(sim.autoPilotJourneyId == 42)
    assert(Array.length(sim.visitedScenes) == 0)
    Console.log("✓ StartAutoPilot")
  | None => Console.error("✗ StartAutoPilot failed (returned None)")
  }

  // Test StopAutoPilot
  let stateForStop = {
    ...initialState,
    simulation: {
      ...initialState.simulation,
      status: Running,
      pendingAdvanceId: Some(5),
    },
  }
  let resultStop = SimulationReducer.reduce(stateForStop, StopAutoPilot)

  switch resultStop {
  | Some(newState) =>
    let sim = getSimState(newState)
    assert(sim.status == Idle)
    assert(sim.pendingAdvanceId == None)
    Console.log("✓ StopAutoPilot")
  | None => Console.error("✗ StopAutoPilot failed")
  }

  // Test AddVisitedScene
  let stateForAdd = {
    ...initialState,
    simulation: {
      ...initialState.simulation,
      visitedScenes: [1, 2],
    },
  }
  let resultAdd = SimulationReducer.reduce(stateForAdd, AddVisitedScene(3))

  switch resultAdd {
  | Some(newState) =>
    let sim = getSimState(newState)
    assert(Array.length(sim.visitedScenes) == 3)
    assert(Array.getUnsafe(sim.visitedScenes, 0) == 1)
    assert(Array.getUnsafe(sim.visitedScenes, 2) == 3)
    Console.log("✓ AddVisitedScene")
  | None => Console.error("✗ AddVisitedScene failed")
  }

  // Test UpdateAdvanceTime (Replaces IncrementJourneyId for sim specific, although actions are global)
  // IncrementJourneyId is actually handled by NavigationReducer/Root logic, but we can test sim specific updates

  let resultTime = SimulationReducer.reduce(initialState, UpdateAdvanceTime(12345.0))
  switch resultTime {
  | Some(newState) =>
    assert(newState.simulation.lastAdvanceTime == 12345.0)
    Console.log("✓ UpdateAdvanceTime")
  | None => Console.error("✗ UpdateAdvanceTime failed")
  }

  Console.log("SimulationReducer tests passed!")
}
