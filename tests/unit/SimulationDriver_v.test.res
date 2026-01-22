/* tests/unit/SimulationDriver_v.test.res */
open Vitest

describe("SimulationDriver", () => {
  test("Module exists and exports make", t => {
    let _ = SimulationDriver.make
    t->expect(true)->Expect.toBe(true)
  })

  test("Component can be instantiated as a React element", t => {
    let _ = <SimulationDriver />
    t->expect(true)->Expect.toBe(true)
  })
})
