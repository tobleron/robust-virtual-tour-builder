/* tests/unit/ProjectDataTest.res */
open ProjectData
open Types

let run = () => {
  Logger.info(~module_="ProjectDataTest", ~message="Running ProjectData tests...", ())

  // Test: version exists
  assert(VersionData.version != "")

  // Test: sanitizeLoadedScenes handles empty array
  let empty = sanitizeLoadedScenes([])
  assert(Belt.Array.length(empty) == 0)

  // Test: sanitizeLoadedScenes with minimal mock data (fallbacks)
  let mockMinimalScene = {
    "name": "Minimal Scene",
  }

  let sanitizedMin = sanitizeLoadedScenes([Obj.magic(mockMinimalScene)])
  assert(Belt.Array.length(sanitizedMin) == 1)
  let sMin = (Obj.magic(Belt.Array.getExn(sanitizedMin, 0)): {..})
  assert(sMin["id"] == "legacy_Minimal Scene")
  assert(sMin["category"] == "outdoor")
  assert(sMin["floor"] == "ground")
  assert(sMin["label"] == "")
  assert(sMin["isAutoForward"] == false)
  assert(Belt.Array.length(sMin["hotspots"]) == 0)

  // Test: sanitizeLoadedScenes with mock data
  let mockRawScene = {
    "id": "scene-unique",
    "name": "Test Scene",
    "category": "indoor",
    "floor": "2",
    "label": "Room A",
    "isAutoForward": true,
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
  assert(s["id"] == "scene-unique")
  assert(s["category"] == "indoor")
  assert(s["floor"] == "2")
  assert(s["label"] == "Room A")
  assert(s["isAutoForward"] == true)
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
            targetYaw: Some(90.0),
            targetPitch: Some(10.0),
            targetHfov: Some(100.0),
            startYaw: None,
            startPitch: None,
            startHfov: None,
            isReturnLink: Some(true),
            viewFrame: Some({yaw: 1.0, pitch: 2.0, hfov: 3.0}),
            returnViewFrame: None,
            waypoints: Some([{yaw: 1.0, pitch: 2.0, hfov: 3.0}]),
            displayPitch: Some(5.0),
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
    activeIndex: 5,
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
    deletedSceneIds: ["old-scene"],
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
    lastUsedCategory: "outdoor",
    sessionId: None,
  }

  let json = toJSON(mockState)
  let jsonDyn = (Obj.magic(json): {..})
  assert(jsonDyn["tourName"] == "Test Tour")
  assert(jsonDyn["activeIndex"] == 5)
  assert(Belt.Array.length(jsonDyn["deletedSceneIds"]) == 1)
  assert(Belt.Array.getExn(jsonDyn["deletedSceneIds"], 0) == "old-scene")

  let scenesDyn = (Obj.magic(jsonDyn["scenes"]): array<{..}>)
  assert(Belt.Array.length(scenesDyn) == 1)
  assert(Belt.Array.getExn(scenesDyn, 0)["id"] == "scene-1")
  assert(Belt.Array.getExn(scenesDyn, 0)["category"] == "cat")

  let hotspotsDyn = (Obj.magic(Belt.Array.getExn(scenesDyn, 0)["hotspots"]): array<{..}>)
  assert(Belt.Array.length(hotspotsDyn) == 1)
  let hDyn = Belt.Array.getExn(hotspotsDyn, 0)
  assert(hDyn["linkId"] == "link-1")
  assert(hDyn["targetYaw"] == Nullable.fromOption(Some(90.0)))
  assert(hDyn["isReturnLink"] == Nullable.fromOption(Some(true)))
  assert(hDyn["viewFrame"] == Nullable.fromOption(Some({yaw: 1.0, pitch: 2.0, hfov: 3.0})))
  assert(hDyn["displayPitch"] == Nullable.fromOption(Some(5.0)))

  Logger.info(~module_="ProjectDataTest", ~message="✓ ProjectData tests passed", ())
}
