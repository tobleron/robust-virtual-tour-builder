open Types
open TourTemplates

let run = () => {
  Console.log("Running TourTemplates tests...")

  let mockViewFrame: viewFrame = {
    yaw: 0.0,
    pitch: 0.0,
    hfov: 90.0,
  }

  let mockHotspot: hotspot = {
    linkId: "link1",
    yaw: 10.0,
    pitch: 5.0,
    target: "scene2",
    targetYaw: Some(0.0),
    targetPitch: Some(0.0),
    targetHfov: Some(90.0),
    startYaw: None,
    startPitch: None,
    startHfov: None,
    isReturnLink: Some(false),
    viewFrame: Some(mockViewFrame),
    returnViewFrame: None,
    waypoints: None,
    displayPitch: Some(5.0),
    transition: None,
    duration: None,
  }

  let mockScene1: scene = {
    id: "sc1",
    name: "scene1",
    file: JSON.Object(Dict.make()),
    tinyFile: None,
    originalFile: None,
    hotspots: [mockHotspot],
    category: "Living Room",
    floor: "1",
    label: "Main Entry",
    quality: None,
    colorGroup: None,
    _metadataSource: "test",
    categorySet: true,
    labelSet: true,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  let mockScene2: scene = {
    id: "sc2",
    name: "scene2",
    file: JSON.Object(Dict.make()),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "Kitchen",
    floor: "1",
    label: "Kitchen Area",
    quality: None,
    colorGroup: None,
    _metadataSource: "test",
    categorySet: true,
    labelSet: true,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  let assertContains = (str, substr) => {
    if !String.includes(str, substr) {
      Console.error(`Expected string to contain "${substr}", but it didn't.`)
      // Don't log full string if it's huge, but here it's fine for debugging
      // Console.log(`String content: ${str}`)
      assert(false)
    }
  }

  Console.log("Test: generateTourHTML basic structure")
  let tourName = "My Awesome Tour"
  let hasLogo = true
  let exportType = "4k"
  let baseSize = 4000
  let logoSize = 150
  let version = "1.0.0"

  let html = generateTourHTML(
    [mockScene1, mockScene2],
    tourName,
    hasLogo,
    exportType,
    baseSize,
    logoSize,
    version,
  )

  assertContains(html, "<!DOCTYPE html>")
  assertContains(html, `<title>${tourName}</title>`)
  assertContains(html, "pannellum.js")
  assertContains(html, "scene1")
  assertContains(html, "scene2")
  assertContains(html, "assets/images/scene1")
  assertContains(html, "assets/images/scene2")
  assertContains(html, "assets/logo.png")

  // Verify Hotspot data presence
  // Note: JSON.stringify encoding behavior checks
  assertContains(html, "\"yaw\":10")
  assertContains(html, "\"pitch\":5")
  assertContains(html, "\"target\":\"scene2\"")

  Console.log("Test: generateTourHTML with no logo")
  let htmlNoLogo = generateTourHTML(
    [mockScene1],
    tourName,
    false,
    exportType,
    baseSize,
    logoSize,
    version,
  )

  assertContains(html, "assets/logo.png") // Original had it
  if String.includes(htmlNoLogo, "assets/logo.png") {
    Console.error("Expected htmlNoLogo to NOT contain logo, but it did.")
    assert(false)
  }

  Console.log("✓ TourTemplates tests pass")
}
