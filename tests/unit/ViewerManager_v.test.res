/* tests/unit/ViewerManager_v.test.res */
open Vitest
open ReBindings
open Types

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"
@send external toHaveBeenCalledWith2: (expectation, 'a, 'b) => unit = "toHaveBeenCalledWith"

type mockFn
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

/* Mocks */
%%raw(`
  vi.mock('../../src/systems/InputSystem.bs.js', () => ({
    initInputSystem: vi.fn(),
    handleMouseMove: vi.fn(),
  }))
`)

%%raw(`
  vi.mock('../../src/systems/LinkEditorLogic.bs.js', () => ({
    handleStageClick: vi.fn(),
    handleStagePointerDown: vi.fn(),
  }))
`)

@module("../../src/systems/InputSystem.bs.js")
external mockInitInputSystem: mockFn = "initInputSystem"
@module("../../src/systems/InputSystem.bs.js")
external mockHandleMouseMove: mockFn = "handleMouseMove"
@module("../../src/systems/LinkEditorLogic.bs.js")
external mockHandleStageClick: mockFn = "handleStageClick"
@module("../../src/systems/LinkEditorLogic.bs.js")
external mockHandleStagePointerDown: mockFn = "handleStagePointerDown"

%%raw(`
  vi.mock('../../src/systems/Navigation.bs.js', () => ({
    __esModule: true,
    FSM: {
      reducer: vi.fn(),
      toString: vi.fn(),
    },
    Graph: {},
    Renderer: {
      activeJourneyId: { contents: undefined },
      setupBlinks: vi.fn(),
      startJourney: vi.fn(),
      init: vi.fn(),
    },
    UI: {
      updateReturnPrompt: vi.fn(),
    },
    Controller: {
      make: vi.fn(),
    },
  }))
`)

%%raw(`
  vi.mock('../../src/core/GlobalStateBridge.bs.js', () => ({
    getState: vi.fn(() => ({
       isLinking: false,
       simulation: { status: 'Idle' },
       activeIndex: -1,
       scenes: [],
       navigation: 'Idle',
       linkDraft: undefined,
       simulation: { status: 'Idle' }
    })),
    dispatch: vi.fn(),
    setDispatch: vi.fn(),
    setState: vi.fn(),
  }))
`)

@module("../../src/core/GlobalStateBridge.bs.js") external mockGetState: mockFn = "getState"
@module("../../src/core/GlobalStateBridge.bs.js") external mockGlobalDispatch: mockFn = "dispatch"
@module("../../src/core/GlobalStateBridge.bs.js") external mockSetDispatch: mockFn = "setDispatch"
@module("../../src/core/GlobalStateBridge.bs.js") external mockSetState: mockFn = "setState"

%%raw(`
  vi.mock('../../src/systems/HotspotLine.bs.js', () => ({
    updateLines: vi.fn(),
    isViewerReady: vi.fn(() => true),
  }))
`)

%%raw(`
  vi.mock('../../src/components/HotspotManager.bs.js', () => ({
    syncHotspots: vi.fn(),
  }))
`)

%%raw(`
  vi.mock('../../src/components/ViewerLoader.bs.js', () => ({
    Loader: {
      loadNewScene: vi.fn(),
    }
  }))
`)

@module("../../src/components/ViewerLoader.bs.js") @scope("Loader")
external mockLoadNewScene: mockFn = "loadNewScene"

%%raw(`
  vi.mock('../../src/components/ViewerFollow.bs.js', () => ({
    updateFollowLoop: vi.fn(),
  }))
`)

%%raw(`
  vi.mock('../../src/systems/EventBus.bs.js', () => ({
    dispatch: vi.fn(),
    subscribe: vi.fn(() => () => {}),
  }))
`)

%%raw(`
  vi.mock('../../src/utils/Logger.bs.js', () => ({
    debug: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
  }))
`)

let makeMockScene = (~id, ~name, ()) => {
  id,
  name,
  file: Url(name ++ ".jpg"),
  tinyFile: None,
  originalFile: None,
  hotspots: [],
  category: "default",
  floor: "ground",
  label: name,
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: false,
  labelSet: false,
  isAutoForward: false,
}

