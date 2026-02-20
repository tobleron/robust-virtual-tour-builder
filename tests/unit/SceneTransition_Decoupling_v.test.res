open Vitest
open Types

/* Mocks */
%%raw(`
  import { vi } from "vitest";

  // Mock ViewerSystem
  vi.mock("../../src/systems/ViewerSystem.bs.js", () => {
    return {
      Pool: {
        getActive: () => ({id: "v1", containerId: "c1", status: "Active"}),
        getInactive: () => ({id: "v2", containerId: "c2", status: "Background"}),
        getActiveViewer: () => ({}),
        getInactiveViewer: () => ({}),
        swapActive: () => {},
        clearCleanupTimeout: () => {},
        clearInstance: () => {},
        setCleanupTimeout: () => {}
      },
      getActiveViewer: () => ({}),
      getInactiveViewer: () => ({}),
      isViewerReady: () => true,
      Adapter: {
        destroy: () => { globalThis.mockDestroyCalled = (globalThis.mockDestroyCalled || 0) + 1; }
      }
    }
  });

  // Mock HotspotLine
  vi.mock("../../src/systems/HotspotLine.bs.js", () => ({
      isViewerReady: () => true,
      updateLines: () => {}
  }));

  // Mock ViewerSnapshot
  vi.mock("../../src/components/ViewerSnapshot.bs.js", () => ({
      requestIdleSnapshot: () => {}
  }));
`)

module Vi = {
  @module("vitest") @scope("vi") external useFakeTimers: unit => unit = "useFakeTimers"
  @module("vitest") @scope("vi") external useRealTimers: unit => unit = "useRealTimers"
  @module("vitest") @scope("vi") external advanceTimersByTime: int => unit = "advanceTimersByTime"
}

describe("SceneTransition Decoupling", () => {
  beforeEach(() => {
    Vi.useFakeTimers()
    ViewerState.resetState()

    // Setup minimal DOM mocks
    let _ = %raw(`
      (() => {
        globalThis.mockDomElements = {};
        globalThis.classLists = {};

        globalThis.document.getElementById = (id) => {
          if (!globalThis.mockDomElements[id]) {
             globalThis.mockDomElements[id] = {
               style: {},
               classList: {
                 add: (c) => {},
                 remove: (c) => {},
                 contains: (c) => false
               },
               textContent: ""
             };
          }
          return globalThis.mockDomElements[id];
        };

        globalThis.window.pannellumViewer = null;
        globalThis.Date.now = () => 1000;
        globalThis.mockDestroyCalled = 0;
      })()
    `)
  })

  afterEach(() => {
    Vi.useRealTimers()
  })

  test("performSwap completes task after 50ms but cleans up after 500ms", t => {
    let s1 = TestUtils.createMockScene(~id="s1", ~name="s1", ())
    let dispatch = _ => ()
    let getState = () => State.initialState
    let transition: Types.transition = {
      type_: Fade,
      targetHotspotIndex: -1,
      fromSceneName: None,
    }

    // Set a last scene so performSwap takes the swap path, not firstLoad path
    ViewerState.state := {
        ...ViewerState.state.contents,
        lastSceneId: Nullable.make("initial-scene"),
      }

    // Start a navigation task
    NavigationSupervisor.requestNavigation("s1")
    let currentTask = NavigationSupervisor.getCurrentTask()
    t->expect(NavigationSupervisor.isBusy())->Expect.toBe(true)
    let taskId = currentTask->Option.map(t => t.token.id)

    // Perform Swap
    Scene.Transition.performSwap(s1, 0.0, ~taskId?, ~getState, ~dispatch, ~transition)

    // Advance 50ms (finalizeSwap runs)
    Vi.advanceTimersByTime(50)

    // BEFORE FIX: Should fail here (still busy)
    // AFTER FIX: Should pass here (Idle)
    t->expect(NavigationSupervisor.isIdle())->Expect.toBe(true)

    // Check cleanup timing
    // At 50ms, cleanup (destroy) should NOT have happened yet
    let destroyCount50: int = %raw(`globalThis.mockDestroyCalled || 0`)
    t->expect(destroyCount50)->Expect.toBe(0)

    // Advance to 500ms (total from start)
    Vi.advanceTimersByTime(450)

    // Cleanup should have happened
    let destroyCount500: int = %raw(`globalThis.mockDestroyCalled || 0`)
    t->expect(destroyCount500 > 0)->Expect.toBe(true)
  })
})
