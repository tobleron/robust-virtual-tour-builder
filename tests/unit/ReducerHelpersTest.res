/* tests/unit/ReducerJsonTest.res */
open Types
open ReducerHelpers

let run = () => {
  Console.log("Running ReducerHelpers tests (Obj.magic elimination verification)...")

  // Test 1: Full structure with hotspots and duration
  let json = JSON.parseOrThrow(`{
    "tourName": "Full Project",
    "scenes": [
      {
        "id": "s1",
        "name": "s1.webp",
        "file": {"some": "file"},
        "hotspots": [
           {
             "linkId": "h1",
             "yaw": 10.0,
             "pitch": 20.0,
             "target": "s2.webp",
             "duration": 500,
             "viewFrame": {"yaw": 1.0, "pitch": 2.0, "hfov": 90.0}
           }
        ]
      }
    ]
  }`)

  let state = parseProject(json)
  assert(state.tourName == "Full Project")

  let s1 = Belt.Array.getExn(state.scenes, 0)
  assert(s1.id == "s1")

  let h1 = Belt.Array.getExn(s1.hotspots, 0)
  assert(h1.linkId == "h1")
  assert(h1.yaw == 10.0)

  // Verify duration int conversion
  switch h1.duration {
  | Some(d) => assert(d == 500)
  | None => Console.error("Expected duration 500")
  }

  // Verify viewFrame
  switch h1.viewFrame {
  | Some(vf) =>
    // types: vf is viewFrame
    assert(vf.yaw == 1.0)
    assert(vf.pitch == 2.0)
  | None => Console.error("Expected viewFrame")
  }

  Console.log("✓ Parse full project structure")

  // Test 2: Missing optional fields
  let json2 = JSON.parseOrThrow(`{
    "scenes": [
      {
        "name": "min.webp",
        "file": "foo"
      }
    ]
  }`)

  let state2 = parseProject(json2)
  assert(state2.tourName == "Imported Tour") // Default
  let s2 = Belt.Array.getExn(state2.scenes, 0)
  assert(s2.id == "legacy_min.webp") // Fallback
  assert(Belt.Array.length(s2.hotspots) == 0)

  Console.log("✓ Parse minimal project structure")

  // Test 3: Timeline Item parsing
  let timelineJson = JSON.parseOrThrow(`{
    "id": "t1",
    "linkId": "l1",
    "sceneId": "s1",
    "targetScene": "s2",
    "transition": "fade",
    "duration": 1000
  }`)

  let item = parseTimelineItem(timelineJson)
  assert(item.id == "t1")
  assert(item.duration == 1000)

  Console.log("✓ Parse timeline item")

  // Test 4: insertAt helper
  let originalArr = [1, 2, 3]
  let inserted = insertAt(originalArr, 1, 99)
  assert(Belt.Array.length(inserted) == 4)
  assert(Belt.Array.getExn(inserted, 0) == 1)
  assert(Belt.Array.getExn(inserted, 1) == 99)
  assert(Belt.Array.getExn(inserted, 2) == 2)
  assert(Belt.Array.getExn(inserted, 3) == 3)

  let insertedAtStart = insertAt(originalArr, 0, 88)
  assert(Belt.Array.getExn(insertedAtStart, 0) == 88)

  Console.log("✓ insertAt helper")

  // Helpers for creating dummy data
  let makeDummyHotspot = (~target="target.webp", ()) => {
    linkId: "h1",
    yaw: 0.0,
    pitch: 0.0,
    target,
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
  }

  let makeDummyScene = (~id="id", ~name="name.webp", ~label="", ~hotspots=[], ()) => {
    id,
    name,
    file: Url("file"),
    tinyFile: None,
    originalFile: None,
    hotspots,
    category: "indoor",
    floor: "ground",
    label,
    quality: None,
    colorGroup: None,
    _metadataSource: "user",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  // Test 5: syncSceneNames
  let sceneA = makeDummyScene(
    ~id="a",
    ~name="old_a.webp",
    ~label="Living Room",
    ~hotspots=[makeDummyHotspot(~target="old_b.webp", ())],
    (),
  )
  let sceneB = makeDummyScene(~id="b", ~name="old_b.webp", ~label="Kitchen", ())

  let scenes = [sceneA, sceneB]
  let synced = syncSceneNames(scenes)

  let expectedNameA = TourLogic.computeSceneFilename(0, "Living Room")
  let expectedNameB = TourLogic.computeSceneFilename(1, "Kitchen")

  let syncedA = Belt.Array.getExn(synced, 0)
  let syncedB = Belt.Array.getExn(synced, 1)

  assert(syncedA.name == expectedNameA)
  assert(syncedB.name == expectedNameB)

  // Check hotspot target update in A
  let hs = Belt.Array.getExn(syncedA.hotspots, 0)
  assert(hs.target == expectedNameB)

  Console.log("✓ syncSceneNames logic")

  // Test 6: handleDeleteScene
  let stateWithScenes = {
    ...State.initialState,
    scenes: [
      makeDummyScene(
        ~id="s1",
        ~name="s1.webp",
        ~hotspots=[makeDummyHotspot(~target="s2.webp", ())],
        (),
      ),
      makeDummyScene(~id="s2", ~name="s2.webp", ()),
      makeDummyScene(~id="s3", ~name="s3.webp", ()),
    ],
    activeIndex: 1,
  }

  // Delete s2 (index 1)
  let stateAfterDelete = handleDeleteScene(stateWithScenes, 1)
  assert(Belt.Array.length(stateAfterDelete.scenes) == 2)
  assert(Belt.Array.getExn(stateAfterDelete.scenes, 0).id == "s1")
  assert(Belt.Array.getExn(stateAfterDelete.scenes, 1).id == "s3")

  // Check that hotspot in s1 pointing to s2 was removed
  let s1After = Belt.Array.getExn(stateAfterDelete.scenes, 0)
  assert(Belt.Array.length(s1After.hotspots) == 0)

  // Check deletedSceneIds
  assert(Belt.Array.some(stateAfterDelete.deletedSceneIds, id => id == "s2"))

  // Check activeIndex adjustment
  assert(stateAfterDelete.activeIndex == 1) // Should now point to s3 which was at 2

  Console.log("✓ handleDeleteScene logic")

  // Test 6b: handleDeleteScene Last Scene Robustness
  let stateWithOneScene = {
    ...State.initialState,
    scenes: [makeDummyScene(~id="last", ~name="last.webp", ())],
    activeIndex: 0,
    activeYaw: 45.0,
    activePitch: 10.0,
  }
  let stateAfterLastDelete = handleDeleteScene(stateWithOneScene, 0)
  assert(Belt.Array.length(stateAfterLastDelete.scenes) == 0)
  assert(stateAfterLastDelete.activeIndex == -1)
  assert(stateAfterLastDelete.activeYaw == 0.0)
  assert(stateAfterLastDelete.activePitch == 0.0)

  Console.log("✓ handleDeleteScene last scene robustness")

  // Test 7: handleAddScenes
  let stateBeforeAdd = {
    ...State.initialState,
    scenes: [makeDummyScene(~id="existing", ~name="a.webp", ())],
  }
  let newSceneJson = JSON.parseOrThrow(`{
    "id": "new",
    "name": "b.webp",
    "preview": "file_b"
  }`)

  let stateAfterAdd = handleAddScenes(stateBeforeAdd, [newSceneJson])
  assert(Belt.Array.length(stateAfterAdd.scenes) == 2)
  assert(Belt.Array.some(stateAfterAdd.scenes, s => s.id == "new"))

  Console.log("✓ handleAddScenes logic")

  // Test 7b: handleAddScenes First Load Robustness
  let stateEmptyWithMuckIndex = {
    ...State.initialState,
    scenes: [],
    activeIndex: 5, // Invalid but let's test robustness
    activeYaw: 45.0,
    activePitch: 10.0,
  }
  let stateAfterRobustAdd = handleAddScenes(stateEmptyWithMuckIndex, [newSceneJson])
  assert(Belt.Array.length(stateAfterRobustAdd.scenes) == 1)
  assert(stateAfterRobustAdd.activeIndex == 0)
  assert(stateAfterRobustAdd.activeYaw == 0.0)
  assert(stateAfterRobustAdd.activePitch == 0.0)

  Console.log("✓ handleAddScenes first load robustness")

  // Test 8: handleUpdateSceneMetadata
  let metaJson = JSON.parseOrThrow(`{
    "category": "outdoor",
    "floor": "roof"
  }`)
  let stateAfterMeta = handleUpdateSceneMetadata(stateWithScenes, 0, metaJson)
  let updatedS1 = Belt.Array.getExn(stateAfterMeta.scenes, 0)
  assert(updatedS1.category == "outdoor")
  assert(updatedS1.floor == "roof")

  Console.log("✓ handleUpdateSceneMetadata logic")

  // Test 9: handleUpdateTimelineStep
  let stateWithTimeline = {
    ...State.initialState,
    timeline: [
      {
        id: "step1",
        linkId: "l1",
        sceneId: "s1",
        targetScene: "s2",
        transition: "fade",
        duration: 1000,
      },
    ],
  }
  let stepUpdateJson = JSON.parseOrThrow(`{
    "transition": "zoom",
    "duration": 2000
  }`)
  let stateAfterStepUpdate = handleUpdateTimelineStep(stateWithTimeline, "step1", stepUpdateJson)
  let updatedStep = Belt.Array.getExn(stateAfterStepUpdate.timeline, 0)
  assert(updatedStep.transition == "zoom")
  assert(updatedStep.duration == 2000)

  Console.log("✓ handleUpdateTimelineStep logic")
}
