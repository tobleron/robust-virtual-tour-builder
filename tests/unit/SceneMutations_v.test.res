open Vitest
open SceneMutations
open TestUtils
open Types

describe("SceneMutations", () => {
  test("syncSceneNames updates names based on labels", t => {
    // Note: sequenceId must be unique for each scene to get unique prefixes
    let s1 = createMockScene(~id="s1", ~name="old_name1.webp", ~label="Entrance", ~sequenceId=1, ())
    let s2 = createMockScene(~id="s2", ~name="old_name2.webp", ~label="Living Room", ~sequenceId=2, ())
    let scenes = [s1, s2]

    let updated = SceneNaming.syncSceneNames(scenes)

    let u1 = updated[0]->Option.getOrThrow
    let u2 = updated[1]->Option.getOrThrow

    t->expect(u1.name)->Expect.toBe("001_Entrance.webp")
    t->expect(u2.name)->Expect.toBe("002_Living_Room.webp")
  })

  test("syncSceneNames updates hotspot targets when scenes are renamed", t => {
    let s1 = createMockScene(~id="s1", ~name="old_s1.webp", ~label="Scene 1", ())
    let h1 = createMockHotspot(~id="h1", ~target="old_s1.webp", ())
    let s2 = createMockScene(~id="s2", ~name="old_s2.webp", ~label="Scene 2", ~hotspots=[h1], ())
    let scenes = [s1, s2]

    let updated = SceneNaming.syncSceneNames(scenes)

    let updatedS2 = updated[1]->Option.getOrThrow
    let updatedH1 = updatedS2.hotspots[0]->Option.getOrThrow
    t->expect(updatedH1.target)->Expect.toBe("001_Scene_1.webp")
  })

  test("calculateActiveIndexAfterDelete handles various cases", t => {
    // Current index 1, delete index 1, remaining length 2 -> index 1 (next item)
    t->expect(calculateActiveIndexAfterDelete(1, 1, 2))->Expect.toBe(1)

    // Current index 1, delete index 1, remaining length 1 -> index 0 (last item)
    t->expect(calculateActiveIndexAfterDelete(1, 1, 1))->Expect.toBe(0)

    // Current index 2, delete index 0, remaining length 2 -> index 1 (shifted down)
    t->expect(calculateActiveIndexAfterDelete(2, 0, 2))->Expect.toBe(1)

    // Current index 0, delete index 2, remaining length 2 -> index 0 (stays same)
    t->expect(calculateActiveIndexAfterDelete(0, 2, 2))->Expect.toBe(0)

    // Remaining 0 -> -1
    t->expect(calculateActiveIndexAfterDelete(0, 0, 0))->Expect.toBe(-1)
  })

  test("handleDeleteScene removes scene and cleans up references", t => {
    let s1 = createMockScene(~id="s1", ~name="scene1.webp", ())
    let h1 = createMockHotspot(~id="h1", ~target="scene1.webp", ())
    let s2 = createMockScene(~id="s2", ~name="scene2.webp", ~hotspots=[h1], ())
    let state = createMockState(
      ~scenes=[s1, s2],
      ~activeIndex=1,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    let result = handleDeleteScene(state, 0)

    let resultScenes = SceneInventory.getActiveScenes(result.inventory, result.sceneOrder)
    t->expect(resultScenes->Array.length)->Expect.toBe(1)
    t->expect(result.activeIndex)->Expect.toBe(0)

    let remainingScene = resultScenes[0]->Option.getOrThrow
    t->expect(remainingScene.id)->Expect.toBe("s2")
    t->expect(remainingScene.hotspots->Array.length)->Expect.toBe(0) // Hotspot to s1 removed
    t->expect(SceneInventory.getDeletedIds(result.inventory))->Expect.toContain("s1")
  })

  test("handleReorderScenes moves items and updates activeIndex", t => {
    let s0 = createMockScene(~id="0", ())
    let s1 = createMockScene(~id="1", ())
    let s2 = createMockScene(~id="2", ())
    let state = createMockState(
      ~scenes=[s0, s1, s2],
      ~activeIndex=1,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )

    // Move 1 to end: [0, 2, 1]
    let result = handleReorderScenes(state, 1, 2)
    let resultScenes = SceneInventory.getActiveScenes(result.inventory, result.sceneOrder)
    let lastScene = resultScenes[2]->Option.getOrThrow
    t->expect(lastScene.id)->Expect.toBe("1")
    t->expect(result.activeIndex)->Expect.toBe(2)

    // Move 2 to front: [2, 0, 1] (result from previous was [0, 2, 1])
    let result2 = handleReorderScenes(result, 1, 0)
    let result2Scenes = SceneInventory.getActiveScenes(result2.inventory, result2.sceneOrder)
    let firstScene = result2Scenes[0]->Option.getOrThrow
    t->expect(firstScene.id)->Expect.toBe("2")
    t->expect(result2.activeIndex)->Expect.toBe(2) // 1 stayed at 2
  })
})
