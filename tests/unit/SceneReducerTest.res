open Types
open Actions

let run = () => {
  Console.log("Running SceneReducer tests...")

  let initialState = State.initialState

  // Helper to create basic scene
  let createScene = name => {
    id: name,
    name,
    file: Obj.magic(name),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "indoor",
    floor: "ground",
    label: "",
    quality: None,
    colorGroup: None,
    _metadataSource: "default",
    categorySet: false,
    labelSet: false,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  }

  // Helper to create basic state
  let createStateWithScenes = scenes => {
    ...initialState,
    scenes,
    activeIndex: if Array.length(scenes) > 0 {
      0
    } else {
      -1
    },
  }

  // --- Test AddScenes ---
  // Mock JSON data (using dummy object as we rely on ReducerHelpers.handleAddScenes parsing)
  // Since we can't easily construct the typed JSON here without helpers, we might skip parsing logic test
  // or use minimal valid JSON if possible.
  // Actually SceneReducer.reduce(AddScenes) calls ReducerHelpers.handleAddScenes.
  // We can test behavior if we can mock JSON.

  // --- Test SetActiveScene ---
  let scenes = [createScene("s1"), createScene("s2")]
  let state = createStateWithScenes(scenes)

  let action = SetActiveScene(1, 90.0, 0.0, None)
  let result = SceneReducer.reduce(state, action)

  switch result {
  | Some(newState) =>
    assert(newState.activeIndex == 1)
    assert(newState.activeYaw == 90.0)
    Console.log("✓ SetActiveScene passed")
  | None => Console.error("✗ SetActiveScene failed: returned None")
  }

  // --- Test DeleteScene ---
  let actionDelete = DeleteScene(0)
  let resultDelete = SceneReducer.reduce(state, actionDelete)

  switch resultDelete {
  | Some(newState) =>
    assert(Array.length(newState.scenes) == 1)
    assert(newState.activeIndex == 0) // Should shift to 0
    Console.log("✓ DeleteScene passed")
  | None => Console.error("✗ DeleteScene failed: returned None")
  }

  // --- Test Unhandled Action ---
  let unhandled = SetIsLinking(true)
  let resultUnhandled = SceneReducer.reduce(state, unhandled)

  switch resultUnhandled {
  | Some(_) => Console.error("✗ Unhandled action failed: returned Some")
  | None => Console.log("✓ Unhandled action ignored correctly")
  }

  Console.log("SceneReducer tests completed.")
}
