open ReBindings
open TourTemplateAssets

let run = () => {
  Console.log("Running TourTemplateAssets tests...")
  let index = generateExportIndex("TestTour", "1.0.0")
  assert(String.includes(index, "TestTour"))
  assert(String.includes(index, "1.0.0"))
  Console.log("✓ TourTemplateAssets: generateExportIndex verified")
}
