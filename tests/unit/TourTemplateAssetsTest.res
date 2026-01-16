open TourTemplateAssets

let run = () => {
  Console.log("Running TourTemplateAssets tests...")

  // Test generateExportIndex
  let index = generateExportIndex("Test_Tour", "1.2.3")
  assert(String.includes(index, "Test_Tour"))
  assert(String.includes(index, "Test Tour")) // Pretty name check (underscores to spaces)
  assert(String.includes(index, "1.2.3"))
  assert(String.includes(index, "Virtual Tour Hub"))
  Console.log("✓ TourTemplateAssets: generateExportIndex verified")

  // Test generateEmbedCodes
  let embed = generateEmbedCodes("TestTour", "2.0.0")
  assert(String.includes(embed, "TestTour"))
  assert(String.includes(embed, "2.0.0"))
  assert(String.includes(embed, "<iframe"))
  assert(String.includes(embed, "tour_4k/index.html"))
  assert(String.includes(embed, "tour_2k/index.html"))
  assert(String.includes(embed, "tour_hd/index.html"))
  Console.log("✓ TourTemplateAssets: generateEmbedCodes verified")
}
