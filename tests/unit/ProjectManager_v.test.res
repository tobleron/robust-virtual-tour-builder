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

let decodeValidationReport = (projectJson: JSON.t): option<SharedTypes.validationReport> =>
  switch JsonCombinators.Json.decode(
    projectJson,
    JsonCombinators.Json.Decode.field("validationReport", JsonParsers.Shared.validationReport),
  ) {
  | Ok(report) => Some(report)
  | Error(_) => None
  }

let attachValidationReport = (
  projectJson: JSON.t,
  ~brokenLinksRemoved: int=0,
  ~orphanedScenes: array<string>=[],
  ~unusedFiles: array<string>=[],
  ~warnings: array<string>=[],
  ~errors: array<string>=[],
) => {
  let mergeValidationReport: (JSON.t, JSON.t) => JSON.t =
    %raw(`(projectJson, validationReport) => ({...projectJson, validationReport})`)
  let validationReport =
    JsonCombinators.Json.Encode.object([
      ("brokenLinksRemoved", JsonCombinators.Json.Encode.int(brokenLinksRemoved)),
      ("orphanedScenes", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(orphanedScenes)),
      ("unusedFiles", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(unusedFiles)),
      ("warnings", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(warnings)),
      ("errors", JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.string)(errors)),
    ])
  mergeValidationReport(projectJson, validationReport)
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
    let projectWithValidation = attachValidationReport(projectJson)

    let input = Ok((sessionId, projectWithValidation))
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
    | Ok((sid, data)) =>
      t->expect(sid)->Expect.toBe(sessionId)
      let report = decodeValidationReport(data)
      t->expect(report->Option.isSome)->Expect.toBe(true)
    | Error(msg) => failwith("Expected Ok, got Error: " ++ msg)
    }
  })

  testAsync("processLoadedProjectData keeps validation report warnings for UI summary", async t => {
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
    let projectWithValidation = attachValidationReport(
      projectJson,
      ~warnings=["Scene order auto-normalized"],
      ~brokenLinksRemoved=2,
    )

    let result = await ProjectManager.Logic.processLoadedProjectData(
      Ok((sessionId, projectWithValidation)),
      ~loadStartTime=0.0,
    )

    switch result {
    | Ok((_sid, data)) =>
      let report = decodeValidationReport(data)->Option.getOrThrow
      t->expect(report.brokenLinksRemoved)->Expect.toBe(2)
      t->expect(Array.length(report.warnings))->Expect.toBe(1)
    | Error(msg) => failwith("Expected Ok, got Error: " ++ msg)
    }
  })

  testAsync("processLoadedProjectData blocks activation on validation errors", async t => {
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
    let projectWithValidation = attachValidationReport(
      projectJson,
      ~errors=["hotspot target points to missing scene"],
    )

    let input = Ok((sessionId, projectWithValidation))
    let result = await ProjectManager.Logic.processLoadedProjectData(input, ~loadStartTime=0.0)

    switch result {
    | Ok(_) => failwith("Expected Error, got Ok")
    | Error(msg) =>
      t->expect(msg->String.includes("Project verification failed"))->Expect.toBe(true)
    }
  })
})
