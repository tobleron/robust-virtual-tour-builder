// @efficiency: infra-adapter
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

  afterEach(() => {
    OperationLifecycle.reset()
    InteractionGuard.clear()
    switch NavigationSupervisor.getCurrentTask() {
    | Some(task) => NavigationSupervisor.abort(task.token.id)
    | None => ()
    }
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
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
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
    let mockState = {
      ...State.initialState,
      scenes: [s1, s2],
      activeIndex: 0,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    }
    let lastAction = ref(None)
    let mockDispatch = action => lastAction.contents = Some(action)
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

    await wait(50)

    let clickSecondItem: Dom.element => unit = %raw(`(container) => {
      const items = container.querySelectorAll(".scene-item");
      if (items[1]) {
        try {
          const p = items[1].click();
          if (p && p.catch) p.catch(() => {});
        } catch (e) {}
      }
    }`)

    // Click 1: Should Succeed
    clickSecondItem(container)
    await wait(50)

    switch lastAction.contents {
    | Some(Actions.SetActiveScene(idx, _, _, _)) => t->expect(idx)->Expect.toBe(1)
    | _ => t->expect("First Click")->Expect.toBe("Dispatched")
    }

    lastAction := None

    // Click 2: Should Fail (Throttled)
    clickSecondItem(container)
    await wait(50)

    t->expect(lastAction.contents)->Expect.toBe(None)

    Dom.removeElement(container)
  })

  testAsync("should have drag attributes and quality indicator classes", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let s1 = {
      ...createScene("1", "LowQualityScene"),
      quality: Some(
        {
          "score": 5.0,
          "features": [],
          "is_panorama": true,
          "width": 100,
          "height": 50,
          "avg_color": "#000000",
        }->Obj.magic,
      ),
    }

    let mockState = {
      ...State.initialState,
      scenes: [s1],
    }
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

    await wait(100)

    let item = Dom.querySelector(container, ".scene-item")
    switch Nullable.toOption(item) {
    | Some(el) =>
      t
      ->expect(Dom.getAttribute(el, "draggable")->Nullable.toOption->Option.getOr(""))
      ->Expect.toBe("true")

      let qualityText = Dom.querySelector(el, ".text-danger")
      // Should be text-danger because score 5.0 < 6.5
      t->expect(Belt.Option.isSome(Nullable.toOption(qualityText)))->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }

    Dom.removeElement(container)
  })

  testAsync("menu interactions should trigger correct actions", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let s1 = createScene("1", "Scene 1")
    let mockState = {
      ...State.initialState,
      scenes: [s1],
    }
    let lastAction = ref(None)
    let mockDispatch = action => lastAction.contents = Some(action)
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSceneList mockState mockDispatch />)

    await wait(100)

    // Open menu
    let menuBtn = Dom.querySelector(container, "[aria-label='Actions for Scene 1']")
    switch Nullable.toOption(menuBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }
    await wait(50)

    // We need to query the document body for the dropdown content
    let deleteBtn = %raw(`document.body.querySelector(".text-danger.cursor-pointer")`)

    switch Nullable.toOption(deleteBtn) {
    | Some(btn) =>
      let modalEvent = ref(None)
      let unsubscribe = EventBus.subscribe(
        e => {
          switch e {
          | ShowModal(config) => modalEvent := Some(config)
          | _ => ()
          }
        },
      )

      Dom.click(btn)
      // SceneItem has 800ms delay
      await wait(900)

      // Modal should be triggered
      switch modalEvent.contents {
      | Some(config) =>
        t->expect(config.title)->Expect.toBe("Delete Scene")
        // Find Delete button and click it
        let deleteActionBtn = Belt.Array.getBy(config.buttons, b => b.label == "Delete")
        switch deleteActionBtn {
        | Some(b) => b.onClick()
        | None => t->expect("Delete Button")->Expect.toBe("Found")
        }
      | None => t->expect("ShowModal")->Expect.toBe("Dispatched")
      }

      unsubscribe()

      // Allow queue processing if needed
      await wait(100)

      // Delete is handled via SidebarLogic/OptimisticAction bridge; verify modal workflow fired.
      t->expect(Belt.Option.isSome(modalEvent.contents))->Expect.toBe(true)
    | None => t->expect("Menu Open")->Expect.toBe("Failed")
    }

    Dom.removeElement(container)
  })
})
