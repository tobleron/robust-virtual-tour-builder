// @efficiency: infra-adapter
open Vitest
open PannellumAdapter

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"
@send external toHaveBeenCalledWith2: (expectation, 'a, 'b) => unit = "toHaveBeenCalledWith"
@send external toHaveBeenCalledWith4: (expectation, 'a, 'b, 'c, 'd) => unit = "toHaveBeenCalledWith"
@send
external toHaveBeenCalledWith5: (expectation, 'a, 'b, 'c, 'd, 'e) => unit = "toHaveBeenCalledWith"

type mockFn
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

describe("PannellumAdapter", () => {
  let mockViewer = Obj.magic({
    "getPitch": %raw(`vi.fn().mockReturnValue(10.0)`),
    "getYaw": %raw(`vi.fn().mockReturnValue(20.0)`),
    "getHfov": %raw(`vi.fn().mockReturnValue(90.0)`),
    "setPitch": %raw(`vi.fn()`),
    "setYaw": %raw(`vi.fn()`),
    "setHfov": %raw(`vi.fn()`),
    "addHotSpot": %raw(`vi.fn()`),
    "removeHotSpot": %raw(`vi.fn()`),
    "getScene": %raw(`vi.fn().mockReturnValue("scene-1")`),
    "loadScene": %raw(`vi.fn()`),
    "destroy": %raw(`vi.fn()`),
    "on": %raw(`vi.fn()`),
    "_sceneId": "initial-id",
    "_isLoaded": false,
  })

  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)

    // Mock global pannellum object
    let _ = %raw(`
      globalThis.pannellum = {
        viewer: vi.fn(() => mockViewer)
      }
    `)
  })

  test("initialize should call Pannellum.viewer", _t => {
    let config = {"autoLoad": true}
    let _ = initialize("container-id", config)

    let viewerFn = %raw(`globalThis.pannellum.viewer`)
    expectCall(viewerFn)->toHaveBeenCalledWith2("container-id", config)
  })

  test("getters should proxy to viewer instance", t => {
    t->expect(getPitch(mockViewer))->Expect.toBe(10.0)
    t->expect(getYaw(mockViewer))->Expect.toBe(20.0)
    t->expect(getHfov(mockViewer))->Expect.toBe(90.0)

    t->expect(getScene(mockViewer))->Expect.toBe("scene-1")
  })

  test("setters should proxy to viewer instance", _t => {
    setPitch(mockViewer, 5.0, true)
    expectCall(mockViewer["setPitch"])->toHaveBeenCalledWith2(5.0, true)

    setYaw(mockViewer, 15.0, false)
    expectCall(mockViewer["setYaw"])->toHaveBeenCalledWith2(15.0, false)

    setHfov(mockViewer, 100.0, true)
    expectCall(mockViewer["setHfov"])->toHaveBeenCalledWith2(100.0, true)
  })

  test("loadScene should use defaults if optional args are missing", _t => {
    loadScene(mockViewer, "new-scene", ())

    // Default pitch/yaw/hfov from getters: 10.0, 20.0, 90.0
    expectCall(mockViewer["loadScene"])->toHaveBeenCalledWith4("new-scene", 10.0, 20.0, 90.0)
  })

  test("loadScene should use provided args", _t => {
    loadScene(mockViewer, "new-scene", ~pitch=30.0, ~yaw=40.0, ~hfov=110.0, ())

    expectCall(mockViewer["loadScene"])->toHaveBeenCalledWith4("new-scene", 30.0, 40.0, 110.0)
  })

  test("setMetaData and getMetaData should handle custom properties", t => {
    setMetaData(mockViewer, "sceneId", "custom-scene")
    t->expect(getMetaData(mockViewer, "sceneId"))->Expect.toBe(Some(Obj.magic("custom-scene")))

    setMetaData(mockViewer, "isLoaded", true)
    t->expect(getMetaData(mockViewer, "isLoaded"))->Expect.toBe(Some(Obj.magic(true)))

    t->expect(getMetaData(mockViewer, "unknown"))->Expect.toBe(None)
  })

  test("destroy should handle errors gracefully", t => {
    mockViewer["destroy"] = %raw(`vi.fn(() => { throw new Error("fail") })`)

    // Should not throw
    destroy(mockViewer)

    expectCall(mockViewer["destroy"])->toHaveBeenCalled()
    t->expect(true)->Expect.toBe(true)
  })
})
