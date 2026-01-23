/* tests/unit/Sidebar_v.test.res */
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

  testAsync("should render sidebar branding and version", async t => {
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

    let h1 = Dom.querySelector(container, "h1")
    t->expect(Nullable.toOption(h1)->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(Dom.getTextContent(Nullable.getUnsafe(h1)))->Expect.toBe("ROBUST")

    let version = Dom.querySelector(container, ".sidebar-version-line")
    t->expect(Nullable.toOption(version)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should update tour name on input change", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {...State.initialState, tourName: "Initial Name"}
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

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

    let input = Dom.querySelector(container, "input#project-name-input")
    switch Nullable.toOption(input) {
    | Some(el) =>
      t->expect(Dom.getValue(el))->Expect.toBe("Initial Name")

      // Simulate input change
      %raw(`(inputEl) => {
        const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
        nativeInputValueSetter.call(inputEl, 'Updated Name');
        inputEl.dispatchEvent(new Event('input', { bubbles: true }));
      }`)(el)
    | None => t->expect(false)->Expect.toBe(true)
    }

    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.SetTourName("Updated Name")))

    Dom.removeElement(container)
  })

  testAsync("should handle 'New' button click with confirmation if scenes exist", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "",
      floor: "",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      preCalculatedSnapshot: None,
    }

    let mockState = {...State.initialState, scenes: [scene]}
    let mockDispatch = _ => ()

    let dispatchedEvent = ref(None)
    let _unsubscribe = EventBus.subscribe(ev => dispatchedEvent := Some(ev))

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

    let newBtn = Dom.querySelector(container, "button[aria-label='New']")
    switch Nullable.toOption(newBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    switch dispatchedEvent.contents {
    | Some(ShowModal(config)) => t->expect(config.title)->Expect.toBe("Create New Project?")
    | _ => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })

  testAsync("should display processing UI when UpdateProcessing is dispatched", async t => {
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

    EventBus.dispatch(
      UpdateProcessing({
        "active": true,
        "progress": 45.0,
        "message": "Uploading icons...",
        "phase": "Upload",
        "error": false,
      }),
    )

    await wait(50)

    let status = Dom.querySelector(container, "[role='status']")
    t->expect(Nullable.toOption(status)->Belt.Option.isSome)->Expect.toBe(true)

    let progressText = Dom.querySelector(container, ".text-primary")
    t->expect(Dom.getTextContent(Nullable.getUnsafe(progressText)))->Expect.toBe("45%")

    let messageText = Dom.querySelector(container, ".truncate")
    t
    ->expect(Dom.getTextContent(Nullable.getUnsafe(messageText)))
    ->Expect.toBe("Uploading icons...")

    Dom.removeElement(container)
  })
})
