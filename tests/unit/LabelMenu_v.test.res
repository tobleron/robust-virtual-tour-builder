open Vitest
open ReBindings

describe("LabelMenu", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render label menu", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.StateProvider value=mockState>
          <LabelMenu onClose={() => ()} />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(150)

    // Check for "Custom Label" text
    let header = Dom.querySelector(container, "h4")
    t->expect(Belt.Option.isSome(Nullable.toOption(header)))->Expect.toBe(true)

    switch Nullable.toOption(header) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("Custom Label")
    | None => ()
    }

    Dom.removeElement(container)
  })
})
