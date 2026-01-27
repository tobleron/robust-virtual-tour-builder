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

  const tmMock = {
    startAutoTeaser: globalThis.vi.fn(),
  };
  globalThis.tmMock = tmMock;
  globalThis.vi.mock('../../src/systems/TeaserManager.bs.js', () => tmMock);

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
            {children}
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

  testAsync("should render sidebar branding and version", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

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
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

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
    }

    let mockState = {...State.initialState, scenes: [scene]}
    let mockDispatch = _ => ()
    let sidebarCmp = await loadSidebar()

    let dispatchedEvent = ref(None)
    let _unsubscribe = EventBus.subscribe(ev => dispatchedEvent := Some(ev))

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

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
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

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

  testAsync("should call saveProject when Save button is clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    GlobalStateBridge.setState(mockState)
    let mockDispatch = _ => ()
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

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
    }

    let mockState = {...State.initialState, scenes: [scene]}
    let mockDispatch = _ => ()
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

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
    }

    let mockState = {...State.initialState, scenes: [scene]}
    let mockDispatch = _ => ()
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

    await wait(100)

    let teaserBtn = Dom.querySelector(container, "button[aria-label='Create Teaser']")
    switch Nullable.toOption(teaserBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    await wait(50)

    let called = %raw(`globalThis.tmMock.startAutoTeaser.mock.calls.length > 0`)
    t->expect(called)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should call processUploads when file input changes", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedSidebar mockState mockDispatch>
      {React.createElement(sidebarCmp, Object.make())}
    </WrappedSidebar>)

    await wait(100)

    let input = Dom.querySelector(container, "input[type='file'][accept='image/jpeg,image/png,image/webp']")
    switch Nullable.toOption(input) {
    | Some(el) =>
      // Mock FileList/File and trigger change
      ignore(%raw(`(inputEl) => {
         const file = new File(['content'], 'test.jpg', { type: 'image/jpeg' });
         Object.defineProperty(inputEl, 'files', {
           value: [file]
         });
         inputEl.dispatchEvent(new Event('change', { bubbles: true }));
      }`)(el))
      await wait(100)
    | None => t->expect(false)->Expect.toBe(true)
    }

    let called = %raw(`globalThis.upMock.processUploads.mock.calls.length > 0`)
    t->expect(called)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
