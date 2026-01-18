/* tests/unit/ProjectDataTest.res */
open ProjectData

let run = () => {
  Console.log("Running ProjectData tests...")

  // Test: version exists
  assert(VersionData.version != "")

  // Test: sanitizeLoadedScenes handles empty array
  let empty = sanitizeLoadedScenes([])
  assert(Belt.Array.length(empty) == 0)

  // Test: sanitizeLoadedScenes with mock data
  let mockRawScene = {
    "name": "Test Scene",
    "hotspots": [
      {
        "pitch": 10.0,
        "yaw": 20.0,
        "target": "other-scene",
      },
    ],
  }

  let sanitized = sanitizeLoadedScenes([Obj.magic(mockRawScene)])
  assert(Belt.Array.length(sanitized) == 1)
  let s = (Obj.magic(Belt.Array.getExn(sanitized, 0)): {..})
  assert(s["name"] == "Test Scene")
  assert(s["id"] == "legacy_Test Scene")
  assert(s["category"] == "indoor") // Default
  assert(Belt.Array.length(s["hotspots"]) == 1)

  let h = (Obj.magic(Belt.Array.getExn(s["hotspots"], 0)): {..})
  assert(h["target"] == "other-scene")
  assert(h["linkId"] == "") // Default

  // Test: toJSON
  let mockState: Types.state = {
    tourName: "Test Tour",
    scenes: [
      {
        id: "scene-1",
        name: "Scene 1",
        file: Obj.magic(1),
        tinyFile: None,
        originalFile: None,
        hotspots: [
          {
            linkId: "link-1",
            yaw: 1.0,
            pitch: 2.0,
            target: "scene-2",
            targetYaw: None,
            targetPitch: None,
            targetHfov: None,
            startYaw: None,
            startPitch: None,
            startHfov: None,
            isReturnLink: None,
            viewFrame: None,
            returnViewFrame: None,
            waypoints: None,
            displayPitch: None,
            transition: None,
            duration: None,
          },
        ],
        category: "cat",
        floor: "1",
        label: "lab",
        quality: None,
        colorGroup: None,
        _metadataSource: "user",
        categorySet: true,
        labelSet: true,
        isAutoForward: false,
        preCalculatedSnapshot: None,
      },
    ],
    activeIndex: 0,
    activeYaw: 0.0,
    activePitch: 0.0,
    isLinking: false,
    transition: {
      type_: None,
      targetHotspotIndex: -1,
      fromSceneName: None,
    },
    lastUploadReport: {success: [], skipped: []},
    exifReport: None,
    linkDraft: None,
    preloadingSceneIndex: -1,
    isTeasing: false,
    deletedSceneIds: [],
    timeline: [],
    activeTimelineStepId: None,
    navigation: Idle,
    simulation: {
      status: Idle,
      visitedScenes: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
      lastAdvanceTime: 0.0,
      pendingAdvanceId: None,
      autoPilotJourneyId: 0,
    },
    incomingLink: None,
    autoForwardChain: [],
    pendingReturnSceneName: None,
    currentJourneyId: 0,
  }

  let json = toJSON(mockState)
  let jsonDyn = (Obj.magic(json): {..})
  assert(jsonDyn["tourName"] == "Test Tour")

  let scenesDyn = (Obj.magic(jsonDyn["scenes"]): array<{..}>)
  assert(Belt.Array.length(scenesDyn) == 1)
  assert(Belt.Array.getExn(scenesDyn, 0)["id"] == "scene-1")

  let hotspotsDyn = (Obj.magic(Belt.Array.getExn(scenesDyn, 0)["hotspots"]): array<{..}>)
  assert(Belt.Array.length(hotspotsDyn) == 1)
  assert(Belt.Array.getExn(hotspotsDyn, 0)["linkId"] == "link-1")

  Console.log("✓ ProjectData tests passed")
}
