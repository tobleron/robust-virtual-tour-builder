/* tests/unit/Exporter_v.test.res */
open Vitest
open Types
open ReBindings

/* Mocks */
let mockScenes: array<scene> = [
  {
    id: "s1",
    name: "scene1",
    file: Url("s1.jpg"),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "cat",
    floor: "1",
    label: "label",
    quality: None,
    colorGroup: None,
    _metadataSource: "test",
    categorySet: true,
    labelSet: true,
    isAutoForward: false,
    preCalculatedSnapshot: None,
  },
]

let _ = describe("Exporter", () => {
  let mockXhrOpen = %raw("vi.fn()")
  let mockXhrSend = %raw("vi.fn()")
  let mockFormDataAppend = %raw("vi.fn()")

  let setGlobal: ('a, string) => unit = %raw("(v, n) => globalThis[n] = v")
  setGlobal(mockXhrOpen, "mockXhrOpen")
  setGlobal(mockXhrSend, "mockXhrSend")
  setGlobal(mockFormDataAppend, "mockFormDataAppend")

  beforeAll(() => {
    /* Global Mocks */
    let _ = %raw(`(function(){
      globalThis.FormData = class {
        append(k, v) { globalThis.mockFormDataAppend(k, v) }
        appendWithFilename(k, v, f) { globalThis.mockFormDataAppend(k, v) }
      };
      
      globalThis.XMLHttpRequest = class {
        constructor() {
            this.upload = { onprogress: null, onload: null };
            this.responseType = "";
            this.response = new Blob(["mock-zip"], {type: "application/zip"});
            this.status = 200;
        }
        open(m, u) { globalThis.mockXhrOpen(m, u) }
        send(d) { 
            globalThis.mockXhrSend(d);
            if(this.onload) this.onload(); 
        }
      };

      globalThis.fetch = async (url) => {
        return {
            ok: true,
            status: 200,
            blob: async () => new Blob(["mock-content"], {type: "text/plain"})
        }
      };
      
      globalThis.Date.now = () => 1000.0;
    })()`)
  })

  beforeEach(() => {
    let _ = %raw("vi.clearAllMocks()")
    GlobalStateBridge.setState(State.initialState)
  })

  test("mocks should be active", t => {
    let fd = FormData.newFormData()
    FormData.append(fd, "test", "val")
    let calls = %raw("mockFormDataAppend.mock.calls")
    t->expect(Array.length(calls) > 0)->Expect.toBe(true)
  })

  testAsync("exportTour should proceed through phases", async t => {
    let progressFn = %raw("vi.fn()")
    let progWrapper = (a, b, c) => progressFn(a, b, c)

    let result = await Exporter.exportTour(mockScenes, Some(progWrapper))

    // Check FormData calls
    let calls: array<array<string>> = %raw("mockFormDataAppend.mock.calls")

    // We expect "html_4k", "pannellum.js", "scene_0" keys to be present in the calls
    let hasHtml4k = Belt.Array.some(calls, args => Belt.Array.get(args, 0) == Some("html_4k"))
    let hasPanJs = Belt.Array.some(calls, args => Belt.Array.get(args, 0) == Some("pannellum.js"))
    let hasScene = Belt.Array.some(calls, args => Belt.Array.get(args, 0) == Some("scene_0"))

    t->expect(hasHtml4k)->Expect.toBe(true)
    t->expect(hasPanJs)->Expect.toBe(true)
    t->expect(hasScene)->Expect.toBe(true)

    t->expect(Result.isOk(result))->Expect.toBe(true)
  })
})
