// @efficiency: infra-adapter
open Vitest
open TourTemplateScripts

describe("TourTemplateScripts", () => {
  test("generateRenderScript should include correct base size and core logic", t => {
    let script = generateRenderScript(32)

    t->expect(String.includes(script, "32px"))->Expect.toBe(true)
    t->expect(String.includes(script, "renderGoldArrow"))->Expect.toBe(true)
    t->expect(String.includes(script, "hotSpotDiv"))->Expect.toBe(true)
    t->expect(String.includes(script, "window.viewer"))->Expect.toBe(true)
  })

  test("generateRenderScript should scale with different base sizes", t => {
    let scriptLarge = generateRenderScript(64)
    t->expect(String.includes(scriptLarge, "64px"))->Expect.toBe(true)
  })
})
