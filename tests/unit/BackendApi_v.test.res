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

  test("Should export ApiTypes types (compile check)", _ => {
    // If this compiles, BackendApi successfully includes ApiTypes
    let _: BackendApi.apiResult<unit> = Ok()
  })
})
