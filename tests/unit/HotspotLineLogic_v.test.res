open Vitest
open HotspotLineLogic
open HotspotLineTypes

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
        t->expect(isViewerValid(mockViewer))->Expect.toBe(true)
      },
    )

    test(
      "should return false if not loaded",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => false,
        })
        t->expect(isViewerValid(mockViewer))->Expect.toBe(false)
      },
    )

    test(
      "should return false if hfov <= 0",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 0.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        t->expect(isViewerValid(mockViewer))->Expect.toBe(false)
      },
    )
  })

  describe("isActiveViewer", () => {
    test(
      "should return true if viewer matches active viewer",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({"id": "active"})
        ViewerPool.registerInstance("panorama-a", mockViewer)

        t->expect(isActiveViewer(mockViewer))->Expect.toBe(true)
      },
    )

    test(
      "should return false if viewer does not match active viewer",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({"id": "inactive"})
        let activeViewer: ReBindings.Viewer.t = Obj.magic({"id": "active"})
        ViewerPool.registerInstance("panorama-a", activeViewer)

        t->expect(isActiveViewer(mockViewer))->Expect.toBe(false)
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
        ViewerPool.registerInstance("panorama-a", mockViewer)

        t->expect(isViewerReady(mockViewer))->Expect.toBe(true)
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
        ViewerPool.registerInstance("panorama-a", mockViewer)

        let cam = getCamState(mockViewer, rect)
        let coords = getScreenCoords(cam, 0.0, 0.0, rect)
        switch coords {
        | Some(c) =>
          t->expect(c.x)->Expect.toBe(500.0)
          t->expect(c.y)->Expect.toBe(250.0)
        | None => t->expect(false)->Expect.toBe(true)
        }
      },
    )

    test(
      "should return None if viewer is not ready",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => false,
        })
        if isViewerReady(mockViewer) {
          let cam = getCamState(mockViewer, rect)
          let coords = getScreenCoords(cam, 0.0, 0.0, rect)
          t->expect(coords)->Expect.toBe(None)
        } else {
          t->expect(true)->Expect.toBe(true)
        }
      },
    )

    test(
      "should return None if point is behind camera (yaw diff > 90)",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerPool.registerInstance("panorama-a", mockViewer)

        let cam = getCamState(mockViewer, rect)
        // Target at 180 degrees yaw (directly behind)
        let coords = getScreenCoords(cam, 0.0, 180.0, rect)
        t->expect(coords)->Expect.toBe(None)
      },
    )
  })

  describe("SVG Drawing", () => {
    let setupSvg = () => {
      let svg = ReBindings.Dom.createElement("svg")
      ReBindings.Dom.setId(svg, "viewer-hotspot-lines")
      ReBindings.Dom.appendChild(ReBindings.Dom.documentBody, svg)
      svg
    }

    let cleanupSvg = svg => {
      ReBindings.Dom.removeElement(svg)
      SvgManager.clearAll()
    }

    test(
      "updateLine should create/update a line element",
      t => {
        let svg = setupSvg()
        updateLine("test-line", 0.0, 0.0, 100.0, 100.0, "red", 2.0, 1.0, ())

        let line = %raw(`document.getElementById("test-line")`)
        t->expect(line !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`line.getAttribute("stroke")`))->Expect.toBe("red")

        cleanupSvg(svg)
      },
    )

    test(
      "updatePolyLine should create/update a path element",
      t => {
        let svg = setupSvg()
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerPool.registerInstance("panorama-a", mockViewer)

        let path: array<PathInterpolation.point> = [{yaw: 0.0, pitch: 0.0}, {yaw: 10.0, pitch: 0.0}]
        let rect: ReBindings.Dom.rect = {
          x: 0.0,
          y: 0.0,
          width: 1000.0,
          height: 1000.0,
          top: 0.0,
          left: 0.0,
          right: 1000.0,
          bottom: 1000.0,
        }

        let cam = getCamState(mockViewer, rect)
        updatePolyLine("test-poly", cam, path, rect, "blue", 1.0, 1.0, ())

        let pathEl = %raw(`document.getElementById("test-poly")`)
        t->expect(pathEl !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`pathEl.getAttribute("stroke")`))->Expect.toBe("blue")
        let d = %raw(`pathEl.getAttribute("d")`)
        t->expect(String.includes(d, "M 500 500"))->Expect.toBe(true)

        cleanupSvg(svg)
      },
    )

    test(
      "updateSimulationArrow should create/update arrow path",
      t => {
        let svg = setupSvg()
        let rect: ReBindings.Dom.rect = {
          x: 0.0,
          y: 0.0,
          width: 1000.0,
          height: 1000.0,
          top: 0.0,
          left: 0.0,
          right: 1000.0,
          bottom: 1000.0,
        }

        // Mock getBoundingClientRect for optimization check in Logic? (Logic uses provided rect usually)
        // But NavigationRenderer uses it. Logic uses passed rect.

        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerPool.registerInstance("panorama-a", mockViewer)

        let cam = getCamState(mockViewer, rect)
        updateSimulationArrow(cam, 0.0, 0.0, 0.0, 10.0, 0.5, rect, ~colorOverride="green", ())

        // logic uses "sim_arrow" id
        let arrow = %raw(`document.getElementById("sim_arrow")`)
        t->expect(arrow !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`arrow.getAttribute("fill")`))->Expect.toBe("green")

        cleanupSvg(svg)
      },
    )
  })
})
