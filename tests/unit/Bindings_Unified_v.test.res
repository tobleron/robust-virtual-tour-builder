open Vitest
open ReBindings

module Vi = {
  type mock
  @val @scope("vi") external stubGlobal: (string, 'a) => unit = "stubGlobal"
  @val @scope("vi") external unstubAllGlobals: unit => unit = "unstubAllGlobals"
  @val @scope("vi") external fn: unit => mock = "fn"
  @val @scope("vi") external fn1: ('a => 'b) => mock = "fn"
  @send external mockReturnValue: (mock, 'a) => mock = "mockReturnValue"
  @send external mockImplementation: (mock, 'a) => mock = "mockImplementation"
  @val @scope("vi") external mockModule: (string, unit => 'a) => unit = "mock"
  @get external calls: mock => array<array<'a>> = "calls"
  @get external mock: mock => {..} = "mock"
}

beforeEach(() => {
  Vi.unstubAllGlobals()
})

afterEach(() => {
  Vi.unstubAllGlobals()
})

describe("BrowserBindings", () => {
  test("Blob binding works", t => {
    let mockBlob = Vi.fn()
    Vi.stubGlobal("Blob", mockBlob)

    let _ = Blob.newBlob(["content"], {"type": "text/plain"})

    // Check if mock was called
    // Since we can't easily check arguments with simple bindings without more complex interop,
    // we'll at least verify the binding didn't crash and called the global.
    // Ideally we verify call arguments.
    let calls = (mockBlob->Vi.mock)["calls"]
    t->expect(Array.length(calls))->Expect.toBe(1)
  })

  test("File binding works", t => {
    let mockFile = Vi.fn()
    Vi.stubGlobal("File", mockFile)

    let _ = File.newFile(["content"], "test.txt", {"type": "text/plain"})

    let calls = (mockFile->Vi.mock)["calls"]
    t->expect(Array.length(calls))->Expect.toBe(1)
  })

  test("JSWeakMap binding works", t => {
    let mockWeakMap = Vi.fn()
    let mockGet = Vi.fn()
    let mockSet = Vi.fn()

    // Mock instance methods
    let mockInstance = {
      "get": mockGet,
      "set": mockSet,
    }

    let mockImpl = %raw(`function(i) { return function() { return i } }`)(mockInstance)
    let _ = mockWeakMap->Vi.mockImplementation(mockImpl)
    Vi.stubGlobal("WeakMap", mockWeakMap)

    let wm = JSWeakMap.make()

    // Test set
    let key = {"id": 1}
    let value = "test"
    JSWeakMap.set(wm, key, value)

    let setCalls = (mockSet->Vi.mock)["calls"]
    t->expect(Array.length(setCalls))->Expect.toBe(1)
  })

  test("AbortController binding works", t => {
    let mockAbortController = Vi.fn()
    let mockAbort = Vi.fn()
    let mockSignal = {"aborted": false}

    let mockInstance = {
      "abort": mockAbort,
      "signal": mockSignal,
    }

    let mockImpl = %raw(`function(i) { return function() { return i } }`)(mockInstance)
    let _ = mockAbortController->Vi.mockImplementation(mockImpl)
    Vi.stubGlobal("AbortController", mockAbortController)

    let ac = AbortController.newAbortController()
    let _ = AbortController.signal(ac)
    AbortController.abort(ac)

    let abortCalls = (mockAbort->Vi.mock)["calls"]
    t->expect(Array.length(abortCalls))->Expect.toBe(1)
  })

  test("JSZip binding works", t => {
    let mockJSZip = Vi.fn()
    let mockFile = Vi.fn()
    let mockGenerateAsync = Vi.fn()

    let mockInstance = {
      "file": mockFile,
      "generateAsync": mockGenerateAsync,
    }

    // Mock constructor
    let mockImpl = %raw(`function(i) { return function() { return i } }`)(mockInstance)
    let _ = mockJSZip->Vi.mockImplementation(mockImpl)

    // Mock static method
    let mockLoadAsync = Vi.fn()
    let _ = %raw(`function(clazz, method) { clazz.loadAsync = method }`)(mockJSZip, mockLoadAsync)

    Vi.stubGlobal("JSZip", mockJSZip)

    // Test create
    let zip = JSZip.create()

    // Test file
    let _ = JSZip.file(zip, "hello.txt")
    let fileCalls = (mockFile->Vi.mock)["calls"]
    t->expect(Array.length(fileCalls))->Expect.toBe(1)

    // Test loadAsync
    let blob = Obj.magic(1)
    let _ = JSZip.loadAsync(blob)
    let loadCalls = (mockLoadAsync->Vi.mock)["calls"]
    t->expect(Array.length(loadCalls))->Expect.toBe(1)
  })
})

describe("DomBindings", () => {
  test("Document binding works", t => {
    let mockGetElementById = Vi.fn()
    let mockQuerySelector = Vi.fn()
    let mockCreateElement = Vi.fn()
    let mockQuerySelectorEl = Vi.fn()

    let mockElement = {
      "id": "el",
      "querySelector": mockQuerySelectorEl,
    }

    let _ = mockGetElementById->Vi.mockReturnValue(Nullable.make(mockElement))
    let _ = mockQuerySelector->Vi.mockReturnValue(Nullable.make(mockElement))
    let _ = mockCreateElement->Vi.mockReturnValue(mockElement)

    let mockDocument = {
      "getElementById": mockGetElementById,
      "querySelector": mockQuerySelector,
      "createElement": mockCreateElement,
      "body": mockElement,
    }

    Vi.stubGlobal("document", mockDocument)

    let _ = Dom.getElementById("test")
    t->expect(Array.length((mockGetElementById->Vi.mock)["calls"]))->Expect.toBe(1)

    // Test querySelector on element
    let _ = Dom.querySelector(Obj.magic(mockElement), ".class")
    t->expect(Array.length((mockQuerySelectorEl->Vi.mock)["calls"]))->Expect.toBe(1)
  })
})

describe("ReBindings.Idb_", () => {
  test("Modules are accessible", _ => {
    let _ = (ReBindings.Idb_.get, ReBindings.Idb_.set, ReBindings.Idb_.del, ReBindings.Idb_.clear)
  })
})

describe("GraphicsBindings", () => {
  test("Canvas binding works", t => {
    let mockGetContext = Vi.fn()
    let mockContext = {"fillStyle": ""}

    let _ = mockGetContext->Vi.mockReturnValue(mockContext)

    // Canvas.getContext2d sends "getContext"
    let mockCanvas = {"getContext": mockGetContext}

    let ctx = Canvas.getContext2d(Obj.magic(mockCanvas), "2d", {"alpha": false})
    t->expect(Array.length((mockGetContext->Vi.mock)["calls"]))->Expect.toBe(1)

    // Set fill style
    Canvas.setFillStyle(Obj.magic(ctx), "red")
    t->expect(Obj.magic(ctx)["fillStyle"])->Expect.toBe("red")
  })
})

describe("ViewerBindings", () => {
  test("Pannellum binding works", t => {
    let mockViewer = Vi.fn()
    let mockGetPitch = Vi.fn()
    let mockViewerInstance = {"getPitch": mockGetPitch}

    // pannellum.viewer returns instance
    let _ = mockViewer->Vi.mockReturnValue(mockViewerInstance)

    let mockPannellum = {"viewer": mockViewer}
    Vi.stubGlobal("pannellum", mockPannellum)

    let v = Pannellum.viewer("container", {"autoLoad": true})
    t->expect(Array.length((mockViewer->Vi.mock)["calls"]))->Expect.toBe(1)

    // Viewer methods
    let _ = mockGetPitch->Vi.mockReturnValue(10.0)

    let p = Viewer.getPitch(v)
    t->expect(p)->Expect.toBe(10.0)
  })
})

describe("WebApiBindings", () => {
  testAsync("Fetch works", async t => {
    let mockFetch = Vi.fn()
    let mockJson = Vi.fn()
    let mockResponse = {
      "ok": true,
      "json": mockJson,
      "text": Vi.fn(),
    }
    // json needs to return promise
    let _ = mockJson->Vi.mockReturnValue(Promise.resolve({"data": 1}))

    let _ = mockFetch->Vi.mockReturnValue(Promise.resolve(mockResponse))
    Vi.stubGlobal("fetch", mockFetch)

    let response = await Fetch.fetchSimple("url")
    t->expect(Array.length((mockFetch->Vi.mock)["calls"]))->Expect.toBe(1)

    let data = await Fetch.json(response)
    t->expect(data)->Expect.toEqual({"data": 1})
  })

  test("URL works", t => {
    let mockCreateObjectURL = Vi.fn()
    let _ = mockCreateObjectURL->Vi.mockReturnValue("blob:url")

    let mockURL = {"createObjectURL": mockCreateObjectURL}
    Vi.stubGlobal("URL", mockURL)

    let url = URL.createObjectURL("blob")
    t->expect(url)->Expect.toBe("blob:url")
  })

  test("FormData works", t => {
    let mockAppend = Vi.fn()
    let mockInstance = {"append": mockAppend}

    let mockImpl = %raw(`function(i) { return function() { return i } }`)(mockInstance)

    let mockFormData = Vi.fn()
    let _ = mockFormData->Vi.mockImplementation(mockImpl)

    Vi.stubGlobal("FormData", mockFormData)

    let fd = FormData.newFormData()
    FormData.append(fd, "key", "value")

    t->expect(Array.length((mockAppend->Vi.mock)["calls"]))->Expect.toBe(1)
  })
})
