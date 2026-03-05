open Vitest
open Types
// Mock Modules
%%raw(`
  import { vi } from "vitest";

  const __activeViewer = {
    getScene: () => "s1",
    getYaw: () => 12.0,
    getPitch: () => -4.0,
    getHfov: () => 100.0,
  };

  const __inactiveViewer = {
    getScene: () => "s1",
    getYaw: () => 12.0,
    getPitch: () => -4.0,
    getHfov: () => 100.0,
  };

  vi.mock("../../src/systems/ViewerSystem.bs.js", () => {
    return {
      Pool: {
        getActive: () => ({id: "v1", containerId: "c1", status: "Active"}),
        getInactive: () => ({id: "v2", containerId: "c2", status: "Background"}),
        getActiveViewer: () => __activeViewer,
        getInactiveViewer: () => __inactiveViewer,
        swapActive: () => {},
        clearCleanupTimeout: () => {},
        clearInstance: () => {},
        setCleanupTimeout: () => {}
      },
      getActiveViewer: () => __activeViewer, // Fallback facade
      getInactiveViewer: () => __inactiveViewer, // Fallback facade
      isViewerReady: () => true,
      isViewerReadyForScene: (v, id) => v === __inactiveViewer,
      getActiveViewerReadyForScene: () => __activeViewer,
      Adapter: {
        destroy: () => {},
        getMetaData: (_viewer, key) => key === "sceneId" ? "initial-scene" : undefined,
      }
    }
  });

  vi.mock("../../src/systems/HotspotLine.bs.js", () => ({
      isViewerReady: () => true,
      updateLines: () => {},
      clearLines: () => {},
  }));

  vi.mock("../../src/components/ViewerSnapshot.bs.js", () => ({
      requestIdleSnapshot: () => {}
  }));
`)

describe("Scene.Transition", () => {
  beforeEach(() => {
    ViewerState.resetState()
    let _ = %raw(`
      (() => {
        globalThis.mockDomElements = {};
        globalThis.classLists = {};

        globalThis.document.getElementById = (id) => {
          if (!globalThis.mockDomElements[id]) {
             globalThis.mockDomElements[id] = {
               style: {},
               classList: {
                 add: (c) => {
                   if(!globalThis.classLists[id]) globalThis.classLists[id] = [];
                   if(!globalThis.classLists[id].includes(c)) globalThis.classLists[id].push(c);
                 },
                 remove: (c) => {
                   if(globalThis.classLists[id]) {
                     const idx = globalThis.classLists[id].indexOf(c);
                     if(idx > -1) globalThis.classLists[id].splice(idx, 1);
                   }
                 },
                 contains: (c) => globalThis.classLists[id] ? globalThis.classLists[id].includes(c) : false
               },
               textContent: ""
             };
          }
          return globalThis.mockDomElements[id];
        };

        globalThis.window.setTimeout = (cb, ms) => { cb(); return 0; };
        globalThis.window.pannellumViewer = null;
        globalThis.Date.now = () => 1000;
      })()
    `)
  })

  test("performSwap swaps active class", t => {
    let s1 = TestUtils.createMockScene(~id="s1", ~name="s1", ())
    let dispatch = _ => ()
    let getState = () => State.initialState
    let transition = {
      type_: Fade,
      targetHotspotIndex: -1,
      fromSceneName: None,
    }

    ViewerState.state := {
        ...ViewerState.state.contents,
        lastSceneId: Nullable.make("initial-scene"),
      }
    Scene.Transition.performSwap(s1, 0.0, ~getState, ~dispatch, ~transition)

    let classLists: dict<array<string>> = %raw(`globalThis.classLists`)
    let c1Classes = Dict.get(classLists, "c1")->Belt.Option.getWithDefault([])
    let c2Classes = Dict.get(classLists, "c2")->Belt.Option.getWithDefault([])

    t->expect(Array.includes(c1Classes, "active"))->Expect.toBe(false)
    t->expect(Array.includes(c2Classes, "active"))->Expect.toBe(true)
  })
})
