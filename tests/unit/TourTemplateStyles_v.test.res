// @efficiency: infra-adapter
/* tests/unit/TourTemplateStyles_v.test.res */
open Vitest
open TourTemplates.TourTemplateStyles

let _ = describe("TourTemplateStyles", () => {
  test("generateCSS creates correct styles for Desktop 4K", t => {
    let css = generateCSS("scene1.jpg", "4k", 32, 40)

    t->expect(String.includes(css, "scene1.jpg"))->Expect.toBe(true)
    t->expect(String.includes(css, "width: 1024px"))->Expect.toBe(true)
    t
    ->expect(String.includes(css, "body.export-state-tablet #stage { width: 640px"))
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "max-width: min(calc((100dvh - (var(--export-fallback-padding) * 2)) * 16 / 10), calc(100vw - (var(--export-fallback-padding) * 2)))",
      ),
    )
    ->Expect.toBe(true)
    t->expect(String.includes(css, "height: 32px"))->Expect.toBe(true) // Base size
    t->expect(String.includes(css, "min-height: 27px"))->Expect.toBe(true)
    t->expect(String.includes(css, "padding: 4px 9px 3px 9px"))->Expect.toBe(true)
    t
    ->expect(String.includes(css, "height: var(--export-logo-height, 40px)"))
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "bottom: calc(12px + var(--export-logo-portrait-height, calc(40px)) + 8px)",
      ),
    )
    ->Expect.toBe(true)
    t->expect(String.includes(css, "margin-left: -16px"))->Expect.toBe(true) // Half base size
  })

  test("generateCSS creates responsive styles for HD (same viewport model as 2k)", t => {
    let css = generateCSS("mob.jpg", "hd", 24, 30)

    t->expect(String.includes(css, "mob.jpg"))->Expect.toBe(true)
    t->expect(String.includes(css, "width: 640px"))->Expect.toBe(true)
    t->expect(String.includes(css, "body.export-state-portrait #stage"))->Expect.toBe(true)
    t->expect(String.includes(css, "height: 100dvh; min-height: 100dvh;"))->Expect.toBe(true)
    t->expect(String.includes(css, "overflow: hidden;"))->Expect.toBe(true)
    t->expect(String.includes(css, "375px"))->Expect.toBe(false)
    t
    ->expect(
      String.includes(
        css,
        "body.export-state-portrait #stage { width: min(calc((100dvh - (var(--export-fallback-padding) * 2)) * 9 / 16), calc((100vw - (var(--export-fallback-padding) * 2)) * 0.791)) !important;",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(css, "body.export-state-tablet #viewer-floor-nav-export .floor-nav-btn"),
    )
    ->Expect.toBe(true)
    t->expect(String.includes(css, "height: 24px"))->Expect.toBe(true)
    t
    ->expect(String.includes(css, "width: var(--export-logo-width, auto)"))
    ->Expect.toBe(true)
    t
    ->expect(String.includes(css, "height: var(--export-logo-portrait-height, calc(30px))"))
    ->Expect.toBe(true)
    t->expect(String.includes(css, "margin-left: -12px"))->Expect.toBe(true)
  })

  test("generateCSS includes portrait export control styling", t => {
    let css = generateCSS("touch.jpg", "2k", 32, 40)

    t->expect(String.includes(css, "#viewer-portrait-joystick-export"))->Expect.toBe(true)
    t->expect(String.includes(css, "#viewer-sequence-prompt-export"))->Expect.toBe(true)
    t->expect(String.includes(css, "--export-touch-mode-title-size: 22px"))->Expect.toBe(true)
    t->expect(String.includes(css, "background: rgba(3, 12, 30, 0.82);"))->Expect.toBe(true)
    t->expect(String.includes(css, "color: rgba(251, 146, 60, 0.94);"))->Expect.toBe(true)
    t
    ->expect(String.includes(css, "body.export-ui-portrait-adaptive #viewer-floor-nav-export"))
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive:not(.is-map-open) .looking-mode-indicator",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "#viewer-portrait-mode-selector-export.is-portrait-mode-selector .portrait-mode-selector-title",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-shell-classic #viewer-portrait-mode-selector-export.is-portrait-mode-selector",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-mode-selector-export.is-portrait-mode-selector .portrait-mode-orb",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-mode-selector-export.is-portrait-mode-selector { position: absolute;",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-mode-selector-export.is-portrait-mode-selector.state-intro",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "state-intro .portrait-mode-orb.state-idle { background: linear-gradient(180deg, #0e2d52, #002147);",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "state-docked .portrait-mode-selector-cluster { flex-direction: column; align-items: flex-start; justify-content: flex-start;",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-mode-selector-export.is-portrait-mode-selector.state-docked { top: var(--export-touch-docked-top); left: var(--export-touch-docked-orb-left); transform: none; align-items: flex-start; width: fit-content; }",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-mode-selector-export.is-portrait-mode-selector.state-docked .portrait-mode-selector-title { display: none; }",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-joystick-export .portrait-joystick-btn",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(String.includes(css, "body.export-portrait-mode-intro #viewer-room-label-export"))
    ->Expect.toBe(true)
    t
    ->expect(String.includes(css, "body.export-portrait-mode-intro .looking-mode-indicator"))
    ->Expect.toBe(true)
    t->expect(String.includes(css, "--export-touch-orb-size: 48px"))->Expect.toBe(true)
    t->expect(String.includes(css, "--export-touch-floor-btn-size: 34px"))->Expect.toBe(true)
    t->expect(String.includes(css, "--export-touch-rail-left: 13px"))->Expect.toBe(true)
    t->expect(String.includes(css, "--export-touch-docked-orb-left: 6px"))->Expect.toBe(true)
    t
    ->expect(String.includes(css, "width: var(--export-touch-orb-size); height: var(--export-touch-orb-size);"))
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-floor-nav-export { gap: 10px; bottom: var(--export-touch-floor-bottom); left: var(--export-touch-rail-left);",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-portrait-mode-selector-export.is-portrait-mode-selector { position: absolute; top: var(--export-touch-docked-top); left: var(--export-touch-docked-orb-left);",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-floor-nav-export .floor-nav-btn { cursor: pointer; color: #fff; backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); width: var(--export-touch-floor-btn-size); height: var(--export-touch-floor-btn-size); min-width: var(--export-touch-floor-btn-size); min-height: var(--export-touch-floor-btn-size); font-size: var(--export-touch-floor-btn-font-size);",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-landscape-touch #viewer-floor-nav-export .floor-nav-btn { cursor: pointer; color: #fff; backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); width: var(--export-touch-floor-btn-size); height: var(--export-touch-floor-btn-size); min-width: var(--export-touch-floor-btn-size); min-height: var(--export-touch-floor-btn-size); font-size: var(--export-touch-floor-btn-font-size);",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-ui-portrait-adaptive #viewer-floor-nav-export .floor-nav-btn sup { font-size: var(--export-touch-floor-btn-sup-size); margin-left: 0; }",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "body.export-shell-classic.is-auto-tour-active .mode-status-line { display: none !important; }",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "#viewer-portrait-mode-selector-export.is-portrait-mode-selector .portrait-mode-selector-countdown { display: inline-flex;",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      String.includes(
        css,
        "#viewer-portrait-mode-selector-export.is-portrait-mode-selector .portrait-mode-selector-countdown-number { color: rgba(251, 146, 60, 0.98); font-weight: 800; }",
      ),
    )
    ->Expect.toBe(true)
    t
    ->expect(String.includes(css, "portrait-joystick-icon { width: var(--export-touch-orb-icon-size); height: var(--export-touch-orb-icon-size)"))
    ->Expect.toBe(true)
    t
    ->expect(String.includes(css, "filter: grayscale(1) blur(6px) brightness(0.82);"))
    ->Expect.toBe(true)
  })
})
