open Vitest
open ReBindings

describe("ReBindings", () => {
  test("Svg namespace is correct", t => {
    t->expect(Svg.namespace)->Expect.toBe("http://www.w3.org/2000/svg")
  })

  test("Modules are accessible", _ => {
    /* This just ensures the compiler sees these as valid modules */
    let _ = (Blob.newBlob, File.newFile, JSZip.create)
  })
})
