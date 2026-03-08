open Vitest

describe("ProjectManagerUrl.rebuildUrl", () => {
  let expectUrlSuffix = (t, rebuilt, expectedSuffix) =>
    switch rebuilt {
    | Types.Url(url) => t->expect(String.endsWith(url, expectedSuffix))->Expect.toBe(true)
    | _ => t->expect(false)->Expect.toBe(true)
    }

  test("rebuilds logo upload sentinel into the current project asset URL", t => {
    let rebuilt = ProjectManagerUrl.rebuildUrl(Types.Url("logo_upload"), ~sessionId="session-1")
    expectUrlSuffix(t, rebuilt, "/api/project/session-1/file/logo_upload")
  })

  test("rebuilds legacy backend asset URLs into the current project session", t => {
    let rebuilt = ProjectManagerUrl.rebuildUrl(
      Types.Url("/api/project/old-session/file/logo_upload?cache=1"),
      ~sessionId="session-2",
    )
    expectUrlSuffix(t, rebuilt, "/api/project/session-2/file/logo_upload")
  })

  test("rebuilds relative filenames into encoded project asset URLs", t => {
    let rebuilt = ProjectManagerUrl.rebuildUrl(
      Types.Url("images/Brand Logo Final.png"),
      ~sessionId="session-3",
    )
    expectUrlSuffix(t, rebuilt, "/api/project/session-3/file/Brand%20Logo%20Final.png")
  })

  test("invalid blob URLs are blanked so callers can fall back safely", t => {
    let rebuilt = ProjectManagerUrl.rebuildUrl(Types.Url("blob:http://localhost:3000/dead"), ~sessionId="session-4")
    t->expect(rebuilt)->Expect.toEqual(Types.Url(""))
  })
})
