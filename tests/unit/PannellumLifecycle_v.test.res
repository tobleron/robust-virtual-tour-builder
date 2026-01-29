open Vitest
open ViewerSystem.Adapter

describe("PannellumLifecycle", () => {
  test("initializeViewer should call Pannellum.viewer", t => {
    let mockViewer = Obj.magic({"_": 1})
    let _ = %raw(`
      window.pannellum = {
        viewer: () => mockViewer
      }
    `)
    let v = initializeViewer("id", Obj.magic({"_": 0}))
    t->expect(v)->Expect.toBe(mockViewer)
  })

  test("destroyViewer should call destroy on instance", t => {
    let destroyCalled = ref(false)
    let mockViewer = Obj.magic({
      "destroy": () => {
        destroyCalled := true
      },
    })

    ViewerSystem.destroyViewer(mockViewer)
    t->expect(destroyCalled.contents)->Expect.toBe(true)
  })
})
