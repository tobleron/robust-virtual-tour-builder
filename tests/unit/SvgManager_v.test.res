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
    t->expect(ReBindings.Dom.getAttribute(el, "id"))->Expect.toBe("test-id")

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
})
