open Vitest
open ReBindings
open Types

describe("ViewerManager", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render and handle cleanup when no scenes", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    // Setup required DOM for side effects
    let _ = %raw(`
      (function(){ document.body.innerHTML = '<div id="cursor-guide"></div><div id="panorama-a"></div><div id="panorama-b"></div><div id="viewer-stage"></div>' })()
    `)

    let mockState = {
      ...State.initialState,
      scenes: [],
    }
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.StateProvider value=mockState>
          <ViewerManager />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(100)

    // Check if viewers were nulled in state (side effect of empty scenes effect)
    t->expect(ViewerState.state.viewerA)->Expect.toBe(Nullable.null)
    t->expect(ViewerState.state.viewerB)->Expect.toBe(Nullable.null)

    Dom.removeElement(container)
  })
})
