open Vitest

describe("Reducers Mod", () => {
  test("should re-export reducers", t => {
    // If these compile, the re-exports are working.
    let _ = Mod.Scene.reduce
    let _ = Mod.Hotspot.reduce
    let _ = Mod.Ui.reduce
    let _ = Mod.Navigation.reduce
    let _ = Mod.Timeline.reduce
    let _ = Mod.Project.reduce
    let _ = Mod.Simulation.reduce
    let _ = Mod.Root.reducer

    t->expect(true)->Expect.toBe(true)
  })
})
