open Vitest
open ReBindings
open Types

module WrappedViewerHUD = {
  @react.component
  let make = (~mockState: Types.state) => {
    let sceneSlice: AppContext.sceneSlice = {
      scenes: SceneInventory.getActiveScenes(mockState.inventory, mockState.sceneOrder),
      activeIndex: mockState.activeIndex,
      tourName: mockState.tourName,
      activeYaw: mockState.activeYaw,
      activePitch: mockState.activePitch,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      appMode: mockState.appMode,
      logo: mockState.logo,
      preloadingSceneIndex: mockState.preloadingSceneIndex,
    }
    let simSlice: AppContext.simSlice = {
      simulation: mockState.simulation,
      navigation: mockState.navigationState.navigation,
      currentJourneyId: mockState.navigationState.currentJourneyId,
      incomingLink: mockState.navigationState.incomingLink,
    }

    <AppContext.GlobalProvider value=mockState>
      <AppContext.SceneSliceProvider value=sceneSlice>
        <AppContext.UiSliceProvider value=uiSlice>
          <AppContext.SimSliceProvider value=simSlice>
            <ViewerHUD />
          </AppContext.SimSliceProvider>
        </AppContext.UiSliceProvider>
      </AppContext.SceneSliceProvider>
    </AppContext.GlobalProvider>
  }
}

describe("ViewerHUD", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render logo and primary components", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedViewerHUD mockState />)

    await wait(50)

    // Check Logo
    let logo = Dom.getElementById("viewer-logo")
    t->expect(Nullable.toOption(logo)->Belt.Option.isSome)->Expect.toBe(true)

    // Check internal image
    switch Nullable.toOption(logo) {
    | Some(el) =>
      let img = Dom.querySelector(el, "img")
      t->expect(Nullable.toOption(img)->Belt.Option.isSome)->Expect.toBe(true)
    | None => ()
    }

    // Check presence of Utility Bar (via ID)
    let utilBar = Dom.getElementById("viewer-utility-bar")
    t->expect(Nullable.toOption(utilBar)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
