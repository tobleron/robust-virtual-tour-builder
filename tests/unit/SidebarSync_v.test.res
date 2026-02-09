// @efficiency: infra-adapter
/* tests/unit/SidebarSync_v.test.res */
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
      scenes: mockState.scenes,
      activeIndex: mockState.activeIndex,
      tourName: mockState.tourName,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      appMode: mockState.appMode,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.GlobalProvider value=mockState>
        <AppContext.SceneSliceProvider value=sceneSlice>
          <AppContext.UiSliceProvider value=uiSlice> {children} </AppContext.UiSliceProvider>
        </AppContext.SceneSliceProvider>
      </AppContext.GlobalProvider>
    </AppContext.DispatchProvider>
  }
}

describe("Sidebar Sync", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let loadSidebar = async () => {
    let m = await %raw(`import('../../src/components/Sidebar.bs.js')`)
    m["make"]
  }

  testAsync("should ignore external update when user has modified input", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {...State.initialState, tourName: "Initial Name"}
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)
    let sidebarCmp = await loadSidebar()

    let root = ReactDOMClient.createRoot(container)
    // We need to re-render to update state
    let render = (s) => {
       ReactDOMClient.Root.render(
        root,
        <WrappedSidebar mockState=s mockDispatch>
          {React.createElement(sidebarCmp, Object.make())}
        </WrappedSidebar>,
      )
    }

    render(mockState)
    await wait(100)

    let input = Dom.querySelector(container, "input#project-name-input")
    switch Nullable.toOption(input) {
    | Some(el) =>
      t->expect(Dom.getValue(el))->Expect.toBe("Initial Name")

      // Simulate input change (User starts typing)
      ignore(
        %raw(`(inputEl) => {
        const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;
        nativeInputValueSetter.call(inputEl, 'User Input');
        inputEl.dispatchEvent(new Event('input', { bubbles: true }));
      }`)(el),
      )

      // Wait for state update inside React (but BEFORE debounce fires - <300ms)
      await wait(50)
      t->expect(Dom.getValue(el))->Expect.toBe("User Input")

      // Now simulate external update (e.g. from Exif)
      let newState = {...mockState, tourName: "External Update"}
      GlobalStateBridge.setState(newState)
      render(newState) // Force re-render with new state

      await wait(50)

      // CRITICAL CHECK:
      // Without fix: The input value should become "External Update" (overwritten).
      // With fix: The input value should remain "User Input".

      // We expect the fix to make it remain "User Input"
      t->expect(Dom.getValue(el))->Expect.toBe("User Input")

    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
