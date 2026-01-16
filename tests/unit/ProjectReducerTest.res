open Types
open Actions

let run = () => {
  Console.log("Running ProjectReducer tests...")

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

  // --- Test 1: SetTourName sanitizes the name ---
  Console.log("Test 1: SetTourName sanitizes the name")
  let action = SetTourName("My Tour Name")
  let result = ProjectReducer.reduce(initialState, action)

  switch result {
  | Some(state) => {
      // TourLogic.sanitizeName replaces spaces with underscores
      assert(state.tourName == "My_Tour_Name")
      Console.log("✓ SetTourName sanitizes correctly")
    }
  | None => assert(false)
  }

  // --- Test 2: SetTourName handles empty string ---
  Console.log("Test 2: SetTourName handles empty string")
  let actionEmpty = SetTourName("")
  let resultEmpty = ProjectReducer.reduce(initialState, actionEmpty)

  switch resultEmpty {
  | Some(state) => {
      // Empty strings should be sanitized to "Untitled"
      assert(state.tourName == "Untitled")
      Console.log("✓ SetTourName handles empty string")
    }
  | None => assert(false)
  }

  // --- Test 3: SetTourName handles special characters ---
  Console.log("Test 3: SetTourName handles special characters")
  let actionSpecial = SetTourName("Tour<>:\"/\\|?*Name")
  let resultSpecial = ProjectReducer.reduce(initialState, actionSpecial)

  switch resultSpecial {
  | Some(state) => {
      // Special characters should be replaced with underscores
      assert(state.tourName == "Tour_Name")
      Console.log("✓ SetTourName handles special characters")
    }
  | None => assert(false)
  }

  // --- Test 4: SetTourName respects maxLength ---
  Console.log("Test 4: SetTourName respects maxLength")
  let longName = String.repeat("a", 150)
  let actionLong = SetTourName(longName)
  let resultLong = ProjectReducer.reduce(initialState, actionLong)

  switch resultLong {
  | Some(state) => {
      // Should be truncated to 100 characters
      assert(String.length(state.tourName) == 100)
      Console.log("✓ SetTourName respects maxLength")
    }
  | None => assert(false)
  }

  // --- Test 5: LoadProject parses project data ---
  Console.log("Test 5: LoadProject parses project data")
  // Create a minimal project JSON
  let projectJson = Obj.magic({
    "tourName": "Test Tour",
    "scenes": [],
  })
  let actionLoad = LoadProject(projectJson)
  let resultLoad = ProjectReducer.reduce(initialState, actionLoad)

  switch resultLoad {
  | Some(state) => {
      assert(state.tourName == "Test Tour")
      assert(Array.length(state.scenes) == 0)
      Console.log("✓ LoadProject parses project data")
    }
  | None => assert(false)
  }

  // --- Test 6: LoadProject handles missing tourName ---
  Console.log("Test 6: LoadProject handles missing tourName")
  let projectJsonNoName = Obj.magic({
    "scenes": [],
  })
  let actionLoadNoName = LoadProject(projectJsonNoName)
  let resultLoadNoName = ProjectReducer.reduce(initialState, actionLoadNoName)

  switch resultLoadNoName {
  | Some(state) => {
      // Should default to "Imported Tour"
      assert(state.tourName == "Imported Tour")
      Console.log("✓ LoadProject handles missing tourName")
    }
  | None => assert(false)
  }

  // --- Test 7: Reset returns initial state ---
  Console.log("Test 7: Reset returns initial state")
  let modifiedState = {...initialState, tourName: "Modified", activeIndex: 5}
  let actionReset = Reset
  let resultReset = ProjectReducer.reduce(modifiedState, actionReset)

  switch resultReset {
  | Some(state) => {
      assert(state.tourName == "")
      assert(state.activeIndex == -1)
      assert(Array.length(state.scenes) == 0)
      Console.log("✓ Reset returns initial state")
    }
  | None => assert(false)
  }

  // --- Test 8: SetExifReport sets the report ---
  Console.log("Test 8: SetExifReport sets the report")
  let exifData = Obj.magic({"files": 10, "processed": 8})
  let actionExif = SetExifReport(exifData)
  let resultExif = ProjectReducer.reduce(initialState, actionExif)

  switch resultExif {
  | Some(state) => {
      assert(state.exifReport == Some(exifData))
      Console.log("✓ SetExifReport sets the report")
    }
  | None => assert(false)
  }

  // --- Test 9: RemoveDeletedSceneId removes the ID ---
  Console.log("Test 9: RemoveDeletedSceneId removes the ID")
  let stateWithDeleted = {...initialState, deletedSceneIds: ["id1", "id2", "id3"]}
  let actionRemove = RemoveDeletedSceneId("id2")
  let resultRemove = ProjectReducer.reduce(stateWithDeleted, actionRemove)

  switch resultRemove {
  | Some(state) => {
      assert(Array.length(state.deletedSceneIds) == 2)
      assert(!Array.includes(state.deletedSceneIds, "id2"))
      assert(Array.includes(state.deletedSceneIds, "id1"))
      assert(Array.includes(state.deletedSceneIds, "id3"))
      Console.log("✓ RemoveDeletedSceneId removes the ID")
    }
  | None => assert(false)
  }

  // --- Test 10: RemoveDeletedSceneId handles non-existent ID ---
  Console.log("Test 10: RemoveDeletedSceneId handles non-existent ID")
  let stateWithDeleted2 = {...initialState, deletedSceneIds: ["id1", "id2"]}
  let actionRemoveNonExistent = RemoveDeletedSceneId("id99")
  let resultRemoveNonExistent = ProjectReducer.reduce(stateWithDeleted2, actionRemoveNonExistent)

  switch resultRemoveNonExistent {
  | Some(state) => {
      assert(Array.length(state.deletedSceneIds) == 2)
      assert(Array.includes(state.deletedSceneIds, "id1"))
      assert(Array.includes(state.deletedSceneIds, "id2"))
      Console.log("✓ RemoveDeletedSceneId handles non-existent ID")
    }
  | None => assert(false)
  }

  // --- Test 11: Unhandled action returns None ---
  Console.log("Test 11: Unhandled action returns None")
  let actionUnhandled = SetIsLinking(true)
  let resultUnhandled = ProjectReducer.reduce(initialState, actionUnhandled)

  assert(resultUnhandled == None)
  Console.log("✓ Unhandled action returns None")

  // --- Test 12: State immutability ---
  Console.log("Test 12: State immutability")
  let originalState = {...initialState, tourName: "Original"}
  let actionMutate = SetTourName("Modified")
  let _newState = ProjectReducer.reduce(originalState, actionMutate)

  assert(originalState.tourName == "Original")
  Console.log("✓ State immutability preserved")

  // --- Test 13: SetTourName preserves other state fields ---
  Console.log("Test 13: SetTourName preserves other state fields")
  let stateWithScenes = {...initialState, scenes: [createScene("s1")], activeIndex: 0}
  let actionPreserve = SetTourName("New Name")
  let resultPreserve = ProjectReducer.reduce(stateWithScenes, actionPreserve)

  switch resultPreserve {
  | Some(state) => {
      assert(state.tourName == "New_Name")
      assert(Array.length(state.scenes) == 1)
      assert(state.activeIndex == 0)
      Console.log("✓ SetTourName preserves other state fields")
    }
  | None => assert(false)
  }

  // --- Test 14: SetExifReport replaces existing report ---
  Console.log("Test 14: SetExifReport replaces existing report")
  let oldExif = Obj.magic({"old": true})
  let newExif = Obj.magic({"new": true})
  let stateWithExif = {...initialState, exifReport: Some(oldExif)}
  let actionReplaceExif = SetExifReport(newExif)
  let resultReplaceExif = ProjectReducer.reduce(stateWithExif, actionReplaceExif)

  switch resultReplaceExif {
  | Some(state) => {
      assert(state.exifReport == Some(newExif))
      Console.log("✓ SetExifReport replaces existing report")
    }
  | None => assert(false)
  }

  // --- Test 15: RemoveDeletedSceneId with empty array ---
  Console.log("Test 15: RemoveDeletedSceneId with empty array")
  let stateEmpty = {...initialState, deletedSceneIds: []}
  let actionRemoveEmpty = RemoveDeletedSceneId("id1")
  let resultRemoveEmpty = ProjectReducer.reduce(stateEmpty, actionRemoveEmpty)

  switch resultRemoveEmpty {
  | Some(state) => {
      assert(Array.length(state.deletedSceneIds) == 0)
      Console.log("✓ RemoveDeletedSceneId with empty array")
    }
  | None => assert(false)
  }

  Console.log("ProjectReducer tests completed.")
}
