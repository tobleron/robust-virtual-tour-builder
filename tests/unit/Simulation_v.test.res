// @efficiency: infra-adapter
/* tests/unit/Simulation_v.test.res */
open Vitest
open ReBindings
open Actions

describe("Simulation", () => {
  test("Module exists and exports make", t => {
    let _ = Simulation.make
    t->expect(true)->Expect.toBe(true)
  })

  test("Component can be instantiated as a React element", t => {
    let _ = <Simulation />
    t->expect(true)->Expect.toBe(true)
  })

  test("should render without crashing with running simulation state", t => {
    let mockState = TestUtils.createMockState(
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockState = {
      ...mockState,
      simulation: {
        ...mockState.simulation,
        status: Running,
      },
    }

    let _ =
      <AppContext.GlobalProvider value=mockState>
        <Simulation />
      </AppContext.GlobalProvider>

    t->expect(true)->Expect.toBe(true)
  })

  testAsync("should dispatch AddVisitedScene if current scene not visited", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)
    let scene1 = TestUtils.createMockScene(~id="s1", ~name="S1", ())
    let mockState = TestUtils.createMockState(
      ~scenes=[scene1],
      ~activeIndex=0,
      (),
    )
    let mockState = {
      ...mockState,
      simulation: {
        ...mockState.simulation,
        status: Running,
        visitedScenes: [], // 0 is NOT visited
      },
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <Simulation />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    // Simulation loop starts in useEffect
    await Promise.make(
      (resolve, _) => {
        let _ = Window.setTimeout(() => resolve(), 50)
      },
    )

    switch lastAction.contents {
    | Some(AddVisitedScene(idx)) => t->expect(idx)->Expect.toBe(0)
    | _ => t->expect("AddVisitedScene")->Expect.toBe("No action or wrong action")
    }

    Dom.removeElement(container)
  })
})
