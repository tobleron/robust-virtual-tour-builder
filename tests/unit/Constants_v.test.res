open Vitest

describe("Constants", _ => {
  test("debug configuration defaults", t => {
    t->expect(Constants.debugLogLevel)->Expect.toBe("info")
    t->expect(Constants.debugMaxEntries)->Expect.toBe(500)
    t->expect(Constants.perfWarnThreshold)->Expect.toBe(500.0)
    t->expect(Constants.perfInfoThreshold)->Expect.toBe(100.0)
  })

  test("hotspot configuration", t => {
    t->expect(Constants.hotspotVisualOffsetDegrees)->Expect.toBe(0.0)
    t->expect(Constants.returnLinkDefaultPitch)->Expect.toBe(0.0)
    t->expect(Constants.returnLinkDisplayOffset)->Expect.toBe(-15.0)
    t->expect(Constants.linkingRodHeight)->Expect.toBe(80.0)
  })

  test("viewer configuration", t => {
    t->expect(Constants.globalHfov)->Expect.toBe(90.0)
  })

  test("teaser configuration", t => {
    t->expect(Constants.Teaser.canvasWidth)->Expect.toBe(1920)
    t->expect(Constants.Teaser.canvasHeight)->Expect.toBe(1080)
    t->expect(Constants.Teaser.frameRate)->Expect.toBe(60)

    t->expect(Constants.Teaser.StyleDissolve.clipDuration)->Expect.toBe(2000)
    t->expect(Constants.Teaser.StyleDissolve.transitionDuration)->Expect.toBe(1000)
    t->expect(Constants.Teaser.StyleDissolve.cameraPanOffset)->Expect.toBe(8.0)

    t->expect(Constants.Teaser.StylePunchy.clipDuration)->Expect.toBe(1200)
    t->expect(Constants.Teaser.StylePunchy.transitionDuration)->Expect.toBe(200)
    t->expect(Constants.Teaser.StylePunchy.cameraPanOffset)->Expect.toBe(0.0)

    t->expect(Constants.Teaser.Logo.width)->Expect.toBe(150)
    t->expect(Constants.Teaser.Logo.padding)->Expect.toBe(30)
    t->expect(Constants.Teaser.Logo.borderRadius)->Expect.toBe(12)
  })

  test("image processing configuration", t => {
    t->expect(Constants.webpQuality)->Expect.toBe(0.92)
    t->expect(Constants.processedImageWidth)->Expect.toBe(4096)
    t->expect(Constants.imageResizeQuality)->Expect.toBe("high")
  })

  test("progress bar configuration", t => {
    t->expect(Constants.progressBarAutoHideDelay)->Expect.toBe(2400)
  })

  test("notification system configuration", t => {
    t->expect(Constants.toastDisplayDuration)->Expect.toBe(4000)
    t->expect(Constants.toastAnimationDuration)->Expect.toBe(400)
  })

  test("download system configuration", t => {
    t->expect(Constants.blobUrlCleanupDelay)->Expect.toBe(60000)
  })

  test("ffmpeg configuration", t => {
    t->expect(Constants.FFmpeg.crfQuality)->Expect.toBe(18)
    t->expect(Constants.FFmpeg.preset)->Expect.toBe("medium")
    t->expect(Constants.FFmpeg.coreVersion)->Expect.toBe("0.12.10")
  })

  test("project management configuration", t => {
    t->expect(Constants.zipCompressionLevel)->Expect.toBe(6)
    t->expect(Constants.uiYieldDelay)->Expect.toBe(10)
  })

  test("animation timing configuration", t => {
    t->expect(Constants.modalFadeDuration)->Expect.toBe(100)
    t->expect(Constants.panningVelocity)->Expect.toBe(12.0)
    t->expect(Constants.panningMinDuration)->Expect.toBe(1000.0)
    t->expect(Constants.panningMaxDuration)->Expect.toBe(15000.0)
    t->expect(Constants.sceneStabilizationDelay)->Expect.toBe(1000)
    t->expect(Constants.viewerLoadCheckInterval)->Expect.toBe(100)
    t->expect(Constants.tooltipDelayDuration)->Expect.toBe(900)
  })

  test("scene floor levels", t => {
    let levels = Constants.Scene.floorLevels
    t->expect(Belt.Array.length(levels) > 0)->Expect.toBe(true)

    let ground = Belt.Array.getBy(levels, l => l.id == "ground")
    t->expect(Belt.Option.isSome(ground))->Expect.toBe(true)
    let g = Belt.Option.getExn(ground)
    t->expect(g.label)->Expect.toBe("Ground Floor")
    t->expect(g.short)->Expect.toBe("G")

    let b1 = Belt.Array.getBy(levels, l => l.id == "b1")
    t->expect(Belt.Option.isSome(b1))->Expect.toBe(true)
    let b = Belt.Option.getExn(b1)
    t->expect(b.suffix)->Expect.toBe(Some("-1"))
  })

  test("scene defaults", t => {
    t->expect(Constants.Scene.Defaults.category)->Expect.toBe("outdoor")
    t->expect(Constants.Scene.Defaults.floor)->Expect.toBe("ground")
    t->expect(Constants.Scene.Defaults.label)->Expect.toBe("")
    t->expect(Constants.Scene.Defaults.description)->Expect.toBe("")
  })

  test("scene room labels", t => {
    let hasKitchen = Belt.Array.some(Constants.Scene.RoomLabels.indoor, x => x == "Kitchen")
    t->expect(hasKitchen)->Expect.toBe(true)

    let hasGarden = Belt.Array.some(Constants.Scene.RoomLabels.outdoor, x => x == "Garden")
    t->expect(hasGarden)->Expect.toBe(true)

    let indoorPreset = Dict.get(Constants.roomLabelPresets, "indoor")
    t->expect(Belt.Option.isSome(indoorPreset))->Expect.toBe(true)

    let outdoorPreset = Dict.get(Constants.roomLabelPresets, "outdoor")
    t->expect(Belt.Option.isSome(outdoorPreset))->Expect.toBe(true)
  })

  test("backend configuration", t => {
    let url = Constants.backendUrl
    t->expect(url != "")->Expect.toBe(true)
  })

  test("navigation and simulation configuration", t => {
    t->expect(Constants.blinkDurationPreview)->Expect.toBe(1200)
    t->expect(Constants.blinkDurationSimulation)->Expect.toBe(1200)
    t->expect(Constants.blinkRatePreview)->Expect.toBe(300)
    t->expect(Constants.blinkRateSimulation)->Expect.toBe(600)
    t->expect(Constants.Simulation.stepDelay)->Expect.toBe(800)
    t->expect(Constants.idleSnapshotDelay)->Expect.toBe(2000)
    t->expect(Constants.sceneLoadTimeout)->Expect.toBe(10000)
  })

  test("telemetry configuration", t => {
    t->expect(Constants.Telemetry.batchInterval)->Expect.toBe(5000)
    t->expect(Constants.Telemetry.batchSize)->Expect.toBe(50)
    t->expect(Constants.Telemetry.queueMaxSize)->Expect.toBe(1000)
    t->expect(Constants.Telemetry.retryMaxAttempts)->Expect.toBe(3)
    t->expect(Constants.Telemetry.retryBackoffMs)->Expect.toBe(1000)
  })

  test("system utilities", t => {
    t->expect(Constants.isTestEnvironment())->Expect.toBe(true)

    let _ = Constants.isDebugBuild()
    let _ = Constants.enableStateInspector()
    t->expect(true)->Expect.toBe(true)
  })
})
