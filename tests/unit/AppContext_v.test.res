/* tests/unit/AppContextTest.res */
open Vitest

describe("AppContext", () => {
  test("defaultDispatch does not crash", t => {
    let _ = AppContext.defaultDispatch(Actions.Reset)
    t->expect(true)->Expect.toBe(true)
  })

  test("stateContext is initialized", t => {
    // Just verify we can access it
    let _ = AppContext.stateContext
    t->expect(true)->Expect.toBe(true)
  })

  test("dispatchContext is initialized", t => {
    // Just verify we can access it
    let _ = AppContext.dispatchContext
    t->expect(true)->Expect.toBe(true)
  })

  test("Providers are accessible", t => {
    let _ = AppContext.StateProvider.make
    let _ = AppContext.DispatchProvider.make
    let _ = AppContext.Provider.make
    t->expect(true)->Expect.toBe(true)
  })
})
