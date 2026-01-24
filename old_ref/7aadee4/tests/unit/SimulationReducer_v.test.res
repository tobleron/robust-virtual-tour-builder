open Vitest
open Types
open Actions

describe("SimulationReducer", () => {
  let initialState = State.initialState

  test("StartAutoPilot initializes simulation state", t => {
    let action = StartAutoPilot(42, true)
    let result = SimulationReducer.reduce(initialState, action)

    switch result {
    | Some(newState) => {
        let sim = newState.simulation
        t->expect(sim.status)->Expect.toBe(Running)
        t->expect(sim.autoPilotJourneyId)->Expect.toBe(42)
        // t->expect(sim.isAutoPilot)->Expect.toBe(true) // Removed in source
        t->expect(Array.length(sim.visitedScenes))->Expect.toBe(0)
        t->expect(sim.skipAutoForwardGlobal)->Expect.toBe(true)
        t->expect(sim.stoppingOnArrival)->Expect.toBe(false)
      }
    | None => t->expect(true)->Expect.toBe(false) // Fail
    }
  })

  test("StopAutoPilot resets simulation state", t => {
    let runningState = {
      ...initialState,
      simulation: {
        ...initialState.simulation,
        status: Running,
        // isAutoPilot: true,
        pendingAdvanceId: Some(123),
        visitedScenes: [1, 2, 3],
        stoppingOnArrival: true,
        skipAutoForwardGlobal: true,
      },
    }

    let action = StopAutoPilot
    let result = SimulationReducer.reduce(runningState, action)

    switch result {
    | Some(newState) => {
        let sim = newState.simulation
        t->expect(sim.status)->Expect.toBe(Idle)
        // t->expect(sim.isAutoPilot)->Expect.toBe(false) // Removed
        t->expect(sim.pendingAdvanceId)->Expect.toBe(None)
        t->expect(Array.length(sim.visitedScenes))->Expect.toBe(0)
        t->expect(sim.stoppingOnArrival)->Expect.toBe(false)
        t->expect(sim.skipAutoForwardGlobal)->Expect.toBe(false)
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("AddVisitedScene appends to visitedScenes", t => {
    let visitedState = {
      ...initialState,
      simulation: {
        ...initialState.simulation,
        visitedScenes: [10],
      },
    }

    let action = AddVisitedScene(20)
    let result = SimulationReducer.reduce(visitedState, action)

    switch result {
    | Some(newState) => {
        let sim = newState.simulation
        t->expect(Array.length(sim.visitedScenes))->Expect.toBe(2)
        t->expect(sim.visitedScenes)->Expect.toEqual([10, 20])
      }
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("ClearVisitedScenes empties visitedScenes", t => {
    let visitedState = {
      ...initialState,
      simulation: {
        ...initialState.simulation,
        visitedScenes: [10, 20, 30],
      },
    }

    let action = ClearVisitedScenes
    let result = SimulationReducer.reduce(visitedState, action)

    switch result {
    | Some(newState) => t->expect(Array.length(newState.simulation.visitedScenes))->Expect.toBe(0)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("SetStoppingOnArrival updates flag", t => {
    let action = SetStoppingOnArrival(true)
    let result = SimulationReducer.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.simulation.stoppingOnArrival)->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("SetSkipAutoForward updates flag", t => {
    // Check toggle to true
    let result1 = SimulationReducer.reduce(initialState, SetSkipAutoForward(true))
    switch result1 {
    | Some(state) => t->expect(state.simulation.skipAutoForwardGlobal)->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }

    // Check toggle back to false
    let startStateTrue = {
      ...initialState,
      simulation: {...initialState.simulation, skipAutoForwardGlobal: true},
    }
    let result2 = SimulationReducer.reduce(startStateTrue, SetSkipAutoForward(false))
    switch result2 {
    | Some(state) => t->expect(state.simulation.skipAutoForwardGlobal)->Expect.toBe(false)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("UpdateAdvanceTime updates lastAdvanceTime", t => {
    let action = UpdateAdvanceTime(999.5)
    let result = SimulationReducer.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.simulation.lastAdvanceTime)->Expect.toBe(999.5)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("SetPendingAdvance updates pendingAdvanceId", t => {
    let action = SetPendingAdvance(Some(55))
    let result = SimulationReducer.reduce(initialState, action)

    switch result {
    | Some(newState) => t->expect(newState.simulation.pendingAdvanceId)->Expect.toBe(Some(55))
    | None => t->expect(true)->Expect.toBe(false)
    }
  })

  test("Unknown action returns None", t => {
    // Using an action that SimulationReducer doesn't handle, e.g., ToggleSidebar
    // We need to cast or construct an action that is valid in the type system but ignored by this reducer.
    // ToggleSidebar is in Actions
    let action = SetTourName("ignored")
    let result = SimulationReducer.reduce(initialState, action)

    t->expect(result)->Expect.toBe(None)
  })
})
