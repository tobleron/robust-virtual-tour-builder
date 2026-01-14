open ReBindings
open TourTemplateScripts

let run = () => {
  Console.log("Running TourTemplateScripts tests...")
  let script = generateRenderScript(32)
  assert(String.includes(script, "32px"))
  Console.log("✓ TourTemplateScripts: generateRenderScript verified")
}
