// @efficiency: infra-adapter
open Vitest

describe("Version", () => {
  test("Constants are defined", t => {
    t->expect(Version.version != "")->Expect.toBe(true)
    t->expect(Version.buildNumber > 0)->Expect.toBe(true)
    t->expect(Version.buildInfo != "")->Expect.toBe(true)
  })
})
