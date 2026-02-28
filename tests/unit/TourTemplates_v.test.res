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
    viewFrame: Some(mockViewFrame),
    waypoints: None,
    displayPitch: Some(5.0),
    transition: None,
    duration: None,
    isAutoForward: None,
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
    sequenceId: 0,
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
    sequenceId: 0,
  }

  let mockScene3Auto: scene = {
    ...mockScene2,
    id: "sc3",
    name: "scene3",
    label: "Auto Scene",
    isAutoForward: true,
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
    t->expectToContain(html, "assets/logo/logo.png")

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
    t->expectToContain(html, "\"autoForwardHotspotIndex\":-1")
    t->expectToContain(html, "\"autoForwardTargetSceneId\":\"\"")
  })

  test("generateTourHTML keeps first-scene data URI fallback valid in CSS", t => {
    let inlineScene = {
      ...mockScene1,
      name: "data:image/webp;base64,AAAA",
      hotspots: [],
    }
    let html = generateTourHTML([inlineScene], "Inline Scene Tour", None, "2k", 32, 40, "1.0")
    t->expectToContain(html, "background-image: url(\"data:image/webp;base64,AAAA\")")
    t->expect(String.includes(html, "background-image: url(\"../../data:image"))->Expect.toBe(false)
  })

  test("generateTourHTML precomputes direct auto-forward route from double-chevron hotspot", t => {
    let hotspotToScene3 = {
      ...mockHotspot,
      linkId: "link-to-sc3",
      target: "scene3",
      targetSceneId: Some("sc3"),
      isAutoForward: Some(true),
    }
    let middleScene = {...mockScene2, hotspots: [hotspotToScene3], isAutoForward: false}
    let html = generateTourHTML(
      [mockScene1, middleScene, mockScene3Auto],
      "Route Tour",
      None,
      "4k",
      32,
      40,
      "1.0",
    )
    t->expectToContain(html, "\"autoForwardHotspotIndex\":0")
    t->expectToContain(html, "\"autoForwardTargetSceneId\":\"sc3\"")
  })

  test("generateTourHTML keeps two-state hotspot icon rendering", t => {
    let autoHotspot = {
      ...mockHotspot,
      linkId: "auto-link",
      target: "scene2",
      targetSceneId: Some("sc2"),
      isAutoForward: Some(true),
    }
    let sourceScene = {...mockScene1, hotspots: [autoHotspot]}
    let html = generateTourHTML(
      [sourceScene, mockScene2],
      "Icons Tour",
      None,
      "hd",
      2000,
      100,
      "1.0",
    )
    t->expectToContain(html, "\"targetIsAutoForward\":true")
    t->expectToContain(html, "if (isAutoForwardVisual)")
    t->expectToContain(html, "M6 17 L11 12 L6 7")
    t->expectToContain(html, "M6 14 L12 8 L18 14")
  })

  test("generateTourHTML auto-advance uses explicit route metadata only", t => {
    let html = generateTourHTML([mockScene1, mockScene2], "Runtime Tour", None, "4k", 32, 40, "1.0")
    t->expectToContain(html, "function resolveScenePlaybackHotspot(sceneId, sceneData)")
    t->expectToContain(
      html,
      "function attemptAutoForwardNavigation(sceneId, playbackTarget, retriesLeft, destinationOverride)",
    )
    // New priority-based link selection
    t->expectToContain(html, "// PRIORITY 1: Unvisited, non-return, non-auto-forward (explore)")
    t->expectToContain(
      html,
      "// PRIORITY 2: Unvisited, non-return, IS auto-forward (exit - taken LAST)",
    )
    t->expectToContain(
      html,
      "const p1 = resolvedHotspots.find(h => !h.hotspot.__visited && !h.isReturn && !h.isAutoForward)",
    )
    t->expectToContain(
      html,
      "const p2 = resolvedHotspots.find(h => !h.hotspot.__visited && !h.isReturn && h.isAutoForward)",
    )
    t->expectToContain(html, "const isAutoForward = playbackTarget.autoForward === true;")
    t->expectToContain(html, "function resolveDestinationView(args, options)")
    t->expectToContain(html, "if (Number.isFinite(options?.destinationOverride?.yaw)")
    t->expectToContain(html, "function resolveAutoForwardArrivalView(sceneId)")
    t->expectToContain(
      html,
      "const destinationOverride = options?.destinationOverride ?? resolveAutoForwardArrivalView(targetSceneId);",
    )
    t->expectToContain(html, "function getPlaybackTerminalView(primary)")
    t->expectToContain(html, "function snapToPlaybackTerminalView(terminalView)")
    t->expectToContain(html, "const terminalView = path.length > 0")
    t->expectToContain(html, "snapToPlaybackTerminalView(terminalView);")
    t
    ->expect(
      String.includes(
        html,
        "window.viewer.lookAt(primary.pitch, primary.yaw, getCurrentHfov(), false);",
      ),
    )
    ->Expect.toBe(false)
    t->expectToContain(
      html,
      "attemptAutoForwardNavigation(sceneId, playbackTarget, 16, terminalView)",
    )
    t->expectToContain(
      html,
      "navigateToNextScene(playbackTarget.hotspot, playbackTarget.targetSceneId, autoForwardOptions);",
    )
    t
    ->expect(String.includes(html, "const autoForward = primary.targetIsAutoForward === true;"))
    ->Expect.toBe(false)
  })

  test("generateTourHTML resolves arrival view from target auto-forward scene endpoint", t => {
    let html = generateTourHTML(
      [mockScene1, mockScene3Auto],
      "Target Endpoint Arrival",
      None,
      "4k",
      32,
      40,
      "1.0",
    )

    t->expectToContain(html, "function resolveAutoForwardArrivalView(sceneId)")
    t->expectToContain(html, "const sceneData = scenesData?.[resolvedSceneId];")
    t->expectToContain(html, "const hotspotIndex = sceneData?.autoForwardHotspotIndex;")
    t->expectToContain(html, "const hotspot = sceneData?.hotSpots?.[hotspotIndex];")
    t->expectToContain(html, "const yaw = Number.isFinite(hotspot?.viewFrame?.yaw)")
    t->expectToContain(html, "const pitch = Number.isFinite(hotspot?.viewFrame?.pitch)")
    t->expectToContain(
      html,
      "const destinationOverride = options?.destinationOverride ?? resolveAutoForwardArrivalView(targetSceneId);",
    )
    t
    ->expect(
      String.includes(
        html,
        "const destinationOverride = resolveAutoForwardArrivalView(args?.targetSceneId);",
      ),
    )
    ->Expect.toBe(false)
  })

  test("generateTourHTML does not infer auto-forward from scene-level flag alone", t => {
    let hotspotToScene2 = {
      ...mockHotspot,
      linkId: "manual-link",
      target: "scene2",
      targetSceneId: Some("sc2"),
      isAutoForward: None,
    }
    let sceneFlagOnly = {
      ...mockScene1,
      hotspots: [hotspotToScene2],
      isAutoForward: true,
    }
    let html = generateTourHTML(
      [sceneFlagOnly, mockScene2],
      "No Legacy Inference Tour",
      None,
      "hd",
      32,
      40,
      "1.0",
    )
    t->expectToContain(html, "\"isAutoForward\":true")
    t->expectToContain(html, "\"autoForwardHotspotIndex\":-1")
    t->expectToContain(html, "\"autoForwardTargetSceneId\":\"\"")
  })

  test(
    "generateTourHTML guards exported auto-forward loops and resets chain on manual navigation",
    t => {
      let autoHotspotA = {
        ...mockHotspot,
        linkId: "auto-a",
        target: "scene2",
        targetSceneId: Some("sc2"),
        isAutoForward: Some(true),
      }
      let autoHotspotB = {
        ...mockHotspot,
        linkId: "auto-b",
        target: "scene1",
        targetSceneId: Some("sc1"),
        isAutoForward: Some(true),
      }
      let autoSceneA = {...mockScene1, hotspots: [autoHotspotA], isAutoForward: true}
      let autoSceneB = {...mockScene2, hotspots: [autoHotspotB], isAutoForward: true}

      let html = generateTourHTML(
        [autoSceneA, autoSceneB],
        "Loop Guard Tour",
        None,
        "4k",
        32,
        40,
        "1.0",
      )

      t->expectToContain(html, "const AUTO_FORWARD_MAX_HOPS = 24;")
      t->expectToContain(html, "let autoForwardChainVisited = [];")
      t->expectToContain(html, "let autoForwardChainActive = false;")
      t->expectToContain(html, "function resetAutoForwardLoopGuard()")
      t->expectToContain(html, "function shouldBlockAutoForward(sourceSceneId, targetSceneId)")
      t->expectToContain(html, "if (sourceSceneId === targetSceneId) return true;")
      t->expectToContain(html, "return autoForwardChainVisited.includes(targetSceneId);")
      t->expectToContain(html, "if (shouldBlockAutoForward(sourceSceneId, targetSceneId))")
      t->expectToContain(html, "trackAutoForwardSource(sourceSceneId);")
      t->expectToContain(html, "const autoForwardOptions = {")
      t->expectToContain(html, "destinationOverride: destinationOverride ?? null,")
      t->expectToContain(html, "anyReady.__navigateNext(autoForwardOptions);")
      t->expectToContain(html, "hotSpotDiv.__navigateNext = function(options)")
    },
  )

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
    t->expectToContain(html, "width: 1024px")
    t->expectToContain(html, "body.export-state-tablet #stage { width: 640px")
  })

  test("generateTourHTML integrates correct CSS for hd (mobile)", t => {
    let html = generateTourHTML([mockScene1], "HD Tour", None, "hd", 32, 40, "1.0")
    t->expectToContain(html, "width: 640px")
    t->expectToContain(html, "body.export-state-tablet #viewer-floor-nav-export .floor-nav-btn")
    t->expectToContain(html, "body.export-state-portrait #stage")
    t->expectToContain(html, "\"minHfov\": 65")
    t->expectToContain(html, "\"maxHfov\": 90")
  })

  test("generateTourHTML includes session-based auto-forward expiration logic", t => {
    let html = generateTourHTML([mockScene1], "Expiration Tour", None, "hd", 32, 40, "1.0")

    // Check tracking variable
    t->expectToContain(html, "let visitedAutoForwards = new Set();")

    // Check expiration check in animation logic
    t->expectToContain(html, "const afKey = sceneId + \":\" + primaryIndex;")
    t->expectToContain(
      html,
      "const autoForwardAlreadyVisited = isAutoForward && visitedAutoForwards.has(afKey);",
    )
    t->expectToContain(
      html,
      "const shouldAutoForward = (isAutoForward && !autoForwardAlreadyVisited) || forceAutoForward;",
    )

    // Check marking as visited in animation
    t->expectToContain(html, "visitedAutoForwards.add(afKey);")

    // Check marking as visited in manual click
    t->expectToContain(html, "if (isAutoForwardConfig) {")
    t->expectToContain(html, "visitedAutoForwards.add(afKey);")

    // Check visual state logic in rendering
    t->expectToContain(
      html,
      "const isAutoForwardExpired = isAutoForwardConfig && visitedAutoForwards.has(afKey);",
    )
    t->expectToContain(
      html,
      "const isAutoForwardVisual = isAutoForwardConfig && !isHubScene && !isAutoForwardExpired;",
    )
  })

  test("generateTourHTML suppresses shortcut panel before auto-tour return-home transition", t => {
    let html = generateTourHTML(
      [mockScene1, mockScene2],
      "AutoTour Return Guard",
      None,
      "hd",
      32,
      40,
      "1.0",
    )

    t->expectToContain(html, "let suppressShortcutPanelUntilNextLoad = false;")
    t->expectToContain(html, "autoTourHomeReturnCountdownRemaining = 1;")
    t->expectToContain(html, "suppressShortcutPanelUntilNextLoad = true;")
    t->expectToContain(html, "if (suppressShortcutPanelUntilNextLoad) {")
    t->expectToContain(html, "clearExportFloorTagShortcuts(panel);")
    t->expectToContain(html, "suppressShortcutPanelUntilNextLoad = false;")
  })

  test("generateTourHTML keeps map exit row aligned with map shortcut grid", t => {
    let html = generateTourHTML(
      [mockScene1, mockScene2],
      "Map Exit Row Layout",
      None,
      "hd",
      32,
      40,
      "1.0",
    )

    t->expectToContain(html, "grid-template-columns: 8px 1.1em auto;")
    t->expectToContain(html, "exitIndicatorEl.className = \"shortcut-indicator-spacer\";")
    t->expectToContain(html, "exitRow.appendChild(exitIndicatorEl);")
    t->expectToContain(html, "exitTextEl.textContent = \"exit map mode\";")
  })

  test("generateTourHTML map shortcuts keep basement aliases and row navigation wiring", t => {
    let html = generateTourHTML(
      [mockScene1, mockScene2],
      "Map Shortcuts Wiring",
      None,
      "hd",
      32,
      40,
      "1.0",
    )

    t->expectToContain(html, "{ id: \"b1\", shortcut: \"b\", mapLabel: \"Basement level -1\" }")
    t->expectToContain(html, "{ id: \"b2\", shortcut: \"z\", mapLabel: \"Basement level -2\" }")
    t->expectToContain(html, "const mapShortcutKey = key.toLowerCase();")
    t->expectToContain(
      html,
      "const didNavigateToMapScene = navigateExportMapShortcut(mapShortcutKey);",
    )
    t->expectToContain(
      html,
      "navigateToFloorTagShortcut(entry.sceneId, { fromMap: true, mapSelectedRow: row });",
    )
    t->expectToContain(html, "if (currentSceneId && entry.sceneId === currentSceneId) return true;")
  })

  test("generateTourHTML renders marketing banner with configured chips", t => {
    let html = generateTourHTML(
      [mockScene1],
      "Marketing Banner",
      None,
      "4k",
      32,
      40,
      "1.0",
      ~marketingBody="For more info call: 01012345678 / 01087654321",
      ~marketingShowRent=true,
      ~marketingShowSale=true,
    )

    t->expectToContain(html, "viewer-marketing-banner-export")
    t->expectToContain(html, "viewer-marketing-chip-rent-export")
    t->expectToContain(html, "viewer-marketing-chip-sale-export")
    t->expectToContain(html, "For more info call: 01012345678 / 01087654321")
  })

  test("generateTourHTML escapes marketing text before injecting into export HTML", t => {
    let html = generateTourHTML(
      [mockScene1],
      "Marketing Escape",
      None,
      "hd",
      32,
      40,
      "1.0",
      ~marketingBody="<script>alert('xss')</script>",
      ~marketingShowRent=false,
      ~marketingShowSale=false,
    )

    t->expectToContain(html, "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
    t->expect(String.includes(html, "<script>alert('xss')</script>"))->Expect.toBe(false)
  })
})
