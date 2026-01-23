open Vitest
open ReBindings
open Types

describe("SceneList", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let createScene = (id, name): scene => {
    {
      id,
      name,
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "test",
      floor: "1",
      label: "label",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      preCalculatedSnapshot: None,
    }
  }

  testAsync("should render empty state when no scenes", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

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
          <SceneList />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    let emptyText = Dom.querySelector(container, "h4")
    t->expect(Belt.Option.isSome(Nullable.toOption(emptyText)))->Expect.toBe(true)

    switch Nullable.toOption(emptyText) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("No scenes")
    | None => ()
    }

    Dom.removeElement(container)
  })

  testAsync("should render scenes when populated", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let s1 = createScene("1", "Scene 1")
    let mockState = {
      ...State.initialState,
      scenes: [s1],
      activeIndex: 0,
    }
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.StateProvider value=mockState>
          <SceneList />
        </AppContext.StateProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(100)

    let items = Dom.querySelectorAll(container, ".scene-item")
    t->expect(Dom.nodeListLength(items))->Expect.toBe(1)

    let sceneName = Dom.querySelector(container, "h4")
    switch Nullable.toOption(sceneName) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("Scene 1")
    | None => ()
    }

    Dom.removeElement(container)
  })
})
