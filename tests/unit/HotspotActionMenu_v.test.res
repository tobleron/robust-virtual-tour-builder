open Vitest
open ReBindings
open Types

describe("HotspotActionMenu", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render hotspot action menu", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()

    let hotspot: hotspot = {
      linkId: "hs1",
      yaw: 0.0,
      pitch: 0.0,
      target: "Target",
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      startYaw: None,
      startPitch: None,
      startHfov: None,
      isReturnLink: None,
      viewFrame: None,
      returnViewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.StateProvider value=mockState>
          <HotspotActionMenu hotspot index=0 onClose={() => ()} />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    // Check for GO button text or class
    let goText = Dom.querySelector(container, "span")
    t->expect(Belt.Option.isSome(Nullable.toOption(goText)))->Expect.toBe(true)

    switch Nullable.toOption(goText) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("GO")
    | None => ()
    }

    Dom.removeElement(container)
  })
})
