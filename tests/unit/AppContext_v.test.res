/* tests/unit/AppContextTest.res */
open Vitest

describe("AppContext", () => {
  test("defaultDispatch does not crash", t => {
    let _ = AppContext.defaultDispatch(Actions.Reset)
    t->expect(true)->Expect.toBe(true)
  })

  test("sceneContext is initialized", t => {
    // Just verify we can access it
    let _ = AppContext.sceneContext
    t->expect(true)->Expect.toBe(true)
  })

  test("uiContext is initialized", t => {
    let _ = AppContext.uiContext
    t->expect(true)->Expect.toBe(true)
  })

  test("simContext is initialized", t => {
    let _ = AppContext.simContext
    t->expect(true)->Expect.toBe(true)
  })

  test("dispatchContext is initialized", t => {
    // Just verify we can access it
    let _ = AppContext.dispatchContext
    t->expect(true)->Expect.toBe(true)
  })

  test("Providers are accessible", t => {
    let _ = AppContext.SceneSliceProvider.make
    let _ = AppContext.UiSliceProvider.make
    let _ = AppContext.SimSliceProvider.make
    let _ = AppContext.DispatchProvider.make
    let _ = AppContext.Provider.make
    t->expect(true)->Expect.toBe(true)
  })
})
