/* tests/unit/TourTemplates_v.test.res */
open Vitest
open Types
open TourTemplates

let _ = describe("TourTemplates", () => {
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
    file: Url(""),
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
  }

  let mockScene2: scene = {
    id: "sc2",
    name: "scene2",
    file: Url(""),
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
  }

  /* Helper to check containment */
  let expectToContain = (t, str, sub) => {
    t->expect(String.includes(str, sub))->Expect.toBe(true)
  }

  test("generateTourHTML builds correct HTML structure", t => {
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

    t->expectToContain(html, "<!DOCTYPE html>")
    t->expectToContain(html, `<title>${tourName}</title>`)
    t->expectToContain(html, "pannellum.js")
    t->expectToContain(html, "scene1")
    t->expectToContain(html, "scene2")
    t->expectToContain(html, "assets/images/scene1")
    t->expectToContain(html, "assets/images/scene2")
    t->expectToContain(html, "assets/logo.png")

    // Check hotspot data
    t->expectToContain(html, "\"yaw\":10")
    t->expectToContain(html, "\"pitch\":5")
    t->expectToContain(html, "\"target\":\"scene2\"")
    t->expectToContain(html, "\"floor\":\"1\"")
    t->expectToContain(html, "\"category\":\"Living Room\"")
    t->expectToContain(html, "\"isAutoForward\":false")
  })

  test("generateTourHTML handles AutoForward", t => {
    let autoScene = {...mockScene2, isAutoForward: true}
    let html = generateTourHTML([autoScene], "Auto Tour", false, "hd", 2000, 100, "1.0")
    t->expectToContain(html, "\"isAutoForward\":true")
  })

  test("delegated functions exist and return strings", t => {
    let embed = generateEmbedCodes("MyTour", "1.0")
    t->expectToContain(embed, "iframe")
    t->expectToContain(embed, "MyTour")

    let index = generateExportIndex("MyTour", "1.0")
    t->expectToContain(index, "MyTour")
    t->expectToContain(index, "viewport")
  })
})
