/* tests/unit/BackendApi_v.test.res */
open Vitest

describe("BackendApi Facade", () => {
  beforeEach(() => {
    let _ = %raw(`globalThis.fetch = vi.fn()`)
  })

  test("Should export ProjectApi functions", t => {
    let fn = BackendApi.importProject
    t->expect(typeof(fn))->Expect.toBe(#function)
  })

  test("Should export MediaApi functions", t => {
    let fn = BackendApi.extractMetadata
    t->expect(typeof(fn))->Expect.toBe(#function)
  })

  test("Should export Api types (compile check)", t => {
    // If this compiles, BackendApi successfully includes Api
    let _: Api.importResponse = {
      sessionId: "test",
      projectData: JSON.Encode.object(Dict.make()),
    }
    t->expect(true)->Expect.toBe(true)
  })
})
