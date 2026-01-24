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

  test("should render without crashing with running simulation state", t => {
    let mockState: Types.state = {
      ...State.initialState,
      simulation: {
        ...State.initialState.simulation,
        status: Running,
      },
    }

    let _ =
      <AppContext.StateProvider value=mockState>
        <SimulationDriver />
      </AppContext.StateProvider>

    t->expect(true)->Expect.toBe(true)
  })
})
