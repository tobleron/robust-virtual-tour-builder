/* tests/unit/ConstantsTest.res */

let run = () => {
  Console.log("Running Constants tests...")

  // Debug defaults
  assert(Constants.debugLogLevel == "debug")
  assert(Constants.debugMaxEntries == 500)
  assert(Constants.perfWarnThreshold == 500.0)
  Console.log("✓ Debug configuration defaults")

  // Teaser
  assert(Constants.Teaser.canvasWidth == 1920)
  assert(Constants.Teaser.canvasHeight == 1080)
  assert(Constants.Teaser.StyleDissolve.transitionDuration == 1000)
  assert(Constants.Teaser.StylePunchy.transitionDuration == 200)
  Console.log("✓ Teaser configuration")

  // Scene Floor Levels
  let levels = Constants.Scene.floorLevels
  assert(Belt.Array.length(levels) > 0)

  let ground = Belt.Array.getBy(levels, l => l.id == "ground")
  switch ground {
  | Some(g) =>
    assert(g.label == "Ground Floor")
    assert(g.short == "G")
  | None => assert(false)
  }

  let b1 = Belt.Array.getBy(levels, l => l.id == "b1")
  switch b1 {
  | Some(b) => assert(b.suffix == Some("-1"))
  | None => assert(false)
  }
  Console.log("✓ Scene Floor Levels")

  // Scene Room Labels
  let hasKitchen = Belt.Array.some(Constants.Scene.RoomLabels.indoor, x => x == "Kitchen")
  assert(hasKitchen)

  let hasGarden = Belt.Array.some(Constants.Scene.RoomLabels.outdoor, x => x == "Garden")
  assert(hasGarden)

  let indoorPreset = Dict.get(Constants.roomLabelPresets, "indoor")
  switch indoorPreset {
  | Some(_) => assert(true)
  | None => assert(false)
  }
  Console.log("✓ Scene Room Labels")

  // Backend
  assert(Constants.backendUrl == "http://localhost:8080")
  Console.log("✓ Backend configuration")

  // Environmental Utilities
  // These should run without error in the test environment
  let _ = Constants.isDebugBuild()
  let _ = Constants.enableStateInspector()
  Console.log("✓ Environmental Utilities execution")

  Console.log("Constants tests passed!")
}
