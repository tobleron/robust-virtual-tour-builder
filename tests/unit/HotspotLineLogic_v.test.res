open Vitest
open Types

describe("HotspotLineLogic", () => {
  describe("isViewerValid", () => {
    test(
      "should return true for a valid viewer",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        t->expect(ViewerSystem.isViewerValid(mockViewer))->Expect.toBe(true)
      },
    )
  })

  describe("isViewerReady", () => {
    test(
      "should return true if valid and active and hfov > 1.0",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerSystem.Pool.registerInstance("panorama-a", mockViewer)
        t->expect(ViewerSystem.isViewerReady(mockViewer))->Expect.toBe(true)
      },
    )
  })

  describe("getScreenCoords", () => {
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

    test(
      "should return center coords for center point",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerSystem.Pool.registerInstance("panorama-a", mockViewer)

        let cam = HotspotLine.Logic.getCamState(mockViewer, rect)
        let coords = ProjectionMath.getScreenCoords(cam, 0.0, 0.0, rect)
        switch coords {
        | Some(c) =>
          t->expect(c.x)->Expect.toBe(500.0)
          t->expect(c.y)->Expect.toBe(250.0)
        | None => t->expect(false)->Expect.toBe(true)
        }
      },
    )
  })

  describe("SVG Drawing", () => {
    test(
      "updateLine should create/update a line element",
      t => {
        // Mock DOM
        let _ = %raw(`document.body.innerHTML = '<svg id="viewer-hotspot-lines"></svg>'`)

        SvgManager.Renderer.updateLine("test-line", 0.0, 0.0, 100.0, 100.0, "red", 2.0, 1.0, ())

        let line = %raw(`document.getElementById("test-line")`)
        t->expect(line !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`line.getAttribute("stroke")`))->Expect.toBe("red")
      },
    )
  })
})
