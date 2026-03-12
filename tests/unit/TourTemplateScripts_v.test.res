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

      t->expectToContain(script, "const ANIMATED_NAVIGATION_BASE_SPEED_MULTIPLIER = 1.44;")
      t->expectToContain(script, "const AUTO_TOUR_BASE_SPEED_MULTIPLIER = ANIMATED_NAVIGATION_BASE_SPEED_MULTIPLIER;")
      t->expectToContain(script, "const AUTO_TOUR_BOOSTED_SPEED_MULTIPLIER = 2.24;")
      t->expectToContain(script, "function applyAutoTourBaseSpeed()")
      t->expectToContain(script, "function isAutoTourSpeedBoosted()")
      t->expectToContain(script, "function getAnimatedPlaybackSpeedMultiplier()")
      t->expectToContain(script, "function getAnimationProgressStep(deltaMs, baseDurationMs)")
      t->expectToContain(script, "function getAutoTourForwardDelayMs()")
      t->expectToContain(script, "if (typeof stopAutoTour === \"function\") {")
      t->expectToContain(script, "setAutoTourSpeedMultiplier(AUTO_TOUR_BOOSTED_SPEED_MULTIPLIER);")
      t->expectToContain(
        script,
        "progress = Math.min(1, progress + getAnimationProgressStep(deltaMs, durationMs));",
      )
      t->expectToContain(script, "}, getAutoTourForwardDelayMs());")
      t->expectToContain(
        script,
        "speedLabel.textContent = isSpeedBoosted ? \"2x\" : \"1x\";",
      )
      t->expectToContain(script, "return typeof isAutoTourSpeedBoosted === \"function\" && isAutoTourSpeedBoosted()")
      t->expectToContain(script, "? \"2x\"")
      t->expectToContain(script, ": \"1x\";")
      t->expectToContain(script, "if (window.isAutoTourActive) {")
      t->expectToContain(script, "if (typeof speedUpAutoTour === \"function\") speedUpAutoTour();")
    },
  )

  test("generateRenderScript should render auto-tour speed toggle above stop action", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)
    let speedIndex = String.indexOf(
      script,
      "speedLabel.textContent = isSpeedBoosted ? \"2x\" : \"1x\";",
    )
    let stopIndex = String.indexOf(script, "stopLabel.textContent = \"stop auto tour\";")

    t->expect(speedIndex >= 0)->Expect.toBe(true)
    t->expect(stopIndex >= 0)->Expect.toBe(true)
    t->expect(speedIndex < stopIndex)->Expect.toBe(true)
  })

  test("generateRenderScript should include portrait export controls", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(script, "function isPortraitAdaptiveExportUi()")
    t->expectToContain(script, "function resolveExportInteractionShell()")
    t->expectToContain(script, "function isTouchFriendlyExportUi()")
    t->expectToContain(script, "function syncExportAdaptiveUiForCurrentScene()")
    t->expectToContain(script, "function resolveFirstSceneForFloor(floorId)")
    t->expectToContain(script, "function navigateToFirstSceneInFloor(floorId)")
    t->expectToContain(script, "const EXPORT_DEFAULT_NAVIGATION_MODE = EXPORT_NAVIGATION_MODE_SEMI_AUTO;")
    t->expectToContain(script, "function setPortraitBaseNavigationMode(nextMode)")
    t->expectToContain(script, "function isSemiAutoExportNavigationMode()")
    t->expectToContain(script, "function ensurePortraitModeSelectorForViewport(previousPortraitAdaptiveUi, nextPortraitAdaptiveUi)")
    t->expectToContain(script, "function shouldIgnorePortraitAutoOrbTap()")
    t->expectToContain(script, "function getPortraitModeSelectorPanel()")
    t->expectToContain(script, "function clearPortraitJoystick()")
    t->expectToContain(script, "function updatePortraitJoystick()")
    t->expectToContain(script, "function renderPortraitAdaptiveShortcutPanel(panel)")
    t->expectToContain(script, "function isLookingModeInteractionAvailable()")
    t->expectToContain(script, "function resolvePortraitModeOrbLines(mode)")
    t->expectToContain(script, "return { primary: \"Semi\", secondary: \"Auto\" };")
    t->expectToContain(script, "return { primary: \"Manual\", secondary: \"\" };")
    t->expectToContain(script, "return { primary: resolvePortraitAutoOrbLabel(), secondary: \"\" };")
    t->expectToContain(script, "function handlePortraitModeSelectorClick(mode, event)")
    t->expectToContain(script, "setPortraitBaseNavigationMode(normalizedMode);")
    t->expectToContain(script, "collapsePortraitModeSelectorIntro();")
    t->expectToContain(script, "navigateToFirstSceneInFloor(level.id);")
    t->expectToContain(script, "panel.classList.add(\"is-portrait-mode-selector\");")
    t->expectToContain(script, "cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_SEMI_AUTO));")
    t->expectToContain(script, "cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_MANUAL));")
    t->expectToContain(script, "cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_AUTO));")
  })

  test("generateRenderScript should not stop auto-tour when portrait controls are pressed", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(script, "function shouldStopAutoTourOnPointerDown(event)")
    t->expectToContain(
      script,
      "\"#viewer-floor-tags-export, #viewer-portrait-mode-selector-export, #viewer-floor-nav-export, #viewer-portrait-joystick-export, .looking-mode-indicator\"",
    )
    t->expectToContain(script, "document.addEventListener(\"mousedown\", event => {")
    t->expectToContain(script, "shouldStopAutoTourOnPointerDown(event)")
  })
})
