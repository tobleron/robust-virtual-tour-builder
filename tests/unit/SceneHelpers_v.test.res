open Vitest
open SceneHelpers
open Types

describe("SceneHelpers", () => {
  // Helpers for creating dummy data
  let makeDummyHotspot = (~target="target.webp", ()) => {
    let hs: Types.hotspot = {
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
    hs
  }

  let makeDummyScene = (~id="id", ~name="name.webp", ~label="", ~hotspots=[], ()) => {
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
      preCalculatedSnapshot: None,
    }
    sc
  }

  test("Parse full project structure", t => {
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
    t->expect(state.tourName)->Expect.toEqual("Full Project")

    let s1 = Belt.Array.getExn(state.scenes, 0)
    t->expect(s1.id)->Expect.toEqual("s1")

    let h1 = Belt.Array.getExn(s1.hotspots, 0)
    t->expect(h1.linkId)->Expect.toEqual("h1")
    t->expect(h1.yaw)->Expect.toEqual(10.0)

    // Verify duration int conversion
    t->expect(h1.duration)->Expect.toEqual(Some(500))

    // Verify viewFrame
    switch h1.viewFrame {
    | Some(vf) =>
      t->expect(vf.yaw)->Expect.toEqual(1.0)
      t->expect(vf.pitch)->Expect.toEqual(2.0)
    | None => failwith("Expected viewFrame")
    }
  })

  test("Parse minimal project structure", t => {
    let json2Str = `{
      "scenes": [
        {
          "name": "min.webp",
          "file": "foo"
        }
      ]
    }`
    let json2 = JSON.parseOrThrow(json2Str)

    let state2 = parseProject(json2)
    t->expect(state2.tourName)->Expect.toEqual("Tour Name") // Default

    let s2 = Belt.Array.getExn(state2.scenes, 0)
    t->expect(s2.id)->Expect.toEqual("legacy_min.webp") // Fallback
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
    let synced = syncSceneNames(scenes)

    let expectedNameA = TourLogic.computeSceneFilename(0, "Living Room")
    let expectedNameB = TourLogic.computeSceneFilename(1, "Kitchen")

    let syncedA = Belt.Array.getExn(synced, 0)
    let syncedB = Belt.Array.getExn(synced, 1)

    t->expect(syncedA.name)->Expect.toEqual(expectedNameA)
    t->expect(syncedB.name)->Expect.toEqual(expectedNameB)

    // Check hotspot target update in A
    let hs = Belt.Array.getUnsafe(syncedA.hotspots, 0)
    t->expect(hs.target)->Expect.toEqual(expectedNameB)
  })

  test("handleDeleteScene logic", t => {
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
    t->expect(Belt.Array.length(stateAfterDelete.scenes))->Expect.toEqual(2)
    t->expect(Belt.Array.getExn(stateAfterDelete.scenes, 0).id)->Expect.toEqual("s1")
    t->expect(Belt.Array.getExn(stateAfterDelete.scenes, 1).id)->Expect.toEqual("s3")

    // Check that hotspot in s1 pointing to s2 was removed
    let s1After = Belt.Array.getExn(stateAfterDelete.scenes, 0)
    t->expect(Belt.Array.length(s1After.hotspots))->Expect.toEqual(0)

    // Check deletedSceneIds
    t
    ->expect(Belt.Array.some(stateAfterDelete.deletedSceneIds, id => id == "s2"))
    ->Expect.toEqual(true)

    // Check activeIndex adjustment
    t->expect(stateAfterDelete.activeIndex)->Expect.toEqual(1) // Should now point to s3 which was at 2
  })

  test("handleDeleteScene last scene robustness", t => {
    let stateWithOneScene = {
      ...State.initialState,
      scenes: [makeDummyScene(~id="last", ~name="last.webp", ())],
      activeIndex: 0,
      activeYaw: 45.0,
      activePitch: 10.0,
    }
    let stateAfterLastDelete = handleDeleteScene(stateWithOneScene, 0)
    t->expect(Belt.Array.length(stateAfterLastDelete.scenes))->Expect.toEqual(0)
    t->expect(stateAfterLastDelete.activeIndex)->Expect.toEqual(-1)
    t->expect(stateAfterLastDelete.activeYaw)->Expect.toEqual(0.0)
    t->expect(stateAfterLastDelete.activePitch)->Expect.toEqual(0.0)
  })

  test("handleAddScenes logic", t => {
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
    t->expect(Belt.Array.length(stateAfterAdd.scenes))->Expect.toEqual(2)
    t->expect(Belt.Array.some(stateAfterAdd.scenes, s => s.id == "new"))->Expect.toEqual(true)
  })

  test("handleAddScenes first load robustness", t => {
    let stateEmptyWithMuckIndex = {
      ...State.initialState,
      scenes: [],
      activeIndex: 5, // Invalid but let's test robustness
      activeYaw: 45.0,
      activePitch: 10.0,
    }
    let newSceneJson = JSON.parseOrThrow(`{
      "id": "new",
      "name": "b.webp",
      "preview": "file_b"
    }`)
    let stateAfterRobustAdd = handleAddScenes(stateEmptyWithMuckIndex, [newSceneJson])
    t->expect(Belt.Array.length(stateAfterRobustAdd.scenes))->Expect.toEqual(1)
    t->expect(stateAfterRobustAdd.activeIndex)->Expect.toEqual(0)
    t->expect(stateAfterRobustAdd.activeYaw)->Expect.toEqual(0.0)
    t->expect(stateAfterRobustAdd.activePitch)->Expect.toEqual(0.0)
  })

  test("handleUpdateSceneMetadata logic", t => {
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
    let metaJson = JSON.parseOrThrow(`{
      "category": "outdoor",
      "floor": "roof"
    }`)
    let stateAfterMeta = handleUpdateSceneMetadata(stateWithScenes, 0, metaJson)
    let updatedS1 = Belt.Array.getExn(stateAfterMeta.scenes, 0)
    t->expect(updatedS1.category)->Expect.toEqual("outdoor")
    t->expect(updatedS1.floor)->Expect.toEqual("roof")
    t->expect(stateAfterMeta.lastUsedCategory)->Expect.toEqual("outdoor")
  })

  test("handleRemoveHotspot logic", t => {
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
    let stateWithAutoForward = {
      ...stateWithScenes,
      scenes: [
        {
          ...Belt.Array.getExn(stateWithScenes.scenes, 0),
          hotspots: [makeDummyHotspot(~target="s2.webp", ())],
        },
        {
          ...Belt.Array.getExn(stateWithScenes.scenes, 1),
          isAutoForward: true,
        },
        Belt.Array.getExn(stateWithScenes.scenes, 2),
      ],
    }

    // Remove hotspot in s1 that points to s2
    let stateAfterRemoveHotspot = handleRemoveHotspot(stateWithAutoForward, 0, 0)
    let s1AfterRemove = Belt.Array.getExn(stateAfterRemoveHotspot.scenes, 0)
    t->expect(Belt.Array.length(s1AfterRemove.hotspots))->Expect.toEqual(0)

    // s2 isAutoForward should be reset to false because nothing points to it anymore
    let s2AfterRemove = Belt.Array.getExn(stateAfterRemoveHotspot.scenes, 1)
    t->expect(s2AfterRemove.isAutoForward)->Expect.toEqual(false)
  })
})
