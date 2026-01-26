open Vitest
open PannellumLifecycle

describe("PannellumLifecycle", () => {
  test("initializeViewer calls Pannellum.viewer", t => {
    let mockViewer = Obj.magic({"id": "mock"})
    let _ = %raw(`
      globalThis.pannellum = {
        viewer: vi.fn(() => mockViewer)
      }
    `)
    let v = initializeViewer("id", Obj.magic({"_": 0}))
    t->expect(v)->Expect.toBe(mockViewer)
  })

  test("destroyViewer calls Viewer.destroy", t => {
    let destroyCalled = ref(false)
    let mockViewer = Obj.magic({"destroy": () => {destroyCalled := true}})

    destroyViewer(mockViewer)
    t->expect(destroyCalled.contents)->Expect.toBe(true)
  })
})
