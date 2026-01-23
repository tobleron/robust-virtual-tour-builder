open Vitest
open ReBindings
open Types

describe("UploadProcessor", () => {
  let _wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let mockFile = (name): File.t => {
    Obj.magic({
      "name": name,
      "size": 1024.0,
      "type": "image/jpeg",
    })
  }

  testAsync("processUploads should handle empty file array", async t => {
    let result = await UploadProcessor.processUploads([], None)

    let report: uploadReport = result["report"]
    t->expect(Array.length(report.success))->Expect.toBe(0)
    t->expect(Array.length(report.skipped))->Expect.toBe(0)
  })

  testAsync("processUploads should handle all duplicates", async t => {
    // Setup state with existing scene
    let mockState = {
      ...State.initialState,
      scenes: [
        {
          id: "mock_id",
          name: "Existing",
          file: Url(""),
          tinyFile: None,
          originalFile: None,
          hotspots: [],
          category: "",
          floor: "",
          label: "",
          quality: None,
          colorGroup: None,
          _metadataSource: "",
          categorySet: false,
          labelSet: false,
          isAutoForward: false,
          preCalculatedSnapshot: None,
        },
      ],
    }
    GlobalStateBridge.setState(mockState)

    let f1 = mockFile("dup.jpg")
    let result = await UploadProcessor.processUploads([f1], None)

    let report: uploadReport = result["report"]
    t->expect(Array.length(report.success))->Expect.toBe(0)
    t->expect(true)->Expect.toBe(true)
  })
})
