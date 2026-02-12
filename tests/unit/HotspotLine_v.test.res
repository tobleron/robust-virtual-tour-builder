open Vitest
open HotspotLine

let mockViewer: ReBindings.Viewer.t = Obj.magic({
  "isLoaded": () => true,
  "getHfov": () => 90.0,
  "getYaw": () => 0.0,
  "getPitch": () => 0.0,
})

let mockViewerNotLoaded: ReBindings.Viewer.t = Obj.magic({
  "isLoaded": () => false,
})

describe("HotspotLine Facade", () => {
  beforeEach(() => {
    ViewerSystem.Pool.registerInstance("panorama-a", mockViewer)
    AppStateBridge.updateState(State.initialState)
  })

  test("getScreenCoords should proxy to Logic", t => {
    let rect: ReBindings.Dom.rect = {
      x: 0.0,
      y: 0.0,
      width: 1000.0,
      height: 500.0,
      top: 0.0,
      left: 0.0,
      right: 1000.0,
      bottom: 500.0,
    }
    let coords = getScreenCoords(mockViewer, 0.0, 0.0, rect)
    t->expect(coords->Belt.Option.isSome)->Expect.toBe(true)
  })
})
