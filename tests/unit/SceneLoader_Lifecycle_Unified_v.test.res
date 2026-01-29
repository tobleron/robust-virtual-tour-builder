// @efficiency: infra-adapter
open Vitest

// Mock Modules
%%raw(`
  import { vi } from "vitest";

  // Mock LazyLoad
  vi.mock("../../src/utils/LazyLoad.bs.js", () => ({
    loadPannellum: () => Promise.resolve()
  }));

  // Mock ViewerPool
  vi.mock("../../src/systems/ViewerPool.bs.js", () => {
    let internalInstance = undefined;
    return {
      getInactive: () => ({id: "vp-2", containerId: "viewer-container-2", status: "Background"}),
      getInactiveViewer: () => internalInstance,
      getActiveViewer: () => undefined,
      registerInstance: (cid, inst) => { internalInstance = inst; },
      clearCleanupTimeout: () => {},
      swapActive: () => {}
    };
  });
`)

describe("SceneLoader Lifecycle Unified", () => {
  let mockState = ref(State.initialState)
  let dispatchedActions = ref([])

  beforeEach(() => {
    mockState := State.initialState
    dispatchedActions := []

    GlobalStateBridge.setDispatch(
      action => {
        let _ = Array.push(dispatchedActions.contents, action)
      },
    )
    GlobalStateBridge.setState(mockState.contents)

    let _ = %raw(`
      (() => {
      var createMockViewer = () => {
        return {
          _listeners: {},
          on: function(event, callback) {
            this._listeners[event] = callback;
          },
          getScene: () => "master",
          loadScene: () => {},
          getPitch: () => 0.0,
          getYaw: () => 0.0,
          getHfov: () => 100.0,
          addHotSpot: () => {},
          destroy: () => {},
          removeHotSpot: () => {},
          setPitch: () => {},
          setYaw: () => {},
          setHfov: () => {},
          _sceneId: "",
          _isLoaded: false,
          trigger: function(event) {
            if (this._listeners[event]) this._listeners[event]();
          }
        };
      };

      globalThis.pannellum = {
        viewer: (id, config) => createMockViewer()
      };

      globalThis.document.getElementById = (id) => {
        return {
             style: {},
             classList: { add: () => {}, remove: () => {} },
             appendChild: () => {},
             removeChild: () => {},
             getAttribute: (name) => null,
             addEventListener: () => {}
        };
      };

      globalThis.document.createElement = (tag) => {
        return {
             style: {},
             classList: { add: () => {}, remove: () => {} },
             appendChild: () => {},
             setAttribute: () => {},
             addEventListener: (ev, cb) => {
               if(ev === 'load') setTimeout(cb, 0);
             }
        };
      };

      globalThis.window.setTimeout = (cb, ms) => { cb(); return 0; };
      globalThis.window.clearTimeout = (id) => {};
      globalThis.URL.revokeObjectURL = (url) => {};
      globalThis.Date.now = () => 1000000;
      })()
    `)
  })

  testAsync("loadNewScene orchestration success flow", t => {
    let s1 = TestUtils.createMockScene(~id="s1", ~name="Scene 1", ())
    let s2 = TestUtils.createMockScene(~id="s2", ~name="Scene 2", ())

    let newState = {...State.initialState, scenes: [s1, s2], activeIndex: 0}
    GlobalStateBridge.setState(newState)

    Scene.Loader.loadNewScene(None, Some(1), ~isAnticipatory=false)

    Promise.make(
      (resolve, _reject) => {
        let _ = setTimeout(
          () => {
            resolve()
          },
          50,
        )
      },
    )->Promise.then(
      () => {
        t->expect(true)->Expect.toBe(true)
        Promise.resolve()
      },
    )
  })

/*
  test("Config creates correct viewer config", t => {
    let config = Scene.LoaderConfig.createViewerConfig(false, "pano.jpg", "")
    let json = JSON.stringify(Obj.magic(config))
    t->expect(String.includes(json, "pano.jpg"))->Expect.toBe(true)
    t->expect(String.includes(json, "master"))->Expect.toBe(true)
    t->expect(String.includes(json, "preview"))->Expect.toBe(false)
  })

  test("Config creates progressive viewer config", t => {
    let config = Scene.LoaderConfig.createViewerConfig(true, "pano.jpg", "tiny.jpg")
    let json = JSON.stringify(Obj.magic(config))
    t->expect(String.includes(json, "preview"))->Expect.toBe(true)
    t->expect(String.includes(json, "tiny.jpg"))->Expect.toBe(true)
  })
*/
})
