// @efficiency: infra-adapter
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
    targetSceneId: None,
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
    let logoFilename = Some("logo.png")
    let exportType = "4k"
    let baseSize = 4000
    let logoSize = 150
    let version = "1.0.0"

    let html = generateTourHTML(
      [mockScene1, mockScene2],
      tourName,
      logoFilename,
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
    let html = generateTourHTML([autoScene], "Auto Tour", None, "hd", 2000, 100, "1.0")
    t->expectToContain(html, "\"isAutoForward\":true")
  })

  test("delegated functions exist and return strings", t => {
    let embed = generateEmbedCodes("MyTour", "1.0")
    t->expectToContain(embed, "iframe")
    t->expectToContain(embed, "MyTour")

    let index = generateExportIndex("MyTour", "1.0", None)
    t->expectToContain(index, "MyTour")
    t->expectToContain(index, "viewport")
  })

  test("generateTourHTML integrates correct CSS for 4k", t => {
    let html = generateTourHTML([mockScene1], "4k Tour", None, "4k", 32, 40, "1.0")
    // 4k max-width is 1024px
    t->expectToContain(html, "max-width: 1024px")
  })

  test("generateTourHTML integrates correct CSS for hd (mobile)", t => {
    let html = generateTourHTML([mockScene1], "HD Tour", None, "hd", 32, 40, "1.0")
    t->expectToContain(html, "width: clamp(375px, 95vw, 640px)")
    t->expectToContain(html, "\"minHfov\":65")
    t->expectToContain(html, "\"maxHfov\":90")
  })
})
