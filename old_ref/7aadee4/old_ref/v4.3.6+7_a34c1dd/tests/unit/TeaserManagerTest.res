open TeaserManager

let run = () => {
  Console.log("Running TeaserManager tests...")

  // Verify configurations
  assert(fastConfig.clipDuration == 2500.0)
  assert(slowConfig.clipDuration == 4000.0)
  assert(punchyConfig.clipDuration == 1800.0)

  assert(fastConfig.transitionDuration == 1000.0)
  assert(slowConfig.transitionDuration == 1500.0)
  assert(punchyConfig.transitionDuration == 600.0)

  assert(fastConfig.cameraPanOffset == 20.0)
  assert(slowConfig.cameraPanOffset == 30.0)
  assert(punchyConfig.cameraPanOffset == 0.0)

  Console.log("✓ TeaserManager: Configurations verified")
}
