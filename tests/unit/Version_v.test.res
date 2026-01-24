/* tests/unit/Version_v.test.res */
open Vitest
open Version

describe("Version - Build Information", () => {
  test("getVersion returns correctly from VersionData", t => {
    t->expect(getVersion())->Expect.toBe(VersionData.version)
  })

  test("getBuildInfo returns correctly from VersionData", t => {
    t->expect(getBuildInfo())->Expect.toBe(VersionData.buildInfo)
  })

  test("getFullVersion combines version and buildInfo", t => {
    let expected = VersionData.version ++ " " ++ VersionData.buildInfo
    t->expect(getFullVersion())->Expect.toBe(expected)
  })
})
