open Vitest
open SceneHelpers
open SceneMutations
open Types
open HotspotHelpers

describe("SceneHelpers", () => {
  // Helpers for creating dummy data
  let makeDummyHotspot = (~target="target.webp", ()) => {
    let hs: Types.hotspot = {
      linkId: "h1",
      yaw: 0.0,
      pitch: 0.0,
      target,
      targetSceneId: Some(target),
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      startYaw: None,
      startPitch: None,
      startHfov: None,
      viewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
      isAutoForward: None,
    }
    hs
  }

  let makeDummyScene = (
    ~id="id",
    ~name="name.webp",
    ~label="",
    ~hotspots=[],
    ~sequenceId=0,
    (),
  ) => {
    let sc: Types.scene = {
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
      sequenceId,
    }
    sc
  }

  let mockState = (
    ~scenes: array<Types.scene>=[],
    ~activeIndex=-1,
    ~appMode=Initializing,
    (),
  ): state => {
    let inventory = scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, s) => {
      acc->Belt.Map.String.set(s.id, {scene: s, status: Active})
    })
    let sceneOrder = scenes->Belt.Array.map(s => s.id)
    {
      ...State.initialState,
      inventory,
      sceneOrder,
      activeIndex,
      appMode,
    }
  }

  test("Parse full project structure with new fields", t => {
    let json = JSON.parseOrThrow(`{
      "tourName": "Full Project",
      "sessionId": "test-session",
      "exifReport": {"summary": "valid"},
      "scenes": [
        {
          "id": "s1",
          "name": "s1.webp",
          "file": "some/file/url",
          "isAutoForward": true,
          "hotspots": [
             {
               "linkId": "h1",
               "yaw": 10.0,
               "pitch": 20.0,
               "target": "s2.webp",
               "duration": 500,
               "viewFrame": {"yaw": 1.0, "pitch": 2.0, "hfov": 90.0},
               "waypoints": [
                 {"yaw": 5.0, "pitch": 5.0, "hfov": 95.0}
               ]
             }
          ]
        },
        {
          "id": "s2",
          "name": "s2.webp",
          "file": "foo"
        }
      ]
    }`)

    let projectResult = parseProject(json)
    let project = projectResult->Result.getOrThrow
    t->expect(project.tourName)->Expect.toEqual("Full Project")
    t->expect(project.sessionId)->Expect.toEqual(Some("test-session"))
    t->expect(project.exifReport)->Expect.toEqual(Some(JSON.parseOrThrow(`{"summary": "valid"}`)))

    let projectScenes = SceneInventory.getActiveScenes(project.inventory, project.sceneOrder)
    let s1: Types.scene = projectScenes[0]->Option.getOrThrow
    t->expect(s1.id)->Expect.toEqual("s1")
    t->expect(s1.isAutoForward)->Expect.toEqual(true)

    let h1 = s1.hotspots[0]->Option.getOrThrow
    t->expect(h1.linkId)->Expect.toEqual("h1")
    t->expect(h1.yaw)->Expect.toEqual(10.0)

    // Verify duration int conversion
    t->expect(h1.duration)->Expect.toEqual(Some(500))
  })

  test("Parse with legacy category", t => {
    let json = JSON.parseOrThrow(`{
      "tourName": "Legacy",
      "scenes": [
         {
           "id": "s1",
           "name": "s1.webp",
           "file": "foo",
           "category": "kitchen"
         }
      ]
    }`)
    let project = parseProject(json)->Result.getOrThrow
    let projectScenes = SceneInventory.getActiveScenes(project.inventory, project.sceneOrder)
    let s1: Types.scene = projectScenes[0]->Option.getOrThrow
    t->expect(s1.category)->Expect.toEqual("kitchen")
    t->expect(s1.categorySet)->Expect.toEqual(true)
  })

  test("Parse with minimal valid structure", t => {
    let json = JSON.parseOrThrow(`{
      "tourName": "Min",
      "scenes": [
         { "id": "m1", "name": "m1.webp", "file": "f1" }
      ]
    }`)
    let project = parseProject(json)->Result.getOrThrow
    t->expect(project.tourName)->Expect.toEqual("Min")
    let projectScenes = SceneInventory.getActiveScenes(project.inventory, project.sceneOrder)
    t->expect(Array.length(projectScenes))->Expect.toEqual(1)
  })

  test("Parse with empty scenes handles gracefully", t => {
    let json = JSON.parseOrThrow(`{ "tourName": "Empty", "scenes": [] }`)
    let project = parseProject(json)->Result.getOrThrow
    let projectScenes = SceneInventory.getActiveScenes(project.inventory, project.sceneOrder)
    t->expect(Array.length(projectScenes))->Expect.toEqual(0)
  })

  test("Robust parsing handles corrupt scene entries", t => {
    let json = JSON.parseOrThrow(`{
      "tourName": "Corrupt",
      "scenes": [
        { "id": "valid", "name": "valid.webp", "file": "ok" },
        { "corrupt": "data" }
      ]
    }`)
    let project = parseProject(json)->Result.getOrThrow
    let projectScenes = SceneInventory.getActiveScenes(project.inventory, project.sceneOrder)
    t->expect(Array.length(projectScenes))->Expect.toEqual(1)
    t->expect((projectScenes[0]->Option.getOrThrow: Types.scene).id)->Expect.toEqual("valid")
  })

  test("Robust parsing handles missing tour name", t => {
    let json1 = JSON.parseOrThrow(`{ "scenes": [] }`)
    let project1 = parseProject(json1)->Result.getOrThrow
    t->expect(project1.tourName)->Expect.toEqual("Untitled Tour")

    let json2 = JSON.parseOrThrow(`{ "tourName": "", "scenes": [{ "name": "m.webp", "file": "f" }] }`)
    let project2 = parseProject(json2)->Result.getOrThrow
    t->expect(project2.tourName)->Expect.toEqual("Untitled Tour")
    let project2Scenes = SceneInventory.getActiveScenes(project2.inventory, project2.sceneOrder)
    let s2 = Belt.Array.getExn(project2Scenes, 0)
    t->expect(s2.id)->Expect.toEqual("legacy_m.webp") // Fallback
    t->expect(Belt.Array.length(s2.hotspots))->Expect.toEqual(0)
  })

  test("syncSceneNames logic", t => {
    let sceneA = makeDummyScene(
      ~id="a",
      ~name="old_a.webp",
      ~label="Living Room",
      ~hotspots=[makeDummyHotspot(~target="old_b.webp", ())],
      (),
    )
    let sceneB = makeDummyScene(~id="b", ~name="old_b.webp", ~label="Kitchen", ())

    let scenes = [sceneA, sceneB]
    let synced = SceneNaming.syncSceneNames(scenes)

    let expectedNameA = TourLogic.computeSceneFilename(0, "Living Room", "a")
    let expectedNameB = TourLogic.computeSceneFilename(1, "Kitchen", "b")

    let syncedA = Belt.Array.getExn(synced, 0)
    let syncedB = Belt.Array.getExn(synced, 1)

    t->expect(syncedA.name)->Expect.toEqual(expectedNameA)
    t->expect(syncedB.name)->Expect.toEqual(expectedNameB)

    // Check hotspot target update in A
    let hs = syncedA.hotspots[0]->Option.getOrThrow
    t->expect(hs.target)->Expect.toEqual(expectedNameB)
  })

  test("handleDeleteScene logic", t => {
    let stateWithScenes = mockState(
      ~scenes=[
        makeDummyScene(
          ~id="s1",
          ~name="s1.webp",
          ~hotspots=[makeDummyHotspot(~target="s2.webp", ())],
          (),
        ),
        makeDummyScene(~id="s2", ~name="s2.webp", ()),
        makeDummyScene(~id="s3", ~name="s3.webp", ()),
      ],
      ~activeIndex=1,
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    // Delete s2 (index 1)
    let stateAfterDelete = handleDeleteScene(stateWithScenes, 1)
    let stateScenes = SceneInventory.getActiveScenes(
      stateAfterDelete.inventory,
      stateAfterDelete.sceneOrder,
    )
    t->expect(Belt.Array.length(stateScenes))->Expect.toEqual(2)
    t->expect(Belt.Array.getExn(stateScenes, 0).id)->Expect.toEqual("s1")
    t->expect(Belt.Array.getExn(stateScenes, 1).id)->Expect.toEqual("s3")

    // Check that hotspot in s1 pointing to s2 was removed
    let s1After = Belt.Array.getExn(stateScenes, 0)
    t->expect(Belt.Array.length(s1After.hotspots))->Expect.toEqual(0)

    // Check deletedSceneIds
    t
    ->expect(
      Belt.Array.some(SceneInventory.getDeletedIds(stateAfterDelete.inventory), id => id == "s2"),
    )
    ->Expect.toEqual(true)

    // Check activeIndex adjustment
    t->expect(stateAfterDelete.activeIndex)->Expect.toEqual(1) // Should now point to s3 which was at 2
  })

  test("handleDeleteScene last scene robustness", t => {
    let s = makeDummyScene(~id="last", ~name="last.webp", ())
    let stateWithOneScene = mockState(
      ~scenes=[s],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let stateWithOneScene = {
      ...stateWithOneScene,
      activeYaw: 45.0,
      activePitch: 10.0,
    }
    let stateAfterLastDelete = handleDeleteScene(stateWithOneScene, 0)
    let stateScenes = SceneInventory.getActiveScenes(
      stateAfterLastDelete.inventory,
      stateAfterLastDelete.sceneOrder,
    )
    t->expect(Belt.Array.length(stateScenes))->Expect.toEqual(0)
    t->expect(stateAfterLastDelete.activeIndex)->Expect.toEqual(-1)
    t->expect(stateAfterLastDelete.activeYaw)->Expect.toEqual(0.0)
    t->expect(stateAfterLastDelete.activePitch)->Expect.toEqual(0.0)
  })

  test("handleAddScenes logic", t => {
    let stateBeforeAdd = mockState(
      ~scenes=[makeDummyScene(~id="existing", ~name="a.webp", ())],
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let newSceneJson = JSON.parseOrThrow(`{
      "id": "new",
      "name": "b.webp",
      "file": "file_b"
    }`)

    let stateAfterAdd = handleAddScenes(stateBeforeAdd, [newSceneJson])
    let stateScenes = SceneInventory.getActiveScenes(
      stateAfterAdd.inventory,
      stateAfterAdd.sceneOrder,
    )
    t->expect(Belt.Array.length(stateScenes))->Expect.toEqual(2)
    t->expect(Belt.Array.some(stateScenes, s => s.id == "new"))->Expect.toEqual(true)
  })

  test("parseScene logic", t => {
    let sceneJson = JSON.parseOrThrow(`{
      "id": "s-123",
      "name": "office.webp",
      "file": "blob:office"
    }`)
    let scene = parseScene(sceneJson)
    t->expect(scene.id)->Expect.toEqual("s-123")
    t->expect(scene.name)->Expect.toEqual("office.webp")
    t->expect(scene.category)->Expect.toEqual("outdoor") // Default
  })

  test("handleAddScenes first load robustness", t => {
    let stateEmptyWithMuckIndex = mockState(
      ~scenes=[],
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let stateEmptyWithMuckIndex = {
      ...stateEmptyWithMuckIndex,
      activeYaw: 45.0,
      activePitch: 10.0,
    }
    let newSceneJson = JSON.parseOrThrow(`{
      "id": "new",
      "name": "b.webp",
      "file": "file_b"
    }`)
    let stateAfterRobustAdd = handleAddScenes(stateEmptyWithMuckIndex, [newSceneJson])
    let stateScenes = SceneInventory.getActiveScenes(
      stateAfterRobustAdd.inventory,
      stateAfterRobustAdd.sceneOrder,
    )
    t->expect(Belt.Array.length(stateScenes))->Expect.toEqual(1)
    t->expect(stateAfterRobustAdd.activeIndex)->Expect.toEqual(0)
    t->expect(stateAfterRobustAdd.activeYaw)->Expect.toEqual(0.0)
    t->expect(stateAfterRobustAdd.activePitch)->Expect.toEqual(0.0)
  })

  test("handleUpdateSceneMetadata logic", t => {
    let stateWithScenes = mockState(
      ~scenes=[
        makeDummyScene(
          ~id="s1",
          ~name="s1.webp",
          ~hotspots=[makeDummyHotspot(~target="s2.webp", ())],
          (),
        ),
        makeDummyScene(~id="s2", ~name="s2.webp", ()),
        makeDummyScene(~id="s3", ~name="s3.webp", ()),
      ],
      ~activeIndex=1,
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let metaJson = JSON.parseOrThrow(`{
      "category": "outdoor",
      "floor": "roof",
      "isAutoForward": true
    }`)
    let stateAfterMeta = handleUpdateSceneMetadata(stateWithScenes, 0, metaJson)
    let stateScenes = SceneInventory.getActiveScenes(
      stateAfterMeta.inventory,
      stateAfterMeta.sceneOrder,
    )
    let updatedS1 = Belt.Array.getExn(stateScenes, 0)
    t->expect(updatedS1.category)->Expect.toEqual("outdoor")
    t->expect(updatedS1.floor)->Expect.toEqual("roof")
    t->expect(updatedS1.isAutoForward)->Expect.toEqual(true)
    t->expect(updatedS1.categorySet)->Expect.toEqual(true)
    t->expect(stateAfterMeta.lastUsedCategory)->Expect.toEqual("outdoor")
  })

  test("handleRemoveHotspot logic", t => {
    let stateWithScenes = mockState(
      ~scenes=[
        makeDummyScene(
          ~id="s1",
          ~name="s1.webp",
          ~hotspots=[
            makeDummyHotspot(~target="s2.webp", ()),
            makeDummyHotspot(~target="s3.webp", ()),
          ],
          (),
        ),
        makeDummyScene(~id="s2", ~name="s2.webp", ()),
        makeDummyScene(~id="s3", ~name="s3.webp", ()),
      ],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: EditingHotspots, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let stateAfterRemove = handleRemoveHotspot(stateWithScenes, 0, 0)
    let stateScenes = SceneInventory.getActiveScenes(
      stateAfterRemove.inventory,
      stateAfterRemove.sceneOrder,
    )
    let s1After = Belt.Array.getExn(stateScenes, 0)
    t->expect(Belt.Array.length(s1After.hotspots))->Expect.toEqual(1)
    t->expect(Belt.Array.getExn(s1After.hotspots, 0).target)->Expect.toEqual("s3.webp")
  })
})
