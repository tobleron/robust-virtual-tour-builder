open Vitest
open Types
// Mock Modules
%%raw(`
  import { vi } from "vitest";

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
      getActiveViewer: () => ({}), // Fallback facade
      getInactiveViewer: () => ({}), // Fallback facade
      isViewerReady: () => true,
      Adapter: { destroy: () => {} }
    }
  });

  vi.mock("../../src/systems/HotspotLine.bs.js", () => ({
      isViewerReady: () => true,
      updateLines: () => {}
  }));

  vi.mock("../../src/components/ViewerSnapshot.bs.js", () => ({
      requestIdleSnapshot: () => {}
  }));
`)

describe("Scene.Transition", () => {
  beforeEach(() => {
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

    Scene.Transition.performSwap(s1, 0.0, ~getState, ~dispatch, ~transition)

    let classLists: dict<array<string>> = %raw(`globalThis.classLists`)
    let c1Classes = Dict.get(classLists, "c1")->Belt.Option.getWithDefault([])
    let c2Classes = Dict.get(classLists, "c2")->Belt.Option.getWithDefault([])

    t->expect(Array.includes(c1Classes, "active"))->Expect.toBe(false)
    t->expect(Array.includes(c2Classes, "active"))->Expect.toBe(true)
  })
})
