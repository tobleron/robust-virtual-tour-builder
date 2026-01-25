open Vitest
open ReBindings
open Types

module WrappedSceneList = {
  @react.component
  let make = (~mockState: Types.state, ~mockDispatch: Actions.action => unit) => {
    let sceneSlice: AppContext.sceneSlice = {
      scenes: mockState.scenes,
      activeIndex: mockState.activeIndex,
      tourName: mockState.tourName,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.GlobalProvider value=mockState>
        <AppContext.SceneSliceProvider value=sceneSlice>
          <AppContext.UiSliceProvider value=uiSlice>
            <SceneList />
          </AppContext.UiSliceProvider>
        </AppContext.SceneSliceProvider>
      </AppContext.GlobalProvider>
    </AppContext.DispatchProvider>
  }
}

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
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

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
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

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

  testAsync("should respect virtualization and only render subset of many scenes", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scenes = Array.fromInitializer(
      ~length=50,
      i => createScene(Int.toString(i), "Scene " ++ Int.toString(i)),
    )
    let mockState = {
      ...State.initialState,
      scenes,
    }
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

    await wait(100)

    let items = Dom.querySelectorAll(container, ".scene-item")
    // Default viewport 800px / 72px = ~11.1 + buffer/visibleCount logic should be around 33
    t->expect(Dom.nodeListLength(items) < 50)->Expect.toBe(true)
    t->expect(Dom.nodeListLength(items) > 10)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should throttle scene switching clicks", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let s1 = createScene("1", "S1")
    let s2 = createScene("2", "S2")
    let mockState = {...State.initialState, scenes: [s1, s2], activeIndex: 0}
    let lastAction = ref(None)
    let mockDispatch = action => lastAction.contents = Some(action)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

    await wait(50)

    // Mock lastSwitchTime to be recent
    ViewerState.state.lastSwitchTime = Date.now()

    let clickSecondItem: Dom.element => unit = %raw(`(container) => {
      const items = container.querySelectorAll(".scene-item");
      if (items[1]) items[1].click();
    }`)

    // Attempt to click second item
    clickSecondItem(container)

    // Should NOT have dispatched SetActiveScene because of throttle
    t->expect(lastAction.contents)->Expect.toBe(None)

    // Wait for throttle and try again
    await wait(700)
    clickSecondItem(container)

    switch lastAction.contents {
    | Some(Actions.SetActiveScene(idx, _, _, _)) => t->expect(idx)->Expect.toBe(1)
    | _ => t->expect("SetActiveScene")->Expect.toBe("Dispatched")
    }

    Dom.removeElement(container)
  })
})
