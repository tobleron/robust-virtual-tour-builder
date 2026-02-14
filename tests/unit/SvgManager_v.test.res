/* tests/unit/SvgManager_v.test.res */
open Vitest

describe("SvgManager", () => {
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
    // Deep clear the internal cache to avoid cross-test pollution
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

  test("getOrCreate creates element and appends to container", t => {
    let elOption = SvgManager.getOrCreate("test-id", "line")
    t->expect(Option.isSome(elOption))->Expect.toBe(true)

    let el = Option.getOrThrow(elOption)
    t
    ->expect(ReBindings.Dom.getAttribute(el, "id")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("test-id")

    let container = ReBindings.Dom.getElementById("viewer-hotspot-lines")
    let found = ReBindings.Dom.querySelector(Nullable.getOrThrow(container), "#test-id")
    t->expect(Nullable.toOption(found))->Expect.toBeSome
  })

  test("getOrCreate returns cached element", t => {
    let el1 = SvgManager.getOrCreate("cache-id", "path")
    let el2 = SvgManager.getOrCreate("cache-id", "path")

    t->expect(el1)->Expect.toEqual(el2)
  })

  test("syncContainer handles container replacement", t => {
    let _ = SvgManager.getOrCreate("id1", "line")

    // Replace container
    cleanupContainer()
    let _ = setupContainer()

    // Should still be able to create new element in new container
    let el = SvgManager.getOrCreate("id1", "line")
    t->expect(Option.isSome(el))->Expect.toBe(true)

    let container = ReBindings.Dom.getElementById("viewer-hotspot-lines")
    let found = ReBindings.Dom.querySelector(Nullable.getOrThrow(container), "#id1")
    t->expect(Nullable.toOption(found))->Expect.toBeSome
  })

  test("clearAll empties container", t => {
    let _ = SvgManager.getOrCreate("id1", "line")
    let _ = SvgManager.getOrCreate("id2", "line")

    SvgManager.clearAll()

    let html = %raw(`document.getElementById("viewer-hotspot-lines").innerHTML`)
    t->expect(html)->Expect.toBe("")
  })

  test("hide/show sets display property", t => {
    let id = "toggle-id"
    let _ = SvgManager.getOrCreate(id, "path")

    SvgManager.hide(id)
    let elH = Option.getOrThrow(SvgManager.getElement(id))
    let displayH = %raw(`(el) => el.style.display`)(elH)
    t->expect(displayH)->Expect.toBe("none")

    SvgManager.show(id)
    let elS = Option.getOrThrow(SvgManager.getElement(id))
    let displayS = %raw(`(el) => el.style.display`)(elS)
    t->expect(displayS)->Expect.toBe("block")
  })

  test("remove deletes from DOM and cache", t => {
    let id = "remove-id"
    let _el = SvgManager.getOrCreate(id, "path")->Option.getOrThrow

    SvgManager.remove(id)

    let container = ReBindings.Dom.getElementById("viewer-hotspot-lines")
    let found = ReBindings.Dom.querySelector(Nullable.getOrThrow(container), "#" ++ id)
    t->expect(Nullable.toOption(found))->Expect.toBeNone
  })

  test("getElement handles stale elements by removing from cache", t => {
    let id = "stale-id"
    let el = SvgManager.getOrCreate(id, "path")->Option.getOrThrow

    // Manually remove from DOM without telling SvgManager
    ReBindings.Dom.removeElement(el)

    // getElement should now return None because el is no longer in container
    let found = SvgManager.getElement(id)
    t->expect(found)->Expect.toBeNone

    // And it should have been removed from cache, so next getOrCreate should create a NEW one
    let elNew = SvgManager.getOrCreate(id, "path")->Option.getOrThrow
    t->expect(el === elNew)->Expect.toBe(false)
  })
})

describe("SvgManager.Renderer", () => {
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
    SvgManager.Renderer.updateLine("line1", 10.0, 20.0, 30.0, 40.0, "red", 2.0, 0.5, ())
    let el = Option.getOrThrow(SvgManager.getElement("line1"))
    t
    ->expect(ReBindings.Dom.getAttribute(el, "x1")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("10")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "y1")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("20")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "stroke")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("red")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "stroke-width")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("2")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "stroke-opacity")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("0.5")
  })

  test("drawPolyLine builds 'd' string correctly", t => {
    let points = [{Types.x: 0.0, y: 0.0}, {x: 100.0, y: 50.0}, {x: 200.0, y: 0.0}]
    SvgManager.Renderer.drawPolyLine("poly1", points, "blue", 1.0, 1.0, ())

    let el = Option.getOrThrow(SvgManager.getElement("poly1"))
    let d = ReBindings.Dom.getAttribute(el, "d")->Nullable.toOption->Option.getOr("")
    // Note: math rounding in SvgManager.Renderer: Math.round(coords.x * 10.0) / 10.0
    t->expect(d)->Expect.toBe("M 0 0 L 100 50 L 200 0")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "stroke")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("blue")
  })

  test("drawArrow sets transform correctly", t => {
    SvgManager.Renderer.drawArrow("arrow1", 100.0, 200.0, 45.0, "green", 1.0)

    let el = Option.getOrThrow(SvgManager.getElement("arrow1"))
    t
    ->expect(ReBindings.Dom.getAttribute(el, "transform")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("translate(100, 200) rotate(45)")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "fill")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("green")
  })

  test("hide calls manager hide", t => {
    SvgManager.Renderer.updateLine("hider", 0.0, 0.0, 0.0, 0.0, "black", 1.0, 1.0, ())
    SvgManager.Renderer.hide("hider")

    let el = Option.getOrThrow(SvgManager.getElement("hider"))
    let display = %raw(`(el) => el.style.display`)(el)
    t->expect(display)->Expect.toBe("none")
  })

  test("updateLine sets optional attributes correctly", t => {
    SvgManager.Renderer.updateLine(
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
    t
    ->expect(
      ReBindings.Dom.getAttribute(el, "stroke-dasharray")->Nullable.toOption->Option.getOr(""),
    )
    ->Expect.toBe("5,5")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "class")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("custom-line")
  })

  test("drawPolyLine handles optional attributes", t => {
    let points = [{Types.x: 0.0, y: 0.0}, {x: 100.0, y: 50.0}]
    SvgManager.Renderer.drawPolyLine(
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
    t
    ->expect(
      ReBindings.Dom.getAttribute(el, "stroke-dasharray")->Nullable.toOption->Option.getOr(""),
    )
    ->Expect.toBe("2,2")
    t
    ->expect(ReBindings.Dom.getAttribute(el, "class")->Nullable.toOption->Option.getOr(""))
    ->Expect.toBe("custom-poly")
  })

  test("drawPolyLine hides element if less than 2 points", t => {
    let points = [{Types.x: 0.0, y: 0.0}]
    // Create a visible one first
    let points2 = [{Types.x: 0.0, y: 0.0}, {x: 10.0, y: 10.0}]
    SvgManager.Renderer.drawPolyLine("poly_short", points2, "red", 1.0, 1.0, ())
    let el = Option.getOrThrow(SvgManager.getElement("poly_short"))
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("block")

    // Now update with 1 point
    SvgManager.Renderer.drawPolyLine("poly_short", points, "red", 1.0, 1.0, ())
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("none")
  })

  test("drawArrow hides element if coordinates are infinite", t => {
    // Create visible first
    SvgManager.Renderer.drawArrow("arrow_inf", 100.0, 100.0, 0.0, "red", 1.0)
    let el = Option.getOrThrow(SvgManager.getElement("arrow_inf"))
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("block")

    // Update with infinite x
    let inf = 1.0 /. 0.0
    SvgManager.Renderer.drawArrow("arrow_inf", inf, 100.0, 0.0, "red", 1.0)
    t->expect(%raw(`(el) => el.style.display`)(el))->Expect.toBe("none")
  })
})
