/* tests/unit/SimulationHelpers_v.test.res */
open Vitest
open Types
open TestUtils

test("SimulationHelpers: handleStartAutoPilot starts simulation", t => {
  let state = createMockState()
  let next = SimulationHelpers.handleStartAutoPilot(state, 123, true)

  switch next.simulation.status {
  | Running => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }

  t->expect(next.simulation.autoPilotJourneyId)->Expect.toBe(123)
  t->expect(next.simulation.skipAutoForwardGlobal)->Expect.toBe(true)
  t->expect(Array.length(next.simulation.visitedLinkIds))->Expect.toBe(0)
  t->expect(next.simulation.stoppingOnArrival)->Expect.toBe(false)
})

test("SimulationHelpers: handleStopAutoPilot resets simulation and increments journey", t => {
  let state = createMockState()
  let state = {
    ...state,
    simulation: {
      ...state.simulation,
      status: Running,
      autoPilotJourneyId: 123,
    },
  }

  let next = SimulationHelpers.handleStopAutoPilot(state)

  switch next.simulation.status {
  | Idle => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }

  t->expect(next.navigationState.navigation)->Expect.toEqual(Idle)
  t
  ->expect(next.navigationState.currentJourneyId)
  ->Expect.toBe(state.navigationState.currentJourneyId + 1)
})

test("SimulationHelpers: handleStartLinking resets simulation", t => {
  let state = createMockState()
  let state = {
    ...state,
    simulation: {
      ...state.simulation,
      status: Running,
    },
  }
  let next = SimulationHelpers.handleStartLinking(state, None)

  t->expect(next.navigationState.navigation)->Expect.toEqual(Idle)
  switch next.simulation.status {
  | Idle => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("SimulationHelpers: handleAddVisitedLink appends linkId", t => {
  let state = createMockState()
  let next = SimulationHelpers.handleAddVisitedLink(state, "A01")
  t->expect(next.simulation.visitedLinkIds)->Expect.toEqual(["A01"])

  let next2 = SimulationHelpers.handleAddVisitedLink(next, "A02")
  t->expect(next2.simulation.visitedLinkIds)->Expect.toEqual(["A01", "A02"])
})
