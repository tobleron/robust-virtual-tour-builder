// @efficiency: infra-adapter
open Vitest

describe("Reducers Mod", () => {
  test("should re-export reducers", t => {
    // If these compile, the re-exports are working.
    let _ = Reducer.Mod.Scene.reduce
    let _ = Reducer.Mod.Hotspot.reduce
    let _ = Reducer.Mod.Ui.reduce
    let _ = Reducer.Mod.Navigation.reduce
    let _ = Reducer.Mod.Timeline.reduce
    let _ = Reducer.Mod.Project.reduce
    let _ = Reducer.Mod.Simulation.reduce
    let _ = Reducer.reducer

    t->expect(true)->Expect.toBe(true)
  })
})
