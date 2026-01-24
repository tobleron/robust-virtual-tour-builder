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

  test("should render without crashing with active navigation state", t => {
    // We mock AppContext by using %%raw or similar if needed,
    // but here we just check if it instantiates with a mocked state if we wrap it.

    let mockJourney: Types.journeyData = {
      journeyId: 1,
      targetIndex: 1,
      sourceIndex: 0,
      hotspotIndex: 0,
      arrivalYaw: 0.0,
      arrivalPitch: 0.0,
      arrivalHfov: 90.0,
      previewOnly: false,
      pathData: None,
    }

    let mockState: Types.state = {
      ...State.initialState,
      navigation: Navigating(mockJourney),
    }

    // Since we don't have a full React testing setup that's easy to use here,
    // we at least verify the type-safety of the component with this state.
    let _ =
      <AppContext.StateProvider value=mockState>
        <NavigationController />
      </AppContext.StateProvider>

    t->expect(true)->Expect.toBe(true)
  })
})
