open Vitest
open ReBindings

%raw(`
  globalThis.vi.mock('../../src/components/SceneList.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'scene-list' }),
    };
  })
`)

describe("Sidebar", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render sidebar branding", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.StateProvider value=mockState>
          <Sidebar />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(100)

    let branding = Dom.querySelector(container, "h1")
    t->expect(Belt.Option.isSome(Nullable.toOption(branding)))->Expect.toBe(true)

    switch Nullable.toOption(branding) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("ROBUST")
    | None => ()
    }

    Dom.removeElement(container)
  })
})
