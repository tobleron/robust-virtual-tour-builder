open Vitest
open StateInspector

describe("StateInspector", _ => {
  test("createSnapshot verified", t => {
    // Ensure we have a known state
    GlobalStateBridge.setState(State.initialState)
    let state = GlobalStateBridge.getState()
    let snapshot = createSnapshot(state)

    t->expect(snapshot.tourName)->Expect.toBe(state.tourName)
    t->expect(snapshot.activeSceneIndex)->Expect.toBe(state.activeIndex)
    t->expect(snapshot.sceneCount)->Expect.toBe(Belt.Array.length(state.scenes))
    t->expect(snapshot.isLinking)->Expect.toBe(state.isLinking)

    let expectedSim = switch state.simulation.status {
    | Running => "Running"
    | Idle => "Idle"
    | Paused => "Paused"
    | Stopping => "Stopping"
    }

    t->expect(snapshot.simulationStatus)->Expect.toBe(expectedSim)

    // Check comparison, expecting timestamp > 0.0
    // Vitest bindings may not have toBeGreaterThan, so using boolean check
    t->expect(snapshot.timestamp > 0.0)->Expect.toBe(true)
  })
})
