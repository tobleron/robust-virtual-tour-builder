// @efficiency: infra-adapter
open Vitest

/* Mocks */
%%raw(`
  vi.mock('../../src/components/Sidebar.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'sidebar' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/systems/ThumbnailProjectSystem.bs.js', () => {
    const React = require('react');
    return {
      make: () => null,
    };
  })
`)

%%raw(`
  vi.mock('../../src/components/ViewerUI.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'viewer-ui' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/components/ModalContext.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'modal-context' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/components/NotificationContext.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'notification-context' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/systems/Navigation/NavigationController.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'navigation-controller' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/components/ViewerManager.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'viewer-manager' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/systems/Simulation.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'simulation-mock' }),
    };
  })
`)

%%raw(`
  vi.mock('../../src/components/AppErrorBoundary.bs.js', () => {
      const React = require('react');
      return {
        make: ({children}) => React.createElement('div', { 'data-testid': 'app-error-boundary' }, children),
      };
  })
`)

%%raw(`
  vi.mock('../../src/components/ui/Shadcn.bs.js', () => {
      const React = require('react');
      return {
        Tooltip: {
          Provider: {
            make: ({children}) => React.createElement('div', { 'data-testid': 'tooltip-provider' }, children),
          }
        },
        Sonner: {
          make: () => React.createElement('div', { 'data-testid': 'sonner' }),
        }
      };
  })
`)

%%raw(`
  vi.mock('../../src/core/AppContext.bs.js', () => {
      const React = require('react');
      return {
        Provider: {
          make: ({children}) => React.createElement('div', { 'data-testid': 'app-context-provider' }, children)
        },
        useAppState: vi.fn(() => ({
           scenes: [],
           inventory: Belt.Map.String.empty,
           sceneOrder: [],
           activeIndex: 0,
           activeYaw: 0,
           activePitch: 0,
           isLinking: false,
           isTeasing: false,
           tourName: "Test",
           appMode: { TAG: "Interactive", _0: { uiMode: { TAG: "Browsing" }, navigation: { TAG: "IdleFsm" }, backgroundTask: undefined } },
           simulation: { status: "Idle", visitedScenes: [], stoppingOnArrival: false, skipAutoForwardGlobal: false, lastAdvanceTime: 0, pendingAdvanceId: null, autoPilotJourneyId: 0 }
        })),
        useUiSlice: vi.fn(() => ({
          isLinking: false,
          isTeasing: false,
          linkDraft: undefined,
          appMode: { TAG: "Interactive", _0: { uiMode: { TAG: "Browsing" }, navigation: { TAG: "IdleFsm" }, backgroundTask: undefined } }
        })),
        useAppDispatch: vi.fn(() => vi.fn()),
        useIsSystemLocked: vi.fn(() => false),
        useSceneSlice: vi.fn(() => ({
          scenes: [],
          activeIndex: 0,
          tourName: "Test",
          activeYaw: 0,
          activePitch: 0
        })),
        useSimSlice: vi.fn(() => ({
          simulation: { status: "Idle", visitedScenes: [], stoppingOnArrival: false, skipAutoForwardGlobal: false, lastAdvanceTime: 0, pendingAdvanceId: null, autoPilotJourneyId: 0 },
          navigation: "Idle",
          currentJourneyId: 0,
          incomingLink: undefined
        })),
        useNavigationSlice: vi.fn(() => ({
          navigation: "IdleFsm",
          incomingLink: undefined,
          autoForwardChain: undefined,
          currentJourneyId: undefined
        })),
        usePipelineSlice: vi.fn(() => ({
          timeline: [],
          scenes: [],
          activeIndex: 0,
          activeTimelineStepId: undefined
        }))
      };
    })

`)

/* Helper Modules */
module Dom = {
  type element
  @val external documentBody: element = "document.body"
  @val external createElement: string => element = "document.createElement"
  @send external appendChild: (element, element) => unit = "appendChild"
  @send external removeElement: element => unit = "remove"
  @send external querySelector: (element, string) => Nullable.t<element> = "querySelector"
  @get external getTextContent: element => string = "textContent"
}

module ReactDOMClient = {
  type root
  @module("react-dom/client")
  external createRoot: Dom.element => root = "createRoot"

  module Root = {
    @send external render: (root, React.element) => unit = "render"
  }
}

type mockFn
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@send external mockReset: mockFn => unit = "mockReset"

