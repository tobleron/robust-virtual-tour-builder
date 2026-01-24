open Vitest
open State
open Types

describe("State", () => {
  test("initialState should have correct default values", t => {
    t->expect(initialState.tourName)->Expect.toBe("Tour Name")
    t->expect(initialState.scenes)->Expect.toEqual([])
    t->expect(initialState.activeIndex)->Expect.toBe(-1)
    t->expect(initialState.activeYaw)->Expect.toBe(0.0)
    t->expect(initialState.activePitch)->Expect.toBe(0.0)
    t->expect(initialState.isLinking)->Expect.toBe(false)
    t->expect(initialState.navigation)->Expect.toEqual(Idle)
    t->expect(initialState.simulation.status)->Expect.toEqual(Idle)
    t->expect(initialState.lastUsedCategory)->Expect.toBe("outdoor")
  })
})
