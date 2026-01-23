open Vitest
open ReBindings

describe("ViewerUI", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render viewer UI with utility bar", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.StateProvider value=mockState>
          <ViewerUI />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(150)

    let utilBar = Dom.getElementById("viewer-utility-bar")
    t->expect(Belt.Option.isSome(Nullable.toOption(utilBar)))->Expect.toBe(true)

    let logo = Dom.getElementById("viewer-logo")
    t->expect(Belt.Option.isSome(Nullable.toOption(logo)))->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
