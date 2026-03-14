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
    sequenceOrder: None,
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

  let countOccurrences = (str, sub) => str->String.split(sub)->Array.length - 1

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
    t->expectToContain(html, "id=\"export-watermark-image\"")
    t->expectToContain(html, "const LOGO_AREA_RATIO = 0.012;")
    t->expectToContain(html, "const EXPORT_TOUCH_PAN_SPEED_COEFF = 1.0;")
    t->expectToContain(html, "const EXPORT_TOUCH_RELEASE_MOMENTUM_FACTOR = 1.4;")
    t->expectToContain(html, "const LOGO_PORTRAIT_AREA_MULTIPLIER = 1.55;")
    t->expectToContain(html, "const LOGO_PORTRAIT_WIDTH_CAP_RATIO = 0.22;")
    t->expectToContain(html, "const LOGO_PORTRAIT_HEIGHT_CAP_RATIO = 0.12;")
    t->expectToContain(html, "function syncExportLogoSize()")
    t->expectToContain(html, "const portraitTargetArea =")
    t->expectToContain(html, "const portraitFinalWidth = Math.min(")
    t->expectToContain(html, "const portraitFinalHeight = Math.min(")
    t->expectToContain(html, "stage.style.setProperty('--export-logo-height'")
    t->expectToContain(html, "'--export-logo-portrait-height'")
    t->expectToContain(html, "\"touchPanSpeedCoeffFactor\": EXPORT_TOUCH_PAN_SPEED_COEFF")
    t->expectToContain(html, "\"touchReleaseMomentumFactor\": EXPORT_TOUCH_RELEASE_MOMENTUM_FACTOR")

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
      sequenceOrder: None,
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

  test("generateTourHTML renders in-hotspot text and simple fallback icon", t => {
    let autoHotspot = {
      ...mockHotspot,
      linkId: "auto-link",
      target: "scene2",
      targetSceneId: Some("sc2"),
      isAutoForward: Some(true),
      sequenceOrder: None,
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
    t->expectToContain(html, "\"sequenceNumber\":1")
    t->expectToContain(html, "\"targetSceneNumber\":2")
    t->expectToContain(html, "const faceText = isReturnLink ? \"R\"")
    t->expectToContain(html, "const dynamicSequenceEdge = !isReturnLink")
    t->expectToContain(
      html,
      "const resolvedSequenceNumber = dynamicSequenceFromEdge ?? sequenceFromArgs ?? sequenceFromOwner;",
    )
    t->expectToContain(html, "const textEl = document.createElement(\"span\");")
    t->expectToContain(html, "textEl.className = \"export-hotspot-face-text\"")
    t->expectToContain(html, "M6 14 L12 8 L18 14")
    t->expect(String.includes(html, "M6 17 L11 12 L6 7"))->Expect.toBe(false)
  })

  test(
    "generateTourHTML keeps wrap-back hotspots pointed at scene one for user-facing numbering",
    t => {
      let hotspotAB = {
        ...mockHotspot,
        linkId: "wrap-ab",
        target: "scene2",
        targetSceneId: Some("sc2"),
        sequenceOrder: None,
      }
      let hotspotBC = {
        ...mockHotspot,
        linkId: "wrap-bc",
        target: "scene3",
        targetSceneId: Some("sc3"),
        sequenceOrder: None,
      }
      let hotspotCA = {
        ...mockHotspot,
        linkId: "wrap-ca",
        target: "scene1",
        targetSceneId: Some("sc1"),
        sequenceOrder: None,
      }
      let sceneA = {...mockScene1, hotspots: [hotspotAB], label: "Entry"}
      let sceneB = {...mockScene2, hotspots: [hotspotBC], label: "Hall"}
      let sceneC = {
        ...mockScene3Auto,
        hotspots: [hotspotCA],
        isAutoForward: false,
        label: "Bedroom",
      }
      let html = generateTourHTML(
        [sceneA, sceneB, sceneC],
        "Wrap Scene Numbers",
        None,
        "hd",
        32,
        40,
        "1.0",
      )

      t->expectToContain(html, "\"sceneNumber\":1")
      t->expectToContain(html, "\"sceneNumber\":2")
      t->expectToContain(html, "\"sceneNumber\":3")
      t->expectToContain(html, "\"targetSceneNumber\":1")
    },
  )

  test("generateTourHTML auto-advance uses explicit route metadata only", t => {
    let html = generateTourHTML([mockScene1, mockScene2], "Runtime Tour", None, "4k", 32, 40, "1.0")
    t->expectToContain(html, "function resolveScenePlaybackHotspot(sceneId, sceneData)")
    t->expectToContain(html, "hotspots.forEach(h => { if (h) h.__visited = false; });")
    t->expectToContain(html, "\"sequenceEdges\"")
    t->expectToContain(html, "\"visibleHotspotIndex\":0")
    t->expectToContain(html, "const EXPORT_TRAVERSAL_MODE = \"canonical\";")
    t->expectToContain(html, "const defaultSceneSequenceCursorByScene = new Map();")
    t->expectToContain(html, "const sceneIdBySequencePosition = new Map();")
    t->expectToContain(html, "const firstSequencePositionBySceneId = new Map();")
    t->expectToContain(
      html,
      "const currentSceneSequenceContext = { sceneId: null, sequenceCursor: null, sourceSceneId: null };",
    )
    t->expectToContain(html, "let pendingArrivalContext = null;")
    t->expectToContain(html, "function getCurrentSceneSequenceCursor(sceneId, sceneData)")
    t->expectToContain(html, "\"sceneNumber\":1")
    t->expectToContain(html, "const rawSceneNumber = scenesData?.[sid]?.sceneNumber;")
    t->expectToContain(html, "function buildSceneNumberRows()")
    t->expectToContain(html, "function navigateToSceneByNumberValue(chosen, options)")
    t->expectToContain(html, "if (homeSceneId) pushDefaultSceneSequenceCursor(homeSceneId, 0);")
    t->expectToContain(html, "pushSceneSequencePosition(targetSceneId, seqRaw + 1);")
    t->expectToContain(html, "function resolveSceneIdForSequencePosition(sequencePosition)")
    t->expectToContain(html, "function resolveFirstSequencePositionForScene(sceneId)")
    t->expectToContain(html, "function applyManualSequencePosition(sceneId, sequencePosition)")
    t->expectToContain(html, "const autoTourManifest = {\"steps\":")
    t->expectToContain(html, "let autoTourManifestCursor = 0;")
    t->expectToContain(html, "function resetAutoTourManifestCursor()")
    t->expectToContain(html, "function resolveAutoTourManifestStep(sceneId)")
    t->expectToContain(html, "function buildPlaybackTargetFromAutoTourStep(sceneId)")
    t->expectToContain(
      html,
      "if (resolvedSceneId && homeSceneId && autoTourManifestCursor > 0 && resolvedSceneId === homeSceneId) {",
    )
    t->expectToContain(html, "fromManifest: true,")
    t->expectToContain(html, "const manifestPlaybackTarget =")
    t->expectToContain(
      html,
      "window.isAutoTourActive === true ? buildPlaybackTargetFromAutoTourStep(sceneId) : null;",
    )
    t->expectToContain(html, "if (window.isAutoTourActive === true) {")
    t->expectToContain(html, "return null;")
    t->expectToContain(
      html,
      "const requestedSequenceCursor = Number.isInteger(options?.sequenceCursorOverride)",
    )
    t->expectToContain(html, "const sequenceCursor = requestedSequenceCursor;")
    t->expectToContain(html, "if (playbackTarget.fromManifest === true) {")
    t->expectToContain(
      html,
      "const didAdvance = advanceAutoTourManifestCursor(sceneId, playbackTarget.targetSceneId);",
    )
    let manifestDeclIndex = String.indexOf(html, "const autoTourManifest = {\"steps\":")
    let manifestUsageIndex = String.indexOf(
      html,
      "const autoTourSteps = Array.isArray(autoTourManifest?.steps) ? autoTourManifest.steps : [];",
    )
    t->expect(manifestDeclIndex >= 0)->Expect.toBe(true)
    t->expect(manifestUsageIndex > manifestDeclIndex)->Expect.toBe(true)
    t->expectToContain(html, "function resolveNextForwardSequenceEdge(sceneId, sceneData)")
    t->expectToContain(
      html,
      "function resolveSequenceEdgeForVisibleHotspot(sceneId, sceneData, visibleHotspotIndex)",
    )
    t->expectToContain(
      html,
      "function resolveForwardHotspotByTargetScene(sceneId, sceneData, targetSceneId)",
    )
    t->expectToContain(html, "function resolvePreviousSequenceTarget(sceneId, sceneData)")
    t->expectToContain(html, "function resolveDeadEndExitHotspot(sceneId, sceneData)")
    t->expectToContain(html, "function resolvePostArrivalFocusHotspot(sceneId, sceneData)")
    t->expectToContain(
      html,
      "function resolveHotspotByTargetScene(sceneId, sceneData, targetSceneId, options)",
    )
    t->expectToContain(
      html,
      "function resolveArrivalReferenceHotspot(sceneId, sceneData, sourceSceneId)",
    )
    t->expectToContain(
      html,
      "function resolveSourceBacktrackTarget(sceneId, sceneData, sourceSceneId, sequenceCursorOverride)",
    )
    t->expectToContain(html, "function resolveStableSceneNumber(sceneId)")
    t->expectToContain(html, "function buildCurrentCursorBacktrackTarget(")
    t->expectToContain(html, "function resolveSceneNumberForwardShortcutTarget(sceneId, sceneData)")
    t->expectToContain(
      html,
      "function resolveSceneNumberBacktrackShortcutTarget(sceneId, sceneData)",
    )
    t->expectToContain(
      html,
      "function resolveProgressAwareForwardShortcutTarget(sceneId, sceneData)",
    )
    t->expectToContain(html, "function resolveShortcutNavigationTargets(sceneId, sceneData)")
    t->expectToContain(html, "const rawSceneNumber = scenesData?.[resolvedSceneId]?.sceneNumber;")
    t->expectToContain(
      html,
      "const currentCursor = getCurrentSceneSequenceCursor(resolvedSceneId, sceneData);",
    )
    t->expectToContain(html, "if (resolvedSceneId === homeSceneId) {")
    t->expectToContain(
      html,
      "return resolveSceneNumberForwardShortcutTarget(resolvedSceneId, sceneData);",
    )
    t->expectToContain(
      html,
      "const nextForwardEdge = resolveNextForwardSequenceEdge(resolvedSceneId, sceneData);",
    )
    t->expectToContain(
      html,
      "const preferredTarget = resolvePreferredNavigationTarget(resolvedSceneId, sceneData);",
    )
    t->expectToContain(html, "preferredTarget.usesReturnLink !== true")
    t->expectToContain(html, "if (!nextForwardEdge) {")
    t->expectToContain(html, "return preferredTarget;")
    t->expectToContain(html, "return buildCurrentCursorBacktrackTarget(")
    t->expectToContain(
      html,
      "const nextTarget = resolveProgressAwareForwardShortcutTarget(resolvedSceneId, sceneData);",
    )
    t->expectToContain(html, "resolvedSceneId === homeSceneId || stableSceneNumber <= 1")
    t->expectToContain(
      html,
      "const previousSceneId = resolveSceneIdForSequencePosition(previousSequencePosition);",
    )
    t->expectToContain(html, "function navigateToNextSequenceShortcut()")
    t->expectToContain(html, "function navigateToPreviousSequenceShortcut()")
    t->expectToContain(html, "navigateToFloorTagShortcut(")
    t->expectToContain(html, "navigateToFloorTagShortcut(targetEntry.sceneId, options);")
    t->expectToContain(
      html,
      "const shortcutTargets = resolveShortcutNavigationTargets(sceneId, currentSceneData);",
    )
    t->expectToContain(html, "const nextTarget = shortcutTargets?.nextTarget ?? null;")
    t->expectToContain(html, "const prevTarget = shortcutTargets?.prevTarget ?? null;")
    t->expectToContain(html, "const nextSceneId = nextTarget?.targetSceneId ?? null;")
    t->expectToContain(html, "const prevSceneId = prevTarget?.targetSceneId ?? null;")
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
    t->expectToContain(html, "animatedScenes.add(sceneId);")
    t->expectToContain(html, "const EXPORT_WAYPOINT_ANIMATION_POLICY = \"auto-tour-only\";")
    t->expectToContain(html, "const EXPORT_DEFAULT_NAVIGATION_MODE = EXPORT_NAVIGATION_MODE_SEMI_AUTO;")
    t->expectToContain(html, "const MANUAL_POST_ARRIVAL_FOCUS_MS = 320.0;")
    t->expectToContain(html, "function resolveDestinationView(args, options)")
    t->expectToContain(html, "if (Number.isFinite(options?.destinationOverride?.yaw)")
    t->expectToContain(html, "function resolveAutoForwardArrivalView(sceneId)")
    t->expectToContain(
      html,
      "const destinationOverride = options?.destinationOverride ?? resolveAutoForwardArrivalView(targetSceneId);",
    )
    t->expectToContain(html, "function getPlaybackTerminalView(primary)")
    t->expectToContain(html, "function snapToPlaybackTerminalView(terminalView)")
    t->expectToContain(html, "function getHotspotFocusView(hotspot)")
    t->expectToContain(html, "function shouldAnimateExportArrivalPlayback()")
    t->expectToContain(html, "typeof isSemiAutoExportNavigationMode === \"function\"")
    t->expectToContain(html, "isSemiAutoExportNavigationMode()")
    t->expectToContain(html, "return EXPORT_WAYPOINT_ANIMATION_POLICY === \"always\";")
    t->expectToContain(html, "function syncPortraitModeSelectorClasses()")
    t->expectToContain(html, "body.classList.add(\"export-portrait-mode-intro\");")
    t->expectToContain(html, "panel.classList.add(\"is-portrait-mode-selector\");")
    t->expectToContain(html, "Choose tour mode:")
    t->expectToContain(html, "mode-shortcut-key mode-shortcut-key-inline")
    t->expectToContain(html, "if (interactionShell !== \"classic\") return false;")
    t->expectToContain(
      html,
      "const focusDurationMs = Number.isFinite(options?.durationMs) && options.durationMs > 0",
    )
    t->expectToContain(
      html,
      "function animateFocusPan(sceneId, startYaw, targetYaw, startPitch, targetPitch, durationMs, onComplete)",
    )
    t->expectToContain(
      html,
      "const postArrivalHotspot = resolvePostArrivalFocusHotspot(sceneId, sd);",
    )
    t->expectToContain(
      html,
      "const postArrivalFocusView = getHotspotFocusView(postArrivalHotspot);",
    )
    t->expectToContain(
      html,
      "const shouldAnimateArrivalPlayback = shouldAnimateExportArrivalPlayback();",
    )
    t->expectToContain(
      html,
      "const shouldAutoForwardWithoutPlayback = isAutoForward && !autoForwardAlreadyVisited;",
    )
    t->expectToContain(html, "if (!shouldAnimateArrivalPlayback) {")
    t->expectToContain(html, "durationMs: MANUAL_POST_ARRIVAL_FOCUS_MS,")
    t->expectToContain(html, "const arrivalReferenceHotspot = arrivalContext")
    t->expectToContain(html, "const startYaw = arrivalReferenceHotspot")
    t->expectToContain(html, "? normalizeYaw(arrivalReferenceHotspot.hotspot.yaw + 180)")
    t->expectToContain(
      html,
      "const yawDelta = Math.abs(normalizeYawDelta(startYaw, postArrivalFocusView.yaw));",
    )
    t->expectToContain(
      html,
      "const pitchDelta = Math.abs(postArrivalFocusView.pitch - currentPitch);",
    )
    t->expectToContain(html, "if (yawDelta <= 0.5 && pitchDelta <= 0.5) {")
    t->expectToContain(
      html,
      "window.viewer.lookAt(postArrivalFocusView.pitch, postArrivalFocusView.yaw, getCurrentHfov(), false);",
    )
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
    t->expectToContain(
      html,
      "const requestedSequenceCursor = Number.isInteger(options?.sequenceCursorOverride)",
    )
    t->expectToContain(html, "const sequenceCursor = requestedSequenceCursor;")
    t->expectToContain(
      html,
      "pendingArrivalContext = {sourceSceneId, targetSceneId, sequenceCursor}",
    )
    t->expectToContain(html, "function focusSceneOnPreferredHotspot(sceneId, options)")
    t->expectToContain(html, "if (typeof onComplete === \"function\") onComplete();")
    t->expectToContain(html, "const prevSequenceNumber = floorTagShortcutState.prevSequenceNumber;")
    t->expectToContain(html, "sequenceCursorOverride: prevSequenceNumber,")
    t->expectToContain(html, "floorTagShortcutState.prevSequenceNumber = null;")
    t->expectToContain(
      html,
      "floorTagShortcutState.prevSequenceNumber = prevSceneId ? prevTarget.sequenceCursorOverride : null;",
    )
    t->expectToContain(
      html,
      "floorTagShortcutState.prevUsesReturnLink = prevSceneId ? prevTarget?.usesReturnLink === true : false;",
    )
    t
    ->expect(
      String.includes(
        html,
        "function animateHorizontalPan(sceneId, startYaw, targetYaw, pitch, durationMs)",
      ),
    )
    ->Expect.toBe(false)
    t
    ->expect(
      String.includes(
        html,
        "const nextSceneId = nextForwardEdge ? nextForwardEdge.targetSceneId : null;",
      ),
    )
    ->Expect.toBe(false)
    t
    ->expect(
      String.includes(
        html,
        "const nextForwardHotspot = resolveVisibleHotspotForSequenceEdge(currentSceneData, nextForwardEdge);",
      ),
    )
    ->Expect.toBe(false)
    t
    ->expect(
      String.includes(html, "const oppositeYaw = normalizeYaw(entryHotspot.hotspot.yaw + 180);"),
    )
    ->Expect.toBe(false)
    t->expectToContain(html, "const currentYaw = typeof window.viewer.getYaw === \"function\"")
    t
    ->expect(String.includes(html, "const autoForward = primary.targetIsAutoForward === true;"))
    ->Expect.toBe(false)
  })

  test("generateTourHTML collapses duplicate published hotspots to the same destination", t => {
    let revisitHotspotA = {
      ...mockHotspot,
      linkId: "revisit-link-1",
      target: "scene2",
      targetSceneId: Some("sc2"),
      yaw: 22.5,
      pitch: 7.5,
      displayPitch: Some(7.5),
      startYaw: Some(15.0),
      startPitch: Some(-4.0),
      sequenceOrder: Some(1),
    }
    let revisitHotspotB = {
      ...mockHotspot,
      linkId: "revisit-link-2",
      target: "scene2",
      targetSceneId: Some("sc2"),
      yaw: 18.25,
      pitch: -3.0,
      displayPitch: Some(-3.0),
      startYaw: Some(-22.0),
      startPitch: Some(6.0),
      waypoints: Some([mockViewFrame]),
      sequenceOrder: Some(2),
    }
    let sourceScene = {...mockScene1, hotspots: [revisitHotspotA, revisitHotspotB]}
    let html = generateTourHTML(
      [sourceScene, mockScene2],
      "Deduped Revisit Tour",
      None,
      "hd",
      2000,
      100,
      "1.0",
    )
    let targetSignature = "\"target\":\"scene2\",\"targetSceneId\":\"sc2\",\"targetSceneNumber\":2,\"targetIsAutoForward\":false,\"isReturnLink\":false"

    t->expect(countOccurrences(html, targetSignature))->Expect.toBe(2)
    t->expectToContain(html, "\"hotSpots\":[{\"pitch\":7.5,\"yaw\":22.5")
    t->expectToContain(html, "\"linkId\":\"revisit-link-2\"")
    t->expectToContain(html, "\"yaw\":22.5")
    t->expect(String.includes(html, "\"yaw\":18.25"))->Expect.toBe(false)
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
      sequenceOrder: None,
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
        sequenceOrder: None,
      }
      let autoHotspotB = {
        ...mockHotspot,
        linkId: "auto-b",
        target: "scene1",
        targetSceneId: Some("sc1"),
        isAutoForward: Some(true),
        sequenceOrder: None,
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
      t->expectToContain(html, "const isAutoTourBacktrack =")
      t->expectToContain(html, "if (isAutoTourBacktrack) {")
      t->expectToContain(html, "resetAutoForwardLoopGuard();")
      t->expectToContain(html, "if (shouldBlockAutoForward(sourceSceneId, targetSceneId))")
      t->expectToContain(html, "trackAutoForwardSource(sourceSceneId);")
      t->expectToContain(html, "const autoForwardOptions = {")
      t->expectToContain(html, "destinationOverride: destinationOverride ?? null,")
      t->expectToContain(html, "usesReturnLink: playbackTarget.usesReturnLink === true,")
      t->expectToContain(html, "isBacktrack: playbackTarget.backtrack === true,")
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
    t->expect(String.includes(html, "body.export-state-tablet #stage { width: 640px"))->Expect.toBe(false)
  })

  test("generateTourHTML integrates correct CSS for hd (mobile)", t => {
    let html = generateTourHTML([mockScene1], "HD Tour", None, "hd", 32, 40, "1.0")
    t->expectToContain(html, "width: 640px")
    t->expectToContain(html, "body.is-hd-export #viewer-floor-nav-export .floor-nav-btn")
    t->expectToContain(html, "body.export-state-portrait #stage")
    t->expectToContain(html, "\"minHfov\": 65")
    t->expectToContain(html, "\"maxHfov\": 90")
  })

  test("generateTourHTML emits portrait export control hosts", t => {
    let html = generateTourHTML([mockScene1], "Touch Portrait Tour", None, "2k", 32, 40, "1.0")

    t->expectToContain(html, "id=\"viewer-portrait-mode-selector-export\"")
    t->expectToContain(html, "id=\"viewer-sequence-prompt-export\"")
    t->expectToContain(html, "id=\"viewer-floor-nav-export\"")
    t->expectToContain(html, "id=\"viewer-portrait-joystick-export\"")
    t->expectToContain(html, "function isPortraitAdaptiveExportUi()")
    t->expectToContain(html, "function renderPortraitAdaptiveShortcutPanel(panel)")
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
    t
    ->expect(
      String.includes(
        html,
        ".export-hotspot-root.auto-forward .export-hotspot-btn { background: #059669;",
      ),
    )
    ->Expect.toBe(false)
  })

  test("generateTourHTML wires export keyboard shortcut R to return link navigation", t => {
    let html = generateTourHTML(
      [mockScene1, mockScene2],
      "Return Shortcut Tour",
      None,
      "hd",
      32,
      40,
      "1.0",
    )
    t->expectToContain(html, "function resolveSceneReturnHotspot(sceneId)")
    t->expectToContain(html, "function navigateReturnHotspotFromCurrentScene()")
    t->expectToContain(html, "if (key === \"r\" || key === \"R\")")
    t->expectToContain(html, "const didNavigateReturn = navigateReturnHotspotFromCurrentScene();")
  })

  test("generateTourHTML keeps auto-forward behavior when link is classified as return", t => {
    let returnAutoHotspot = {
      ...mockHotspot,
      linkId: "return-auto-link",
      target: "scene2",
      targetSceneId: Some("sc2"),
      isAutoForward: Some(true),
      sequenceOrder: None,
    }
    let sourceScene = {...mockScene1, hotspots: [returnAutoHotspot]}
    let html = generateTourHTML(
      [sourceScene, mockScene2],
      "Return Auto Forward",
      None,
      "hd",
      32,
      40,
      "1.0",
    )
    t->expectToContain(html, "\"targetIsAutoForward\":true")
    t->expectToContain(
      html,
      "const shouldAutoForward = (isAutoForward && !autoForwardAlreadyVisited) || forceAutoForward;",
    )
    t->expectToContain(html, "if (isAutoForwardConfig) {")
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
    t->expectToContain(html, "function finishAutoTourAtScene(sceneId) {")
    t->expectToContain(html, "function resetHomeSceneCompletionSequence(sceneId) {")
    t->expectToContain(html, "applyManualSequencePosition(sceneId, 1);")
    t->expectToContain(html, "const restoreLookingMode = () => {")
    t->expectToContain(html, "const homeSceneId = resolveExistingSceneId(firstSceneId);")
    t->expectToContain(html, "const isAlreadyHome =")
    t->expectToContain(html, "if (isAlreadyHome) {")
    t->expectToContain(html, "resetHomeSceneCompletionSequence(activeSceneId);")
    t->expectToContain(html, "const finalizeCompletion = () => {")
    t->expectToContain(html, "finishAutoTourAtScene(activeSceneId);")
    t->expectToContain(html, "focusSceneOnPreferredHotspot(activeSceneId, {")
    t->expectToContain(html, "pauseLookingMode: true,")
    t->expectToContain(html, "onComplete: finalizeCompletion,")
    t->expectToContain(
      html,
      "if (homeSceneId && currentSceneId && currentSceneId === homeSceneId) {",
    )
    t->expectToContain(html, "resetHomeSceneCompletionSequence(homeSceneId);")
    t->expectToContain(html, "finishAutoTourAtScene(currentSceneId);")
    t->expectToContain(html, "animateSceneToPrimaryHotspot(homeSceneId, 20);")
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

    t->expectToContain(html, "grid-template-columns: 8px 1.1em minmax(0, 1fr);")
    t->expectToContain(html, "exitIndicatorEl.className = \"shortcut-indicator-arrow\";")
    t->expectToContain(html, "exitRow.appendChild(exitIndicatorEl);")
    t->expectToContain(html, "exitTextEl.textContent = \"Exit Map Mode\";")
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
    t->expectToContain(html, "jumpTextEl.textContent = \"Jump to Scene\";")
    t->expectToContain(html, "if (key === \"n\" || key === \"N\") {")
    t->expectToContain(html, "function navigateToSceneBySequenceInput() {")
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
