open Vitest
open ViewerPool

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"

describe("ViewerPool", () => {
  beforeEach(() => {
    // Reset pool state manually since we can't re-initialize the module
    // The pool is hardcoded with 2 items in ViewerPool.res
    pool->Belt.Array.forEach(v => {
      v.instance = None
      v.cleanupTimeout = None
      if v.id == "primary-a" {
        v.status = #Active
      } else {
        v.status = #Background
      }
    })
  })

  test("getViewport should return correct viewport by id", t => {
    let v = getViewport("primary-a")
    t->expect(v->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(v->Belt.Option.map(x => x.containerId))->Expect.toBe(Some("panorama-a"))
  })

  test("getViewportByContainer should return correct viewport", t => {
    let v = getViewportByContainer("panorama-b")
    t->expect(v->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(v->Belt.Option.map(x => x.id))->Expect.toBe(Some("primary-b"))
  })

  test("getActive should return the active viewport", t => {
    let v = getActive()
    t->expect(v->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(v->Belt.Option.map(x => x.id))->Expect.toBe(Some("primary-a"))
  })

  test("getInactive should return the background viewport", t => {
    let v = getInactive()
    t->expect(v->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(v->Belt.Option.map(x => x.id))->Expect.toBe(Some("primary-b"))
  })

  test("swapActive should toggle statuses", t => {
    swapActive()

    let active = getActive()
    let inactive = getInactive()

    t->expect(active->Belt.Option.map(x => x.id))->Expect.toBe(Some("primary-b"))
    t->expect(inactive->Belt.Option.map(x => x.id))->Expect.toBe(Some("primary-a"))
  })

  test("registerInstance should store the viewer instance", t => {
    let mockInstance: PannellumAdapter.t = Obj.magic({"id": "mock"})
    registerInstance("panorama-a", mockInstance)

    let v = getViewport("primary-a")
    t->expect(v->Belt.Option.flatMap(x => x.instance))->Expect.toBe(Some(mockInstance))
  })

  test("clearInstance should remove the viewer instance", t => {
    let mockInstance: PannellumAdapter.t = Obj.magic({"id": "mock"})
    registerInstance("panorama-a", mockInstance)
    clearInstance("panorama-a")

    let v = getViewport("primary-a")
    t->expect(v->Belt.Option.flatMap(x => x.instance))->Expect.toBe(None)
  })

  test("getActiveViewer should return instance of active viewport", t => {
    let mockInstance: PannellumAdapter.t = Obj.magic({"id": "mock-active"})
    registerInstance("panorama-a", mockInstance) // default active

    let instance = getActiveViewer()
    t->expect(instance)->Expect.toBe(Some(mockInstance))
  })

  test("getInactiveViewer should return instance of background viewport", t => {
    let mockInstance: PannellumAdapter.t = Obj.magic({"id": "mock-bg"})
    registerInstance("panorama-b", mockInstance) // default background

    let instance = getInactiveViewer()
    t->expect(instance)->Expect.toBe(Some(mockInstance))
  })

  test("cleanupTimeout handling", t => {
    let mockClearTimeout = %raw(`vi.spyOn(window, 'clearTimeout')`)

    // Set a timeout
    setCleanupTimeout("primary-a", Some(123))

    let v = getViewport("primary-a")
    t->expect(v->Belt.Option.flatMap(x => x.cleanupTimeout))->Expect.toBe(Some(123))

    // Set another timeout - should clear previous
    setCleanupTimeout("primary-a", Some(456))
    expectCall(mockClearTimeout)->toHaveBeenCalledWith(123)
    t->expect(v->Belt.Option.flatMap(x => x.cleanupTimeout))->Expect.toBe(Some(456))

    // Clear timeout explicitly
    clearCleanupTimeout("primary-a")
    expectCall(mockClearTimeout)->toHaveBeenCalledWith(456)
    t->expect(v->Belt.Option.flatMap(x => x.cleanupTimeout))->Expect.toBe(None)
  })
})
