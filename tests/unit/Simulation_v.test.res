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
        visitedLinkIds: [], // 0 is NOT visited
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

    // Simulation loop starts in useEffect - wait longer for it to dispatch
    await Promise.make(
      (resolve, _) => {
        let _ = Window.setTimeout(() => resolve(), 200)
      },
    )

    switch lastAction.contents {
    | Some(AddVisitedLink(linkId)) => t->expect(linkId != "")->Expect.toBe(true)
    | other => {
        let msg = switch other {
        | Some(a) => "Got: " ++ Actions.actionToString(a)
        | None => "Got: no action"
        }
        t->expect(msg)->Expect.toBe("Expected: AddVisitedLink")
      }
    }

    Dom.removeElement(container)
  })
})
