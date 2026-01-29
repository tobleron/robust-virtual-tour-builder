open Vitest
open Teaser.State

describe("TeaserState", () => {
  test("getConfigForStyle returns correct config", t => {
    t->expect(getConfigForStyle("punchy"))->Expect.toEqual(punchyConfig)
    t->expect(getConfigForStyle("slow"))->Expect.toEqual(slowConfig)
    t->expect(getConfigForStyle("fast"))->Expect.toEqual(fastConfig)
    t->expect(getConfigForStyle("unknown"))->Expect.toEqual(fastConfig)
  })
})
