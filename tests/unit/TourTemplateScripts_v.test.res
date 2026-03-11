// @efficiency: infra-adapter
open Vitest
open TourTemplates.TourTemplateScripts

describe("TourTemplateScripts", () => {
  let expectToContain = (t, str, sub) => {
    t->expect(String.includes(str, sub))->Expect.toBe(true)
  }

  test("generateRenderScript should include correct base size and core logic", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expect(String.includes(script, "32px"))->Expect.toBe(true)
    t->expect(String.includes(script, "const MIN_HFOV = 65"))->Expect.toBe(true)
    t->expect(String.includes(script, "const STAGE_MIN_WIDTH = 375"))->Expect.toBe(true)
    t->expect(String.includes(script, "renderOrangeHotspot"))->Expect.toBe(true)
    t->expect(String.includes(script, "hotSpotDiv"))->Expect.toBe(true)
    t->expect(String.includes(script, "window.viewer"))->Expect.toBe(true)
  })

  test("generateRenderScript should scale with different base sizes", t => {
    let scriptLarge = generateRenderScript(64, 90.0, 65.0, 90.0, 375, 640, true, false)
    t->expect(String.includes(scriptLarge, "64px"))->Expect.toBe(true)
  })

  test(
    "generateRenderScript should embed exported auto-tour speed constants and toggle helpers",
    t => {
      let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

      t->expectToContain(script, "const AUTO_TOUR_BASE_SPEED_MULTIPLIER = 1.2;")
      t->expectToContain(script, "const AUTO_TOUR_SPEED_UP_MULTIPLIER = 1.7;")
      t->expectToContain(script, "function applyAutoTourBaseSpeed()")
      t->expectToContain(script, "function isAutoTourSpeedBoosted()")
      t->expectToContain(script, "function getAnimationProgressStep(deltaMs, baseDurationMs)")
      t->expectToContain(script, "function getAutoTourForwardDelayMs()")
      t->expectToContain(
        script,
        "setAutoTourSpeedMultiplier(AUTO_TOUR_BASE_SPEED_MULTIPLIER * AUTO_TOUR_SPEED_UP_MULTIPLIER);",
      )
      t->expectToContain(
        script,
        "progress = Math.min(1, progress + getAnimationProgressStep(deltaMs, durationMs));",
      )
      t->expectToContain(script, "}, getAutoTourForwardDelayMs());")
      t->expectToContain(
        script,
        "speedLabel.textContent = isSpeedBoosted ? \"slow down 1x\" : \"speed up 1.7x\";",
      )
      t->expectToContain(script, "if (window.isAutoTourActive) {")
      t->expectToContain(script, "if (typeof speedUpAutoTour === \"function\") speedUpAutoTour();")
    },
  )

  test("generateRenderScript should render auto-tour speed toggle above stop action", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)
    let speedIndex = String.indexOf(
      script,
      "speedLabel.textContent = isSpeedBoosted ? \"slow down 1x\" : \"speed up 1.7x\";",
    )
    let stopIndex = String.indexOf(script, "stopLabel.textContent = \"stop auto tour\";")

    t->expect(speedIndex >= 0)->Expect.toBe(true)
    t->expect(stopIndex >= 0)->Expect.toBe(true)
    t->expect(speedIndex < stopIndex)->Expect.toBe(true)
  })
})
