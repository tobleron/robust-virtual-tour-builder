/* tests/unit/ViewerLoader_v.test.res */
open Vitest
open ViewerLoader
open Types

let _ = describe("ViewerLoader", () => {
  let mockDestroy = %raw("vi.fn()")
  let mockViewerCtor = %raw("vi.fn()")

  let setGlobal: ('a, string) => unit = %raw("(v, n) => globalThis[n] = v")
  setGlobal(mockDestroy, "mockDestroy")
  setGlobal(mockViewerCtor, "mockViewerCtor")

  beforeAll(() => {
    let _ = %raw(`(function(){
      globalThis.pannellum = {
        viewer: (id, config) => {
            globalThis.mockViewerCtor(id, config);
            return {
              _id: id,
              destroy: () => globalThis.mockDestroy(),
              on: (e, cb) => {},
              getScene: () => "master",
              getPitch: () => 0.0,
              getYaw: () => 0.0,
              getHfov: () => 90.0
            }
        }
      };

      globalThis.window.getComputedStyle = () => ({
        getPropertyValue: (p) => "1.0"
      });

      // Mock DOM methods used in ViewerLoader
      globalThis.document.querySelectorAll = () => [];
      globalThis.document.getElementById = (id) => {
          if (id === "missing") return null;
          return {
             id: id,
             style: {},
             classList: {
                add: () => {},
                remove: () => {},
                contains: () => false
             },
             setAttribute: () => {},
             addEventListener: (_, _1) => {},
             getBoundingClientRect: () => ({top: 0, left: 0}),
             appendChild: () => {}
          }
      };
    })()`)
  })

  beforeEach(() => {
    let _ = %raw("vi.clearAllMocks()")
    AppStateBridge.updateState(State.initialState)
  })

  test("getPanoramaUrl handles URL object", t => {
    let url = getPanoramaUrl(Url("test.jpg"))
    t->expect(url)->Expect.toBe("test.jpg")
  })

  test("ViewerSystem.Adapter.initialize calls Pannellum", t => {
    let _ = ViewerSystem.Adapter.initialize("test-container", %raw("{}"))
    let calls = %raw("mockViewerCtor.mock.calls")
    t->expect(Array.length(calls) > 0)->Expect.toBe(true)
  })

  test("ViewerSystem.Adapter.destroy calls destroy", t => {
    let v = ViewerSystem.Adapter.initialize("test-container", %raw("{}"))
    ViewerSystem.Adapter.destroy(v)
    let calls = %raw("mockDestroy.mock.calls")
    t->expect(Array.length(calls) > 0)->Expect.toBe(true)
  })

  test("getComputedOpacity returns 1.0 from mock", t => {
    let el = %raw(`globalThis.document.getElementById("t")`)
    let op = getComputedOpacity(el)
    t->expect(op)->Expect.toBe(1.0)
  })
})
