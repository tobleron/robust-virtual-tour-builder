// @efficiency: infra-adapter
open Vitest

describe("SvgRenderer", () => {
  let setupContainer = () => {
    let container = ReBindings.Dom.createElement("div")
    ReBindings.Dom.setAttribute(container, "id", "viewer-hotspot-lines")
    ReBindings.Dom.appendChild(ReBindings.Dom.documentBody, container)
    container
  }

  let cleanupContainer = () => {
    let container = ReBindings.Dom.getElementById("viewer-hotspot-lines")
    switch Nullable.toOption(container) {
    | Some(el) => ReBindings.Dom.removeElement(el)
    | None => ()
    }
    // Deep clear the internal cache
    let _ = %raw(`
      (function(){
        const SvgManager = require('../../src/systems/SvgManager.bs.js');
        SvgManager.globalCache.elementMap = {}; 
        SvgManager.globalCache.lastContainer = undefined;
      })()
    `)
  }

  beforeEach(() => {
    let _ = setupContainer()
  })

  afterEach(() => {
    cleanupContainer()
  })

  test("updateLine sets attributes correctly", t => {
    SvgRenderer.updateLine("line1", 10.0, 20.0, 30.0, 40.0, "red", 2.0, 0.5, ())

    let el = Option.getOrThrow(SvgManager.getElement("line1"))
    t->expect(ReBindings.Dom.getAttribute(el, "x1"))->Expect.toBe("10")
    t->expect(ReBindings.Dom.getAttribute(el, "y1"))->Expect.toBe("20")
    t->expect(ReBindings.Dom.getAttribute(el, "stroke"))->Expect.toBe("red")
    t->expect(ReBindings.Dom.getAttribute(el, "stroke-width"))->Expect.toBe("2")
    t->expect(ReBindings.Dom.getAttribute(el, "stroke-opacity"))->Expect.toBe("0.5")
  })

  test("drawPolyLine builds 'd' string correctly", t => {
    let points = [{HotspotLineTypes.x: 0.0, y: 0.0}, {x: 100.0, y: 50.0}, {x: 200.0, y: 0.0}]
    SvgRenderer.drawPolyLine("poly1", points, "blue", 1.0, 1.0, ())

    let el = Option.getOrThrow(SvgManager.getElement("poly1"))
    let d = ReBindings.Dom.getAttribute(el, "d")
    // Note: math rounding in SvgRenderer: Math.round(coords.x * 10.0) / 10.0
    t->expect(d)->Expect.toBe("M 0 0 L 100 50 L 200 0")
    t->expect(ReBindings.Dom.getAttribute(el, "stroke"))->Expect.toBe("blue")
  })

  test("drawArrow sets transform correctly", t => {
    SvgRenderer.drawArrow("arrow1", 100.0, 200.0, 45.0, "green", 1.0)

    let el = Option.getOrThrow(SvgManager.getElement("arrow1"))
    t
    ->expect(ReBindings.Dom.getAttribute(el, "transform"))
    ->Expect.toBe("translate(100, 200) rotate(45)")
    t->expect(ReBindings.Dom.getAttribute(el, "fill"))->Expect.toBe("green")
  })

  test("hide calls manager hide", t => {
    SvgRenderer.updateLine("hider", 0.0, 0.0, 0.0, 0.0, "black", 1.0, 1.0, ())
    SvgRenderer.hide("hider")

    let el = Option.getOrThrow(SvgManager.getElement("hider"))
    let display = %raw(`(el) => el.style.display`)(el)
    t->expect(display)->Expect.toBe("none")
  })

  test("updateLine sets optional attributes correctly", t => {
    SvgRenderer.updateLine(
      "line_opt",
      10.0,
      10.0,
      50.0,
      50.0,
      "red",
      2.0,
      1.0,
      ~dashArray="5,5",
      ~className="custom-line",
      (),
    )

    let el = Option.getOrThrow(SvgManager.getElement("line_opt"))
    t->expect(ReBindings.Dom.getAttribute(el, "stroke-dasharray"))->Expect.toBe("5,5")
    t->expect(ReBindings.Dom.getAttribute(el, "class"))->Expect.toBe("custom-line")
  })

  test("drawPolyLine handles optional attributes", t => {
    let points = [{HotspotLineTypes.x: 0.0, y: 0.0}, {x: 100.0, y: 50.0}]
    SvgRenderer.drawPolyLine(
      "poly_opt",
      points,
      "blue",
      1.0,
      1.0,
      ~dashArray="2,2",
      ~className="custom-poly",
      (),
    )

    let el = Option.getOrThrow(SvgManager.getElement("poly_opt"))
    t->expect(ReBindings.Dom.getAttribute(el, "stroke-dasharray"))->Expect.toBe("2,2")
    t->expect(ReBindings.Dom.getAttribute(el, "class"))->Expect.toBe("custom-poly")
  })

  test("drawPolyLine hides element if less than 2 points", t => {
    let points = [{HotspotLineTypes.x: 0.0, y: 0.0}]
    // Create a visible one first
    let points2 = [{HotspotLineTypes.x: 0.0, y: 0.0}, {x: 10.0, y: 10.0}]
    SvgRenderer.drawPolyLine("poly_short", points2, "red", 1.0, 1.0, ())
    let el = Option.getOrThrow(SvgManager.getElement("poly_short"))
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("block")

    // Now update with 1 point
    SvgRenderer.drawPolyLine("poly_short", points, "red", 1.0, 1.0, ())
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("none")
  })

  test("drawArrow hides element if coordinates are infinite", t => {
    // Create visible first
    SvgRenderer.drawArrow("arrow_inf", 100.0, 100.0, 0.0, "red", 1.0)
    let el = Option.getOrThrow(SvgManager.getElement("arrow_inf"))
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("block")

    // Update with infinite x
    let inf = 1.0 /. 0.0
    SvgRenderer.drawArrow("arrow_inf", inf, 100.0, 0.0, "red", 1.0)
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("none")
  })
})
