// @efficiency: infra-adapter
open Vitest

describe("VersionData", () => {
  test("Constants are defined", t => {
    t->expect(VersionData.version != "")->Expect.toBe(true)
    t->expect(VersionData.buildNumber > 0)->Expect.toBe(true)
    t->expect(VersionData.buildInfo != "")->Expect.toBe(true)
  })
})
