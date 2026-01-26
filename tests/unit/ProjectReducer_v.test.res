/* tests/unit/ProjectReducer_v.test.res */
open Vitest
open Actions

describe("ProjectReducer", () => {
  let initialState = State.initialState

  // Helper to create basic scene
  let createScene = name => {
    let sc: Types.scene = {
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
    }
    sc
  }

  test("SetTourName sanitizes the name", t => {
    let action = SetTourName("My Tour Name")
    let result = ProjectReducer.reduce(initialState, action)

    switch result {
    | Some(state) => t->expect(state.tourName)->Expect.toEqual("My_Tour_Name")
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetTourName handles empty string", t => {
    let actionEmpty = SetTourName("")
    let resultEmpty = ProjectReducer.reduce(initialState, actionEmpty)

    switch resultEmpty {
    | Some(state) => t->expect(state.tourName)->Expect.toEqual("Untitled")
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetTourName handles special characters", t => {
    let actionSpecial = SetTourName("Tour<>:\"/\\|?*Name")
    let resultSpecial = ProjectReducer.reduce(initialState, actionSpecial)

    switch resultSpecial {
    | Some(state) => t->expect(state.tourName)->Expect.toEqual("Tour_Name")
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetTourName respects maxLength", t => {
    let longName = String.repeat("a", 300)
    let actionLong = SetTourName(longName)
    let resultLong = ProjectReducer.reduce(initialState, actionLong)

    switch resultLong {
    | Some(state) => t->expect(String.length(state.tourName))->Expect.toEqual(255)
    | None => failwith("Expected Some(state)")
    }
  })

  test("LoadProject parses project data", t => {
    let projectJson = JSON.parseOrThrow(`{"tourName": "Test Tour", "scenes": []}`)
    let actionLoad = LoadProject(projectJson)
    let resultLoad = ProjectReducer.reduce(initialState, actionLoad)

    switch resultLoad {
    | Some(state) =>
      t->expect(state.tourName)->Expect.toEqual("Test Tour")
      t->expect(Array.length(state.scenes))->Expect.toEqual(0)
    | None => failwith("Expected Some(state)")
    }
  })

  test("LoadProject handles missing tourName", t => {
    let projectJsonNoName = JSON.parseOrThrow(`{"scenes": []}`)
    let actionLoadNoName = LoadProject(projectJsonNoName)
    let resultLoadNoName = ProjectReducer.reduce(initialState, actionLoadNoName)

    switch resultLoadNoName {
    | Some(state) => t->expect(state.tourName)->Expect.toEqual("Tour Name")
    | None => failwith("Expected Some(state)")
    }
  })

  test("Reset returns initial state", t => {
    let modifiedState = {...initialState, tourName: "Modified", activeIndex: 5}
    let actionReset = Reset
    let resultReset = ProjectReducer.reduce(modifiedState, actionReset)

    switch resultReset {
    | Some(state) =>
      t->expect(state.tourName)->Expect.toEqual("Tour Name")
      t->expect(state.activeIndex)->Expect.toEqual(-1)
      t->expect(Array.length(state.scenes))->Expect.toEqual(0)
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetExifReport sets the report", t => {
    let exifData = JSON.parseOrThrow(`{
      "totalSelected": 10,
      "alreadyInProject": 2,
      "invalidFiles": 1,
      "validClusters": 2
    }`)
    let actionExif = SetExifReport(exifData)
    let resultExif = ProjectReducer.reduce(initialState, actionExif)

    switch resultExif {
    | Some(state) => t->expect(state.exifReport)->Expect.toEqual(Some(exifData))
    | None => failwith("Expected Some(state)")
    }
  })

  test("RemoveDeletedSceneId removes the ID", t => {
    let stateWithDeleted = {...initialState, deletedSceneIds: ["id1", "id2", "id3"]}
    let actionRemove = RemoveDeletedSceneId("id2")
    let resultRemove = ProjectReducer.reduce(stateWithDeleted, actionRemove)

    switch resultRemove {
    | Some(state) =>
      t->expect(Array.length(state.deletedSceneIds))->Expect.toEqual(2)
      t->expect(Array.includes(state.deletedSceneIds, "id2"))->Expect.toEqual(false)
      t->expect(Array.includes(state.deletedSceneIds, "id1"))->Expect.toEqual(true)
      t->expect(Array.includes(state.deletedSceneIds, "id3"))->Expect.toEqual(true)
    | None => failwith("Expected Some(state)")
    }
  })

  test("RemoveDeletedSceneId handles non-existent ID", t => {
    let stateWithDeleted2 = {...initialState, deletedSceneIds: ["id1", "id2"]}
    let actionRemoveNonExistent = RemoveDeletedSceneId("id99")
    let resultRemoveNonExistent = ProjectReducer.reduce(stateWithDeleted2, actionRemoveNonExistent)

    switch resultRemoveNonExistent {
    | Some(state) =>
      t->expect(Array.length(state.deletedSceneIds))->Expect.toEqual(2)
      t->expect(Array.includes(state.deletedSceneIds, "id1"))->Expect.toEqual(true)
      t->expect(Array.includes(state.deletedSceneIds, "id2"))->Expect.toEqual(true)
    | None => failwith("Expected Some(state)")
    }
  })

  test("Unhandled action returns None", t => {
    let actionUnhandled = StopLinking
    let resultUnhandled = ProjectReducer.reduce(initialState, actionUnhandled)

    t->expect(resultUnhandled)->Expect.toEqual(None)
  })

  test("State immutability", t => {
    let originalState = {...initialState, tourName: "Original"}
    let actionMutate = SetTourName("Modified")
    let _newState = ProjectReducer.reduce(originalState, actionMutate)

    t->expect(originalState.tourName)->Expect.toEqual("Original")
  })

  test("SetTourName preserves other state fields", t => {
    let stateWithScenes = {...initialState, scenes: [createScene("s1")], activeIndex: 0}
    let actionPreserve = SetTourName("New Name")
    let resultPreserve = ProjectReducer.reduce(stateWithScenes, actionPreserve)

    switch resultPreserve {
    | Some(state) =>
      t->expect(state.tourName)->Expect.toEqual("New_Name")
      t->expect(Array.length(state.scenes))->Expect.toEqual(1)
      t->expect(state.activeIndex)->Expect.toEqual(0)
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetExifReport replaces existing report", t => {
    let oldExif = JSON.parseOrThrow(`{"totalSelected": 1}`)
    let newExif = JSON.parseOrThrow(`{"totalSelected": 2}`)
    let stateWithExif = {...initialState, exifReport: Some(oldExif)}
    let actionReplaceExif = SetExifReport(newExif)
    let resultReplaceExif = ProjectReducer.reduce(stateWithExif, actionReplaceExif)

    switch resultReplaceExif {
    | Some(state) => t->expect(state.exifReport)->Expect.toEqual(Some(newExif))
    | None => failwith("Expected Some(state)")
    }
  })

  test("RemoveDeletedSceneId with empty array", t => {
    let stateEmpty = {...initialState, deletedSceneIds: []}
    let actionRemoveEmpty = RemoveDeletedSceneId("id1")
    let resultRemoveEmpty = ProjectReducer.reduce(stateEmpty, actionRemoveEmpty)

    switch resultRemoveEmpty {
    | Some(state) => t->expect(Array.length(state.deletedSceneIds))->Expect.toEqual(0)
    | None => failwith("Expected Some(state)")
    }
  })

  test("SetSessionId sets the session ID", t => {
    let actionSession = SetSessionId("session_123")
    let resultSession = ProjectReducer.reduce(initialState, actionSession)

    switch resultSession {
    | Some(state) => t->expect(state.sessionId)->Expect.toEqual(Some("session_123"))
    | None => failwith("Expected Some(state)")
    }
  })

  test("LoadProject preserves existing sessionId", t => {
    let stateWithSession = {...initialState, sessionId: Some("preserved_session")}
    let projectJson = JSON.parseOrThrow(`{"tourName": "Real Tour", "scenes": []}`)
    let actionLoadPreserve = LoadProject(projectJson)
    let resultLoadPreserve = ProjectReducer.reduce(stateWithSession, actionLoadPreserve)

    switch resultLoadPreserve {
    | Some(state) =>
      t->expect(state.tourName)->Expect.toEqual("Real Tour")
      t->expect(state.sessionId)->Expect.toEqual(Some("preserved_session"))
    | None => failwith("Expected Some(state)")
    }
  })
})
