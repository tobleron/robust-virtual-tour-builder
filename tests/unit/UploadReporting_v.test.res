open Vitest

describe("UploadReporting", () => {
  test("shouldAutoApplySuggestedName allows empty current name", t => {
    let allowed = UploadReporting.shouldAutoApplySuggestedName(
      ~currentName="",
      ~suggestedName="Maadi_Cairo_050326_1010",
    )
    t->expect(allowed)->Expect.toBe(true)
  })

  test("shouldAutoApplySuggestedName blocks custom current name", t => {
    let allowed = UploadReporting.shouldAutoApplySuggestedName(
      ~currentName="MyCustomProjectName",
      ~suggestedName="Maadi_Cairo_050326_1010",
    )
    t->expect(allowed)->Expect.toBe(false)
  })

  test("shouldAutoApplySuggestedName blocks unknown suggestions", t => {
    let allowed = UploadReporting.shouldAutoApplySuggestedName(
      ~currentName="Untitled Tour",
      ~suggestedName="Unknown_Location_050326_1010",
    )
    t->expect(allowed)->Expect.toBe(false)
  })

  testAsync("awaitWithTimeout returns success for fast promise", async t => {
    let result = await UploadReporting.awaitWithTimeout(
      ~promise=Promise.resolve("ok"),
      ~timeoutMs=50,
    )
    t->expect(result)->Expect.toEqual(Ok("ok"))
  })

  testAsync("awaitWithTimeout returns timeout for stalled promise", async t => {
    let stalled: Promise.t<string> = Promise.make((_resolve, _reject) => ())
    let result = await UploadReporting.awaitWithTimeout(~promise=stalled, ~timeoutMs=10)
    t->expect(result)->Expect.toEqual(Error("TitleDiscoveryTimeout"))
  })
})
