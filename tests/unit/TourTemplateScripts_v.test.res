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
      t->expectToContain(script, "function triggerAutoNavigationMode()")
      t->expectToContain(script, "setAutoTourSpeedMultiplier(AUTO_TOUR_BOOSTED_SPEED_MULTIPLIER);")
      t->expectToContain(
        script,
        "progress = Math.min(1, progress + getAnimationProgressStep(deltaMs, durationMs));",
      )
      t->expectToContain(script, "}, getAutoTourForwardDelayMs());")
      t->expectToContain(script, "const autoModeLabel = !floorTagShortcutState.isAutoTourActive")
      t->expectToContain(script, "return typeof isAutoTourSpeedBoosted === \"function\" && isAutoTourSpeedBoosted()")
      t->expectToContain(script, "? \"auto 2x\"")
      t->expectToContain(script, "\"auto 1x\"")
      t->expectToContain(script, "if (typeof speedUpAutoTour === \"function\") {")
      t->expectToContain(script, "return speedUpAutoTour();")
    },
  )

  test("generateRenderScript should render desktop navigation mode rows in manual semi-auto auto order", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)
    let manualIndex = String.indexOf(script, "label: \"manual\"")
    let semiAutoIndex = String.indexOf(script, "label: \"semi-auto\"")
    let autoIndex = String.indexOf(script, "label: autoModeLabel")

    t->expect(manualIndex >= 0)->Expect.toBe(true)
    t->expect(semiAutoIndex >= 0)->Expect.toBe(true)
    t->expect(autoIndex >= 0)->Expect.toBe(true)
    t->expect(manualIndex < semiAutoIndex)->Expect.toBe(true)
    t->expect(semiAutoIndex < autoIndex)->Expect.toBe(true)
  })

  test("generateRenderScript should include portrait export controls", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(script, "function isPortraitAdaptiveExportUi()")
    t->expectToContain(script, "function resolveExportInteractionShell()")
    t->expectToContain(script, "function isTouchFriendlyExportUi()")
    t->expectToContain(script, "function syncExportAdaptiveUiForCurrentScene()")
    t->expectToContain(script, "if (detectTouchPrimaryInput()) return \"landscape-touch\";")
    t->expectToContain(script, "const referenceStageArea = 832.0 * 520.0;")
    t->expectToContain(script, "const dockedOrbLeftPx = railLeftPx;")
    t->expectToContain(script, "root.setProperty(\"--export-touch-rail-left\", railLeftPx + \"px\");")
    t->expectToContain(script, "root.setProperty(\"--export-touch-docked-orb-left\", dockedOrbLeftPx + \"px\");")
    t->expectToContain(script, "function getAdaptivePortraitHfov()")
    t->expectToContain(script, "const portraitMaxHfov = clampExportMetric(Math.floor((MAX_HFOV * 0.93) * 10.0) / 10.0, MIN_HFOV, MAX_HFOV);")
    t->expectToContain(script, "if (effectiveStageWidth >= 700) return portraitMaxHfov;")
    t->expectToContain(script, "if (effectiveStageWidth >= 600) return clampExportMetric(78.0, MIN_HFOV, portraitMaxHfov);")
    t->expectToContain(script, "if (effectiveStageWidth >= 480) return clampExportMetric(72.0, MIN_HFOV, portraitMaxHfov);")
    t->expectToContain(script, "return state === \"portrait\" ? getAdaptivePortraitHfov() : MAX_HFOV;")
    t->expectToContain(script, "window.viewer.setHfovBounds([nextHfov, nextHfov]);")
    t->expectToContain(script, "window.viewer.setHfovBounds([MIN_HFOV, MAX_HFOV]);")
    t->expectToContain(script, "function resolveFirstSceneForFloor(floorId)")
    t->expectToContain(script, "function navigateToFirstSceneInFloor(floorId)")
    t->expectToContain(script, "const EXPORT_DEFAULT_NAVIGATION_MODE = EXPORT_NAVIGATION_MODE_SEMI_AUTO;")
    t->expectToContain(script, "function setPortraitBaseNavigationMode(nextMode)")
    t->expectToContain(script, "function activateExportNavigationMode(mode)")
    t->expectToContain(script, "function isSemiAutoExportNavigationMode()")
    t->expectToContain(script, "function ensurePortraitModeSelectorForViewport(")
    t->expectToContain(script, "function updateTouchFriendlyOrbMetrics()")
    t->expectToContain(script, "function shouldIgnorePortraitAutoOrbTap()")
    t->expectToContain(script, "function getPortraitModeSelectorPanel()")
    t->expectToContain(script, "function getSceneSequencePromptHost()")
    t->expectToContain(script, "title.textContent = \"Choose tour mode:\";")
    t->expectToContain(script, "function clearPortraitJoystick()")
    t->expectToContain(script, "function updatePortraitJoystick()")
    t->expectToContain(script, "function renderPortraitAdaptiveShortcutPanel(panel)")
    t->expectToContain(script, "function isLookingModeInteractionAvailable()")
    t->expectToContain(script, "function resolvePortraitModeOrbLines(mode)")
    t->expectToContain(script, "return { primary: \"Semi\", secondary: \"Auto\" };")
    t->expectToContain(script, "return { primary: \"Manual\", secondary: \"\" };")
    t->expectToContain(script, "return { primary: resolvePortraitAutoOrbLabel(), secondary: \"\" };")
    t->expectToContain(script, "function handlePortraitModeSelectorClick(mode, event)")
    t->expectToContain(script, "collapsePortraitModeSelectorIntro();")
    t->expectToContain(script, "navigateToFirstSceneInFloor(level.id);")
    t->expectToContain(script, "panel.classList.add(\"is-portrait-mode-selector\");")
    t->expectToContain(script, "cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_SEMI_AUTO));")
    t->expectToContain(script, "cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_MANUAL));")
    t->expectToContain(script, "cluster.appendChild(createModeOrb(EXPORT_NAVIGATION_MODE_AUTO));")
    t->expectToContain(script, "countdown.className = \"portrait-mode-selector-countdown\";")
    t->expectToContain(script, "countdownLabel.textContent = \"Returning home\";")
    t->expectToContain(script, "countdownNumber.textContent = String(autoTourHomeReturnCountdownRemaining);")
    t->expectToContain(script, "root.setProperty(\"--export-touch-floor-btn-size\", floorButtonSizePx + \"px\");")
    t->expectToContain(
      script,
      "root.setProperty(\"--export-touch-floor-btn-font-size\", floorButtonFontPx + \"px\");",
    )
    t->expectToContain(script, "root.setProperty(\"--export-touch-floor-btn-sup-size\", floorButtonSupPx + \"px\");")
  })

  test("generateRenderScript should resolve exported viewport state to portrait or desktop only", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 832, true, false)

    t->expectToContain(script, "if (portraitViewport) return \"portrait\";")
    t->expectToContain(script, "return \"desktop\";")
    t->expect(String.includes(script, "EXPORT_ALLOW_TABLET_LANDSCAPE_STAGE"))->Expect.toBe(false)
    t->expect(String.includes(script, "return \"tablet\";"))->Expect.toBe(false)
  })

  test("generateRenderScript should suspend looking mode around classic desktop scene-number prompt", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(script, "const sceneSequencePromptRuntime = { restoreLookingModeOnSuccess: false };")
    t->expectToContain(script, "function suspendLookingModeForSceneSequencePrompt()")
    t->expectToContain(script, "function restoreLookingModeAfterSceneSequencePromptSuccess()")
    t->expectToContain(script, "if (interactionShell !== \"classic\") return false;")
    t->expectToContain(script, "suspendLookingModeForSceneSequencePrompt();")
    t->expectToContain(script, "fromSceneSequencePrompt: true,")
    t->expectToContain(script, "restoreLookingModeAfterSceneSequencePromptSuccess();")
    t->expectToContain(script, "key === \"Escape\" || key === \"Esc\" || key === \"n\" || key === \"N\"")
    t->expectToContain(script, "exitHint.textContent = \"n to return\";")
  })

  test("generateRenderScript should render selector intro while blocking UI even on classic shell", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(script, "if (portraitModeSelectorState.hasResolvedIntro !== true) {")
    t->expectToContain(script, "const selectorBlockingUi =")
    t->expectToContain(script, "if (isTouchFriendlyUi || selectorBlockingUi) {")
  })

  test("generateRenderScript should hide classic navigation-mode section while auto-tour is active", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(
      script,
      "if (!floorTagShortcutState.isAutoTourActive && autoTourHomeReturnCountdownRemaining <= 0) {",
    )
  })

  test("generateRenderScript should not stop auto-tour when portrait controls are pressed", t => {
    let script = generateRenderScript(32, 90.0, 65.0, 90.0, 375, 640, true, false)

    t->expectToContain(script, "function shouldStopAutoTourOnPointerDown(event)")
    t->expectToContain(
      script,
      "\"#viewer-floor-tags-export, #viewer-portrait-mode-selector-export, #viewer-floor-nav-export, #viewer-portrait-joystick-export, #viewer-sequence-prompt-export, .looking-mode-indicator\"",
    )
    t->expectToContain(script, "document.addEventListener(\"mousedown\", event => {")
    t->expectToContain(script, "shouldStopAutoTourOnPointerDown(event)")
  })
})
