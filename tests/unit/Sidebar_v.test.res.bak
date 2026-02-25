// @efficiency: infra-adapter
/* tests/unit/Sidebar_v.test.res */
open Vitest
open ReBindings

%raw(`
(() => {
  globalThis.vi.mock('../../src/components/SceneList.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'scene-list' }),
    };
  });

  const pmMock = {
    saveProject: globalThis.vi.fn().mockResolvedValue(true),
    loadProject: globalThis.vi.fn(),
  };
  globalThis.pmMock = pmMock;
  globalThis.vi.mock('../../src/systems/ProjectManager.bs.js', () => pmMock);

  const exporterMock = {
    exportTour: globalThis.vi.fn().mockResolvedValue({TAG: 0, _0: undefined}),
  };
  globalThis.exporterMock = exporterMock;
  globalThis.vi.mock('../../src/systems/Exporter.bs.js', () => exporterMock);

  const teaserMock = {
    startAutoTeaser: globalThis.vi.fn().mockResolvedValue(),
    startHeadlessTeaserWithStyle: globalThis.vi.fn().mockResolvedValue(),
  };
  globalThis.teaserMock = teaserMock;
  globalThis.vi.mock('../../src/systems/Teaser.bs.js', () => teaserMock);

  const upMock = {
    processUploads: globalThis.vi.fn().mockResolvedValue({
      qualityResults: [],
      report: {
        totalFiles: 0,
        processed: 0,
        errors: 0,
        duplicates: 0,
        rejected: 0,
        details: []
      }
    }),
  };
  globalThis.upMock = upMock;
  globalThis.vi.mock('../../src/systems/UploadProcessor.bs.js', () => upMock);
})()
`)

