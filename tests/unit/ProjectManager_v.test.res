open Vitest
open Types

module Vi = {
  type mock
  @val @scope("vi") external stubGlobal: (string, 'a) => unit = "stubGlobal"
  @val @scope("vi") external unstubAllGlobals: unit => unit = "unstubAllGlobals"
  @val @scope("vi") external fn: unit => mock = "fn"
  @val @scope("vi") external fn1: ('a => 'b) => mock = "fn"
  @send external mockReturnValue: (mock, 'a) => mock = "mockReturnValue"
  @send external mockImplementation: (mock, 'a) => mock = "mockImplementation"
  @get external calls: mock => array<array<'a>> = "calls"
  @get external mock: mock => {..} = "mock"
}

// Helpers
let mockFormData = () => {
  let append = Vi.fn()
  let mockInstance = {
    "append": append,
  }
  let mockImpl = %raw(`function(i) { return function() { return i } }`)(mockInstance)
  let mockCtor = Vi.fn()
  let _ = mockCtor->Vi.mockImplementation(mockImpl)

  Vi.stubGlobal("FormData", mockCtor)
  append
}

let mockFetch = () => {
  let mockFetchFn = Vi.fn()
  Vi.stubGlobal("fetch", mockFetchFn)
  mockFetchFn
}

let createMockResponse = (ok, status, jsonFn, blobFn) => {
  {
    "ok": ok,
    "status": status,
    "statusText": if ok {
      "OK"
    } else {
      "Error"
    },
    "json": jsonFn,
    "blob": blobFn,
    "text": Vi.fn(),
  }
}

describe("ProjectManager.Logic", () => {
  let initialState = State.initialState

  beforeEach(() => {
    Vi.unstubAllGlobals()
  })

  test("validateProjectStructure accepts valid project", t => {
    let project: Types.project = {
      tourName: "Valid Tour",
      inventory: Belt.Map.String.empty,
      sceneOrder: [],
      lastUsedCategory: "indoor",
      exifReport: None,
      sessionId: Some("sess1"),
      timeline: [],
      logo: None,
      marketingComment: "",
      marketingPhone1: "",
      marketingPhone2: "",
      marketingForRent: false,
      marketingForSale: false,
      nextSceneSequenceId: 1,
    }
    let projectJson = JsonParsers.Encoders.project(project)

    let result = ProjectManager.Logic.validateProjectStructure(projectJson)

    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(true)
    | Error(msg) => failwith("Expected Ok, got Error: " ++ msg)
    }
  })

  testAsync("createSavePackage uploads data and returns blob", async t => {
    let mockAppend = mockFormData()
    let mockFetchFn = mockFetch()

    let mockBlob = "mock_blob"
    let mockBlobFn = Vi.fn()
    let _ = mockBlobFn->Vi.mockReturnValue(Promise.resolve(mockBlob))

    let mockResponse = createMockResponse(true, 200, Vi.fn(), mockBlobFn)
    let _ = mockFetchFn->Vi.mockReturnValue(Promise.resolve(mockResponse))

    let state = {...initialState, tourName: "Test Tour", sessionId: Some("session_123")}

    let result = await ProjectManager.Logic.createSavePackage(state)

    let calls = (mockAppend->Vi.mock)["calls"]
    t->expect(Array.length(calls) > 0)->Expect.toBe(true)

    let fetchCalls = (mockFetchFn->Vi.mock)["calls"]
    t->expect(Array.length(fetchCalls))->Expect.toBe(1)

    switch result {
    | Ok(blob) => t->expect(Obj.magic(blob))->Expect.toBe(mockBlob)
    | Error(msg) => failwith("Expected Ok, got Error: " ++ msg)
    }
  })

  testAsync("processLoadedProjectData handles valid data", async t => {
    let sessionId = "session_123"
    let project: Types.project = {
      tourName: "Loaded Tour",
      inventory: Belt.Map.String.empty,
      sceneOrder: [],
      lastUsedCategory: "indoor",
      exifReport: None,
      sessionId: Some(sessionId),
      timeline: [],
      logo: None,
      marketingComment: "",
      marketingPhone1: "",
      marketingPhone2: "",
      marketingForRent: false,
      marketingForSale: false,
      nextSceneSequenceId: 1,
    }
    let projectJson = JsonParsers.Encoders.project(project)

    let input = Ok((sessionId, projectJson))
    let startTime = 0.0

    let mockGetItem = Vi.fn()
    let _ = mockGetItem->Vi.mockReturnValue(Some("mock_token"))

    let mockLocalStorage = {"getItem": mockGetItem}
    Vi.stubGlobal("localStorage", mockLocalStorage)

    let result = await ProjectManager.Logic.processLoadedProjectData(
      input,
      ~loadStartTime=startTime,
    )

    switch result {
    | Ok((sid, _data)) => t->expect(sid)->Expect.toBe(sessionId)
    | Error(msg) => failwith("Expected Ok, got Error: " ++ msg)
    }
  })
})
