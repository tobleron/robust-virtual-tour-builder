open Vitest
open ViewerSystem.Pool

describe("ViewerPool", () => {
  beforeEach(() => {
    pool := [
        {
          id: "primary-a",
          containerId: "panorama-a",
          instance: None,
          status: #Active,
          cleanupTimeout: None,
        },
        {
          id: "primary-b",
          containerId: "panorama-b",
          instance: None,
          status: #Background,
          cleanupTimeout: None,
        },
      ]
  })

  test("getViewportByContainer should return correct viewport", t => {
    let v = getViewportByContainer("panorama-b")
    t->expect(v->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(v->Belt.Option.map(x => x.id))->Expect.toBe(Some("primary-b"))
  })

  test("getActive should return the active viewport", t => {
    let v = getActive()
    t->expect(v->Belt.Option.map(x => x.containerId))->Expect.toBe(Some("panorama-a"))
  })

  test("swapActive should toggle statuses", t => {
    swapActive()
    t->expect(getActive()->Belt.Option.map(x => x.containerId))->Expect.toBe(Some("panorama-b"))
  })

  test("registerInstance should store the viewer instance", t => {
    let mockInstance: ViewerSystem.PannellumAdapter.t = Obj.magic({"id": "mock"})
    registerInstance("panorama-a", mockInstance)

    let v = getActiveViewer()
    t->expect(v)->Expect.toBe(Some(mockInstance))
  })
})