module WrappedSidebar = {
  @react.component
  let make = (~mockState: Types.state, ~mockDispatch: Actions.action => unit, ~children) => {
    let sceneSlice: AppContext.sceneSlice = {
      scenes: SceneInventory.getActiveScenes(mockState.inventory, mockState.sceneOrder),
      activeIndex: mockState.activeIndex,
      tourName: mockState.tourName,
      activeYaw: mockState.activeYaw,
      activePitch: mockState.activePitch,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      movingHotspot: mockState.movingHotspot,
      appMode: mockState.appMode,
      logo: mockState.logo,
      preloadingSceneIndex: mockState.preloadingSceneIndex,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.GlobalProvider value=mockState>
        <AppContext.SceneSliceProvider value=sceneSlice>
          <AppContext.UiSliceProvider value=uiSlice>
            {children}
            <ModalContext />
          </AppContext.UiSliceProvider>
        </AppContext.SceneSliceProvider>
      </AppContext.GlobalProvider>
    </AppContext.DispatchProvider>
  }
}

describe("Sidebar", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let loadSidebar = async () => {
    let m = await %raw(`import('../../src/components/Sidebar.bs.js')`)
    m["make"]
  }

  afterEach(() => {
    OperationLifecycle.reset()
    InteractionGuard.clear()
  })

  testAsync("should render sidebar branding and version", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
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
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
    )

    await wait(100)

    let input = Dom.querySelector(container, "input#project-name-input")
    switch Nullable.toOption(input) {
    | Some(el) =>
      t->expect(Dom.getValue(el))->Expect.toBe("Initial Name")

      // Simulate input change
      ignore(
        %raw(`(inputEl) => {
        const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
        nativeInputValueSetter.call(inputEl, 'Updated Name');
        inputEl.dispatchEvent(new Event('input', { bubbles: true }));
      }`)(el),
      )
      await wait(400)
    | None => t->expect(false)->Expect.toBe(true)
    }

    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.SetTourName("Updated Name")))

    Dom.removeElement(container)
  })

  testAsync("should handle 'New' button click with confirmation if scenes exist", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let hotspot: Types.hotspot = {
      linkId: "h1",
      yaw: 0.0,
      pitch: 0.0,
      target: "s2",
      targetSceneId: None,
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
      isAutoForward: None,
    }

    let scene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [hotspot],
      category: "",
      floor: "",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 0,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let dispatchedEvent = ref(None)
    let _unsubscribe = EventBus.subscribe(ev => dispatchedEvent := Some(ev))

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
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
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
    )

    await wait(100)

    let opId = OperationLifecycle.start(
      ~type_=OperationLifecycle.ProjectLoad,
      ~scope=OperationLifecycle.Blocking,
      ~visibleAfterMs=0,
      (),
    )
    OperationLifecycle.progress(opId, 45.0, ~message="Uploading icons...", ~phase="Upload", ())

    await wait(100)

    let status = Dom.querySelector(container, "[role='status']")
    t->expect(Nullable.toOption(status)->Belt.Option.isSome)->Expect.toBe(true)

    let progressText = Dom.querySelector(container, ".sidebar-progress-percentage")
    t->expect(Dom.getTextContent(Nullable.getUnsafe(progressText)))->Expect.toBe("45%")

    let messageText = Dom.querySelector(container, ".truncate")
    t
    ->expect(Dom.getTextContent(Nullable.getUnsafe(messageText)))
    ->Expect.toBe("Uploading icons...")

    Dom.removeElement(container)
  })

  testAsync("should call saveProject when Save button is clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    }
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
    )

    await wait(100)

    let saveBtn = Dom.querySelector(container, "button[aria-label='Save']")
    switch Nullable.toOption(saveBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    await wait(50)

    let called = %raw(`globalThis.pmMock.saveProject.mock.calls.length > 0`)
    t->expect(called)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should call exportTour when Export button is clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let hotspot: Types.hotspot = {
      linkId: "h1",
      yaw: 0.0,
      pitch: 0.0,
      target: "s2",
      targetSceneId: None,
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
      isAutoForward: None,
    }

    let scene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [hotspot],
      category: "",
      floor: "",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 0,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
    )

    await wait(100)

    let exportBtn = Dom.querySelector(container, "button[aria-label='Export Tour']")
    switch Nullable.toOption(exportBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    await wait(50)

    let called = %raw(`globalThis.exporterMock.exportTour.mock.calls.length > 0`)
    t->expect(called)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should call startAutoTeaser when Teaser button is clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    // We need enough hotspots to enable Teaser button (>= 3)
    let hotspot: Types.hotspot = {
      linkId: "h1",
      yaw: 0.0,
      pitch: 0.0,
      target: "s2",
      targetSceneId: None,
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
      isAutoForward: None,
    }

    let scene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [hotspot, hotspot, hotspot],
      category: "",
      floor: "",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 0,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
    )

    await wait(100)

    let teaserBtn = Dom.querySelector(container, "button[aria-label='Create Teaser']")
    switch Nullable.toOption(teaserBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    await wait(100)

    // Modal should be open, find the "Cinematic (WebM)" button
    let modalButtons = Dom.querySelectorAll(container, ".modal-btn-premium")
    let styleBtn = ref(None)
    Belt.Array.forEach(
      JsHelpers.from(modalButtons),
      btn => {
        if String.includes(Dom.getTextContent(btn), "Cinematic (WebM)") {
          styleBtn := Some(btn)
        }
      },
    )

    switch styleBtn.contents {
    | Some(btn) => Dom.click(btn)
    | None => ()
    }

    await wait(50)

    let called = %raw(`globalThis.teaserMock.startHeadlessTeaserWithStyle.mock.calls.length > 0`)
    t->expect(called)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should render image upload file input with expected accept types", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    }
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)
    AppStateBridge.updateState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedSidebar mockState mockDispatch>
        {React.createElement(sidebarCmp, Object.make())}
      </WrappedSidebar>,
    )

    await wait(100)

    let inputs = Dom.querySelectorAll(container, "input[type='file']")
    let input = Belt.Array.getBy(
      JsHelpers.from(inputs),
      el => {
        Dom.getAttribute(el, "accept")
        ->Nullable.toOption
        ->Option.getOr("")
        ->String.includes("image/jpeg")
      },
    )
    switch input {
    | Some(el) =>
      let accept = Dom.getAttribute(el, "accept")->Nullable.toOption->Option.getOr("")
      t->expect(accept)->Expect.toBe("image/jpeg,image/png,image/webp")
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