describe("App", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = setTimeout(() => resolve(), ms)
    })

  /* Note: We use dynamic import for App to ensure mocks defined above are applied before App loads */
  testAsync("should render main application structure", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let app = await %raw(`import("../../src/App.bs.js").then(m => m.make)`)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, React.createElement(app, %raw("{}")))

    await wait(100)

    // Check for Sidebar
    let sidebar = Dom.querySelector(container, "[data-testid='sidebar']")
    t->expect(Nullable.toOption(sidebar)->Belt.Option.isSome)->Expect.toBe(true)

    // Check for ViewerUI
    let viewerUI = Dom.querySelector(container, "[data-testid='viewer-ui']")
    t->expect(Nullable.toOption(viewerUI)->Belt.Option.isSome)->Expect.toBe(true)

    // Check for ModalContext
    let modalContext = Dom.querySelector(container, "[data-testid='modal-context']")
    t->expect(Nullable.toOption(modalContext)->Belt.Option.isSome)->Expect.toBe(true)

    // Check for Controllers
    let navController = Dom.querySelector(container, "[data-testid='navigation-controller']")
    t->expect(Nullable.toOption(navController)->Belt.Option.isSome)->Expect.toBe(true)

    let viewerManager = Dom.querySelector(container, "[data-testid='viewer-manager']")
    t->expect(Nullable.toOption(viewerManager)->Belt.Option.isSome)->Expect.toBe(true)

    let simDriver = Dom.querySelector(container, "[data-testid='simulation-mock']")
    t->expect(Nullable.toOption(simDriver)->Belt.Option.isSome)->Expect.toBe(true)

    // Check for Panorama Layers
    let panoA = Dom.querySelector(container, "#panorama-a")
    t->expect(Nullable.toOption(panoA)->Belt.Option.isSome)->Expect.toBe(true)

    let panoB = Dom.querySelector(container, "#panorama-b")
    t->expect(Nullable.toOption(panoB)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should display 'Ready to build' when no scenes exist", async t => {
    let container = Dom.createElement("div")
    ignore(Dom.appendChild(Dom.documentBody, container))

    let app = await %raw(`import("../../src/App.bs.js").then(m => m.make)`)

    let useAppStateMock: mockFn = await %raw(`import("../../src/core/AppContext.bs.js").then(m => m.useAppState)`)
    useAppStateMock->mockReturnValue(TestUtils.createMockState(~scenes=[], ()))

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, React.createElement(app, %raw("{}")))

    await wait(200)

    let placeholder = Dom.querySelector(container, "#placeholder-text")
    t->expect(Nullable.toOption(placeholder)->Belt.Option.isSome)->Expect.toBe(true)

    let text = Dom.getTextContent(Nullable.getUnsafe(placeholder))
    t->expect(text)->Expect.toBe("Ready to build.")

    Dom.removeElement(container)
  })

  testAsync("should NOT display 'Ready to build' when scenes exist", async t => {
    let container = Dom.createElement("div")
    ignore(Dom.appendChild(Dom.documentBody, container))

    let app = await %raw(`import("../../src/App.bs.js").then(m => m.make)`)

    /* Mock useAppState to return scenes */
    let useAppStateMock: mockFn = await %raw(`import("../../src/core/AppContext.bs.js").then(m => m.useAppState)`)

    // Update mock implementation to return scenes
    let scene1 = TestUtils.createMockScene(~id="1", ~name="Scene 1", ())
    useAppStateMock->mockReturnValue(TestUtils.createMockState(~scenes=[scene1], ()))

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, React.createElement(app, %raw("{}")))

    await wait(100)

    let placeholder = Dom.querySelector(container, "#placeholder-text")
    t->expect(Nullable.toOption(placeholder)->Belt.Option.isNone)->Expect.toBe(true)

    // Reset mock
    useAppStateMock->mockReset

    Dom.removeElement(container)
  })
})
let useAppStateMock: mockFn = await %raw(`import("../../src/core/AppContext.bs.js").then(m => m.useAppState)`)
useAppStateMock->mockReturnValue(
  %raw(`{
         scenes: [],
         inventory: {},
         sceneOrder: [],
         tourName: "Test",
         activeIndex: 0,
         activeYaw: 0,
         activePitch: 0,
         isLinking: false,
         isTeasing: false,
         appMode: { TAG: "Interactive", _0: { uiMode: { TAG: "Browsing" }, navigation: { TAG: "IdleFsm" }, backgroundTask: undefined } },
         simulation: { status: "Idle", visitedScenes: [], stoppingOnArrival: false, skipAutoForwardGlobal: false, lastAdvanceTime: 0, pendingAdvanceId: null, autoPilotJourneyId: 0 }
      }`),
)
