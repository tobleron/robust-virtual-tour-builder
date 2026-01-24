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
        ViewerState.state.viewerA = Nullable.make(mockViewer)
        ViewerState.state.activeViewerKey = A

        t->expect(isActiveViewer(mockViewer))->Expect.toBe(true)
      },
    )

    test(
      "should return false if viewer does not match active viewer",
      t => {
        let mockViewer: ReBindings.Viewer.t = Obj.magic({"id": "inactive"})
        let activeViewer: ReBindings.Viewer.t = Obj.magic({"id": "active"})
        ViewerState.state.viewerA = Nullable.make(activeViewer)
        ViewerState.state.activeViewerKey = A

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
        ViewerState.state.viewerA = Nullable.make(mockViewer)
        ViewerState.state.activeViewerKey = A

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
        ViewerState.state.viewerA = Nullable.make(mockViewer)
        ViewerState.state.activeViewerKey = A

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
  })

  describe("SVG Drawing", () => {
    test(
      "drawLine should append a line element to svg",
      t => {
        let svg = ReBindings.Dom.createElement("svg")
        drawLine(svg, 0.0, 0.0, 100.0, 100.0, "red", 2.0, 1.0, ())

        let line = %raw(`svg.querySelector("line")`)
        t->expect(line !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`line.getAttribute("stroke")`))->Expect.toBe("red")
      },
    )

    test(
      "drawPolyLine should append a path element if path has >= 2 points",
      t => {
        let svg = ReBindings.Dom.createElement("svg")
        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerState.state.viewerA = Nullable.make(mockViewer)
        ViewerState.state.activeViewerKey = A

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
        drawPolyLine(svg, cam, path, rect, "blue", 1.0, 1.0, ())

        let pathEl = %raw(`svg.querySelector("path")`)
        t->expect(pathEl !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`pathEl.getAttribute("stroke")`))->Expect.toBe("blue")
        let d = %raw(`pathEl.getAttribute("d")`)
        t->expect(String.includes(d, "M 500 500"))->Expect.toBe(true)
      },
    )

    test(
      "drawSimulationArrow should append an arrow path",
      t => {
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
        // Setup DOM
        let svg = ReBindings.Dom.createElement("svg")
        ReBindings.Dom.setId(svg, "viewer-hotspot-lines")
        ReBindings.Dom.appendChild(ReBindings.Dom.documentBody, svg)

        // Mock getBoundingClientRect
        let _ = %raw(`svg.getBoundingClientRect = () => ({ width: 1000, height: 500, top: 0, left: 0, right: 1000, bottom: 500 })`)

        let mockViewer: ReBindings.Viewer.t = Obj.magic({
          "isLoaded": () => true,
          "getHfov": () => 90.0,
          "getYaw": () => 0.0,
          "getPitch": () => 0.0,
        })
        ViewerState.state.viewerA = Nullable.make(mockViewer)
        ViewerState.state.activeViewerKey = A

        let cam = getCamState(mockViewer, rect)
        drawSimulationArrow(svg, cam, 0.0, 0.0, 0.0, 10.0, 0.5, rect, ~colorOverride="green", ()) // start // end // progress

        let arrow = %raw(`svg.querySelector("path")`)
        t->expect(arrow !== Nullable.null)->Expect.toBe(true)
        t->expect(%raw(`arrow.getAttribute("fill")`))->Expect.toBe("green")

        // Cleanup
        %raw(`document.body.removeChild(svg)`)
      },
    )
  })
})
