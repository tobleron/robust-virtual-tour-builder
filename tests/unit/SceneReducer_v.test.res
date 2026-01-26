/* tests/unit/SceneReducer.test.res */
open Vitest
open Actions
open TestUtils
// RootReducer is used fully qualified, no open needed if namespaced correctly, but keeping it open for now if needed.
// Actually, RootReducer was unused because I use RootReducer.reducer explicitly?
// ReScript says "unused open RootReducer".

test("SceneReducer: handleSetActiveScene sets active index and transition", t => {
  let s1 = createMockScene(~id="s1", ())
  let s2 = createMockScene(~id="s2", ())
  let state = createMockState(~scenes=[s1, s2], ~activeIndex=0, ())

  let transition: Types.transition = {
    type_: Fade,
    targetHotspotIndex: 0,
    fromSceneName: Some("s1"),
  }

  let action = SetActiveScene(1, 45.0, -10.0, Some(transition))
  // Use RootReducer to verify the action is handled correctly by the system
  let result = RootReducer.reducer(state, action)

  t->expect(result.activeIndex)->Expect.toBe(1)
  t->expect(result.activeYaw)->Expect.toBe(45.0)
  t->expect(result.activePitch)->Expect.toBe(-10.0)
  t->expect(result.transition.type_)->Expect.toEqual(Fade)
})

test("SceneReducer: handleSetActiveScene ignores invalid index", t => {
  let state = createMockState(~scenes=[createMockScene()], ~activeIndex=0, ())
  let action = SetActiveScene(5, 0.0, 0.0, None)
  let result = RootReducer.reducer(state, action)

  t->expect(result.activeIndex)->Expect.toBe(0)
})

test("SceneReducer: ReorderScenes moves scene and updates activeIndex correctly", t => {
  let s0 = createMockScene(~id="0", ())
  let s1 = createMockScene(~id="1", ())
  let s2 = createMockScene(~id="2", ())
  let state = createMockState(~scenes=[s0, s1, s2], ~activeIndex=1, ()) // Active is "1"

  // Move "1" to index 2: [0, 2, 1]
  let action = ReorderScenes(1, 2)
  let result = RootReducer.reducer(state, action)

  let scene = result.scenes[2]->Option.getOrThrow
  t->expect(scene.id)->Expect.toBe("1")
  t->expect(result.activeIndex)->Expect.toBe(2)
})

test("SceneReducer: DeleteScene removes scene and cleanup hotspots", t => {
  let h1 = createMockHotspot(~id="h1", ~target="scene2_name", ())
  let s1 = createMockScene(~id="s1", ~name="scene1_name", ~hotspots=[h1], ())
  let s2 = createMockScene(~id="s2", ~name="scene2_name", ())
  let state = createMockState(~scenes=[s1, s2], ~activeIndex=0, ())

  // Delete s2 (index 1)
  let action = DeleteScene(1)
  let result = RootReducer.reducer(state, action)

  t->expect(result.scenes->Array.length)->Expect.toBe(1)
  let remainingScene = result.scenes[0]->Option.getOrThrow
  t->expect(remainingScene.hotspots->Array.length)->Expect.toBe(0) // Hotspot to s2 should be gone
})

test("SceneReducer: handleSetActiveScene applies lastUsedCategory if not set", t => {
  let s1 = createMockScene(~id="s1", ~categorySet=false, ~category="default", ())
  let state = createMockState(~scenes=[s1], ~activeIndex=-1, ~lastUsedCategory="kitchen", ())

  let action = SetActiveScene(0, 0.0, 0.0, None)
  let result = RootReducer.reducer(state, action)

  let updatedScene = result.scenes[0]->Option.getOrThrow
  t->expect(updatedScene.category)->Expect.toBe("kitchen")
})

test("SceneReducer: ApplyLazyRename updates label and syncs name", t => {
  let s1 = createMockScene(~id="s1", ~name="old_name.webp", ~label="Old Label", ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ())

  let action = ApplyLazyRename(0, "New Label")
  let result = RootReducer.reducer(state, action)

  let updatedScene = result.scenes[0]->Option.getOrThrow
  t->expect(updatedScene.label)->Expect.toBe("New Label")
  // It should also sync the name based on label
  let expectedName = TourLogic.computeSceneFilename(0, "New Label")
  t->expect(updatedScene.name)->Expect.toBe(expectedName)
})
