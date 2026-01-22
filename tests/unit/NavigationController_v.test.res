/* tests/unit/NavigationController_v.test.res */
open Vitest

describe("NavigationController", () => {
  test("Module exists and exports make", t => {
    let _ = NavigationController.make
    t->expect(true)->Expect.toBe(true)
  })

  test("Component can be instantiated as a React element", t => {
    let _ = <NavigationController />
    t->expect(true)->Expect.toBe(true)
  })
})
