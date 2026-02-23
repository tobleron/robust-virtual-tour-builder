// @efficiency: infra-adapter
open Vitest

describe("Version", () => {
  test("Constants are defined", t => {
    t->expect(Version.version != "")->Expect.toBe(true)
    t->expect(Version.buildNumber >= 0)->Expect.toBe(true)
    t->expect(Version.buildInfo != "")->Expect.toBe(true)
  })
  test("getFullVersion includes build number", t => {
    let full = Version.getFullVersion()
    t->expect(String.includes(full, "+"))->Expect.toBe(true)
  })
  test("getVersionLabel prefixes the version with v", t => {
    let label = Version.getVersionLabel()
    t->expect(String.startsWith(label, "v"))->Expect.toBe(true)
  })
})
