// @efficiency: infra-adapter
open Vitest
open TourTemplates.TourTemplateScripts

describe("TourTemplateScripts", () => {
  test("generateRenderScript should include correct base size and core logic", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true)

    t->expect(String.includes(script, "32px"))->Expect.toBe(true)
    t->expect(String.includes(script, "const MIN_HFOV = 65"))->Expect.toBe(true)
    t->expect(String.includes(script, "const STAGE_MIN_WIDTH = 375"))->Expect.toBe(true)
    t->expect(String.includes(script, "renderOrangeHotspot"))->Expect.toBe(true)
    t->expect(String.includes(script, "hotSpotDiv"))->Expect.toBe(true)
    t->expect(String.includes(script, "window.viewer"))->Expect.toBe(true)
  })

  test("generateRenderScript should scale with different base sizes", t => {
    let scriptLarge = generateRenderScript(64, 90.0, 65.0, 90.0, 375, 640, true)
    t->expect(String.includes(scriptLarge, "64px"))->Expect.toBe(true)
  })
})
