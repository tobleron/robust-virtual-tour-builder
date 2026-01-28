// @efficiency: infra-adapter
open Vitest
open RescriptSchema

describe("Final Async Check", () => {
  test("Domain.scene should be sync", t => {
    t->expect(S.isAsync(Schemas.Domain.scene))->Expect.toBe(false)
  })

  test("Domain.project should be sync", t => {
    t->expect(S.isAsync(Schemas.Domain.project))->Expect.toBe(false)
  })
})
