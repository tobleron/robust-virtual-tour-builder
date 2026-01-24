open Vitest
open StateInspector

// Force import of Constants for use in %raw
let _ = Constants.enableStateInspector

describe("StateInspector", _ => {
  beforeEach(() => {
    // Reset window.store before each test
    let _ = %raw(`delete globalThis.window.store`)
    GlobalStateBridge.setState(State.initialState)
  })

  test("createSnapshot verified", t => {
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
    t->expect(snapshot.timestamp > 0.0)->Expect.toBe(true)
  })

  test("getDebugSnapshot returns snapshot of current state", t => {
    let snapshot = getDebugSnapshot()
    let state = GlobalStateBridge.getState()
    t->expect(snapshot.tourName)->Expect.toBe(state.tourName)
  })

  test("exposeToWindow should attach store to window when enabled", t => {
    // Force enableStateInspector to return true for this test
    let _ = %raw(`
      vi.spyOn(Constants, 'enableStateInspector').mockReturnValue(true)
    `)

    exposeToWindow()

    let hasStore = %raw(`!!globalThis.window.store`)
    t->expect(hasStore)->Expect.toBe(true)

    let storeState = %raw(`globalThis.window.store.state`)
    t->expect(storeState.tourName)->Expect.toBe("Tour Name")

    let _ = %raw(`
      Constants.enableStateInspector.mockRestore()
    `)
  })

  test("exposeToWindow should NOT attach store to window when disabled", t => {
    // Force enableStateInspector to return false
    let _ = %raw(`
      vi.spyOn(Constants, 'enableStateInspector').mockReturnValue(false)
    `)

    exposeToWindow()

    let hasStore = %raw(`!!globalThis.window.store`)
    t->expect(hasStore)->Expect.toBe(false)

    let _ = %raw(`
      Constants.enableStateInspector.mockRestore()
    `)
  })

  test("removeFromWindow should remove store from window", t => {
    // Manually attach something to window.store
    let _ = %raw(`globalThis.window.store = { test: true }`)

    removeFromWindow()

    let hasStore = %raw(`!!globalThis.window.store`)
    t->expect(hasStore)->Expect.toBe(false)
  })

  test("window.store.getFullState should return frozen state", t => {
    let _ = %raw(`
      vi.spyOn(Constants, 'enableStateInspector').mockReturnValue(true)
    `)
    exposeToWindow()

    let fullState = %raw(`globalThis.window.store.getFullState()`)
    t->expect(fullState.tourName)->Expect.toBe("Tour Name")

    // Test it's frozen
    let isFrozen = %raw(`Object.isFrozen(fullState)`)
    t->expect(isFrozen)->Expect.toBe(true)

    let _ = %raw(`
      Constants.enableStateInspector.mockRestore()
    `)
  })
})
