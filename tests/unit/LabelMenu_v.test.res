// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("LabelMenu", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render outdoor presets", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockScene: Types.scene = {
      id: "s1",
      name: "s1.webp",
      file: Url("s1.webp"),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "user",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      sequenceId: 0,
    }
    let mockState = TestUtils.createMockState(~scenes=[mockScene], ~activeIndex=0, ())
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <LabelMenu onClose={() => ()} />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(200)

    // Check for an outdoor preset
    let html = String.toLowerCase(%raw(`container.innerHTML`))
    t->expect(String.includes(html, "front yard"))->Expect.toBe(true)
    t->expect(String.includes(html, "majlis"))->Expect.toBe(false)

    Dom.removeElement(container)
  })

  testAsync("should render indoor presets", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockScene: Types.scene = {
      id: "s1",
      name: "s1.webp",
      file: Url("s1.webp"),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "indoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "user",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      sequenceId: 0,
    }
    let mockState = TestUtils.createMockState(~scenes=[mockScene], ~activeIndex=0, ())
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <LabelMenu onClose={() => ()} />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(200)

    // Check for an indoor preset
    let html = String.toLowerCase(%raw(`container.innerHTML`))
    t->expect(String.includes(html, "majlis"))->Expect.toBe(true)
    t->expect(String.includes(html, "front yard"))->Expect.toBe(false)

    Dom.removeElement(container)
  })

  testAsync("should dispatch clear action when clear button clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)
    let mockState = State.initialState

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <LabelMenu onClose={() => ()} />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(200)

    // Find and click CLEAR LABEL button
    let buttons = Dom.querySelectorAll(container, "button")
    let clearBtn = ref(None)

    // Convert nodeList to array for forEach
    let btnArr: array<Dom.element> = %raw(`(buttons) => Array.from(buttons)`)(buttons)
    btnArr->Belt.Array.forEach(
      btn => {
        if Dom.getTextContent(btn)->String.includes("CLEAR LABEL") {
          clearBtn := Some(btn)
        }
      },
    )

    switch clearBtn.contents {
    | Some(btn) => Dom.click(btn)
    | None => t->expect("Clear button not found")->Expect.toBe("")
    }

    // Verify dispatch
    switch lastAction.contents {
    | Some(UpdateSceneMetadata(_, _)) => t->expect(true)->Expect.toBe(true)
    | _ => t->expect("Correct action not dispatched")->Expect.toBe("")
    }

    Dom.removeElement(container)
  })
})
