open ReBindings
open TourTemplateScripts

let run = () => {
  Console.log("Running TourTemplateScripts tests...")

  // Test generateRenderScript
  let script = generateRenderScript(32)
  assert(String.includes(script, "32px"))
  assert(String.includes(script, "renderGoldArrow"))
  assert(String.includes(script, "hotSpotDiv"))
  assert(String.includes(script, "window.viewer"))

  let scriptLarge = generateRenderScript(64)
  assert(String.includes(scriptLarge, "64px"))

  Console.log("✓ TourTemplateScripts: generateRenderScript verified")
}
