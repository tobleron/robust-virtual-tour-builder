open Vitest
open PersistenceLayer
open TestUtils

describe("PersistenceLayer autosave cost", () => {
  test("records autosave cost stats within target for small state", _t => {
    let state = createMockState(~tourName="Benchmark Tour", ())

    for _i in 1 to 5 {
      performSave(state)
    }

    let stats = getAutosaveCostStats()
    _t->expect(stats.sampleCount > 0)->Expect.toBe(true)
    _t->expect(stats.lastMs >= 0.0)->Expect.toBe(true)
    _t->expect(stats.averageMs <= 10.0)->Expect.toBe(true)
  })
})
