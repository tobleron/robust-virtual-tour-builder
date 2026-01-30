// @efficiency: infra-adapter
open Vitest
open ReBindings

/* Mocks */
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
  vi.mock('../../src/systems/Navigation.bs.js', () => {
    const React = require('react');
    return {
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
        make: () => React.createElement('div', { 'data-testid': 'navigation-controller' }),
      },
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
  vi.mock('../../src/systems/SimulationDriver.bs.js', () => {
    const React = require('react');
    return {
      make: () => React.createElement('div', { 'data-testid': 'simulation-driver' }),
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
  vi.mock('../../src/components/ui/tooltip.jsx', () => {
      const React = require('react');
      return {
        TooltipProvider: ({children}) => React.createElement('div', { 'data-testid': 'tooltip-provider' }, children),
      };
  })
`)

%%raw(`
  vi.mock('../../src/utils/SessionStore.bs.js', () => {
    return {
      loadState: () => undefined,
      saveState: () => {},
    };
  })
`)

%%raw(`
  vi.mock('../../src/core/GlobalStateBridge.bs.js', () => {
    return {
      setDispatch: () => {},
      setState: () => {},
      getInstance: () => ({ state: {}, dispatch: () => {} }),
    };
  })
`)

describe("App", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render main application structure", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <App />)

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

    // Check for NotificationContext
    let notificationContext = Dom.querySelector(container, "[data-testid='notification-context']")
    t->expect(Nullable.toOption(notificationContext)->Belt.Option.isSome)->Expect.toBe(true)

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

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <App />)

    await wait(100)

    let placeholder = Dom.querySelector(container, "#placeholder-text")
    t->expect(Nullable.toOption(placeholder)->Belt.Option.isSome)->Expect.toBe(true)

    let text = Dom.getTextContent(Nullable.getUnsafe(placeholder))
    t->expect(text)->Expect.toBe("Ready to build.")

    Dom.removeElement(container)
  })

  testAsync("should NOT display 'Ready to build' when scenes exist", async t => {
    let container = Dom.createElement("div")
    ignore(Dom.appendChild(Dom.documentBody, container))

    let dummyState: Types.state = %raw(`{
       scenes: [{id: "1"}],
       tourName: "Test",
       activeIndex: 0,
       activeYaw: 0,
       activePitch: 0,
       isLinking: false,
       isTeasing: false,
       simulation: { status: "Idle", visitedScenes: [], stoppingOnArrival: false, skipAutoForwardGlobal: false, lastAdvanceTime: 0, pendingAdvanceId: null, autoPilotJourneyId: 0 }
    }`)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <App initialState={dummyState} />)

    await wait(100)

    let placeholder = Dom.querySelector(container, "#placeholder-text")
    t->expect(Nullable.toOption(placeholder)->Belt.Option.isNone)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