/* SKIPPED: Task 1197 */
/* describe("ViewerManager", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  beforeEach(() => {
    // Reset all mocks before each test
    let _ = %raw(`vi.clearAllMocks()`)

    // Reset ViewerState
    ViewerSystem.Pool.clearInstance("panorama-a")
    ViewerSystem.Pool.clearInstance("panorama-b")
    ViewerSystem.Pool.pool :=
      ViewerSystem.Pool.pool.contents->Belt.Array.map(
        v => {...v, status: v.id == "primary-a" ? #Active : #Background},
      )
    ViewerState.state := {
        ...ViewerState.state.contents,
        isSwapping: false,
        lastSceneId: Nullable.null,
        lastPreloadingIndex: -1,
        followLoopActive: false,
      }

    // Clear document body from previous tests if any
    let body = Dom.documentBody
    Dom.setTextContent(body, "")

    // Setup required DOM elements
    let guide = Dom.createElement("div")
    Dom.setId(guide, "cursor-guide")
    Dom.appendChild(body, guide)

    let stage = Dom.createElement("div")
    Dom.setId(stage, "viewer-stage")
    // Mock getBoundingClientRect
    let _ = %raw(`
      (stage.getBoundingClientRect = () => ({
        top: 0,
        left: 0,
        width: 1000,
        height: 1000,
        bottom: 1000,
        right: 1000
      }))
    `)
    Dom.appendChild(body, stage)

    let panoA = Dom.createElement("div")
    Dom.setId(panoA, "panorama-a")
    Dom.appendChild(body, panoA)

    let panoB = Dom.createElement("div")
    Dom.setId(panoB, "panorama-b")
    Dom.appendChild(body, panoB)

    let svg = Dom.createElement("div")
    Dom.setId(svg, "viewer-hotspot-lines")
    Dom.appendChild(body, svg)
  })

  testAsync("should handle cleanup when no scenes exist", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      scenes: [],
      activeIndex: -1,
    }
    let mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    // Check if viewers were nulled in state (side effect of empty scenes effect)
    let active = ViewerSystem.Pool.getActive()
    t->expect(active->Belt.Option.isSome)->Expect.toBe(true)
    let viewport = active->Belt.Option.getExn
    t->expect(viewport.ViewerSystem.Pool.instance)->Expect.toBe(None)

    let panoA = Dom.getElementById("panorama-a")
    let isActive = switch Nullable.toOption(panoA) {
    | Some(el) => Dom.classList(el)->Dom.ClassList.contains("active")
    | None => false
    }
    t->expect(isActive)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should handle Escape key to cancel linking", async _t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      isLinking: true,
    }
    let mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    // VERIFY: InputSystem was initialized
    expectCall(mockInitInputSystem)->toHaveBeenCalled()

    Dom.removeElement(container)
  })

  testAsync("should update ViewerState on mouse move on stage", async _t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let _mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(_mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=_mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    await wait(50)

    let stage = Dom.getElementById("viewer-stage")->Nullable.getUnsafe
    let moveEvent = %raw(`new MouseEvent('mousemove', { clientX: 500, clientY: 500 })`)
    let _ = %raw(`(stage, ev) => stage.dispatchEvent(ev)`)(stage, moveEvent)

    // VERIFY: handleMouseMove was called
    expectCall(mockHandleMouseMove)->toHaveBeenCalled()

    Dom.removeElement(container)
  })

  testAsync("should handle stage click during linking", async _t => {
    let scene1 = makeMockScene(~id="scene-1", ~name="Scene 1", ())

    // Mock GlobalStateBridge.getState to return isLinking: true
    mockGetState->mockReturnValue({
      "isLinking": true,
      "simulation": {"status": "Idle"},
      "activeIndex": 0,
      "scenes": [scene1],
      "linkDraft": undefined,
    })

    // Mock Viewer object and active viewer
    let mockViewer = {
      "mouseEventToCoords": _ => [10.0, 20.0],
      "getPitch": () => 5.0,
      "getYaw": () => 15.0,
      "getHfov": () => 90.0,
      "destroy": () => (),
    }
    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic(mockViewer))

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      isLinking: true,
      activeIndex: 0,
      scenes: [scene1],
    }
    let mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    let stage = Dom.getElementById("viewer-stage")->Nullable.getUnsafe
    let clickEvent = %raw(`new MouseEvent('click', { clientX: 500, clientY: 500 })`)
    let _ = %raw(`(stage, ev) => stage.dispatchEvent(ev)`)(stage, clickEvent)

    // VERIFY: LinkEditorLogic.handleStageClick was called
    expectCall(mockHandleStageClick)->toHaveBeenCalled()

    Dom.removeElement(container)
  })

  testAsync("should trigger project context reset if lastSceneId is invalid", async t => {
    let scene1 = makeMockScene(~id="new-valid-id", ~name="New Scene", ())

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    // Set an old lastSceneId that is not in the new scenes list
    ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make("old-stale-id")}

    let mockState = {
      ...State.initialState,
      activeIndex: 0,
      scenes: [scene1],
    }
    let mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    // lastSceneId should be reset to null (via ViewerSystem.resetState)
    t->expect(ViewerState.state.contents.lastSceneId)->Expect.toBe(Nullable.null)

    Dom.removeElement(container)
  })

  testAsync("should sync simulation state with body classes", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      simulation: {...State.initialState.simulation, status: Running},
    }
    let mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    let body = Dom.documentBody
    let hasClass = Dom.classList(body)->Dom.ClassList.contains("auto-pilot-active")
    t->expect(hasClass)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should trigger preloading when preloadingSceneIndex changes", async _t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      preloadingSceneIndex: 1,
      scenes: [makeMockScene(~id="s1", ~name="S1", ()), makeMockScene(~id="s2", ~name="S2", ())],
    }
    let mockDispatch = %raw(`vi.fn()`)
    GlobalStateBridge.setDispatch(mockDispatch)
    GlobalStateBridge.setState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <ViewerManager />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    // CHECK: Dispatch was called with StartAnticipatoryLoad event
    expectCall(mockDispatch)->toHaveBeenCalled()

    Dom.removeElement(container)
  })
}) */
