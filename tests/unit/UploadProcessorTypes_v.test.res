open Vitest
open UploadProcessorTypes

describe("UploadProcessorTypes", () => {
  test("should define uploadItem correctly", t => {
    let mockFile: ReBindings.File.t = Obj.magic({"name": "test.jpg"})
    let item: uploadItem = {
      id: Nullable.make("123"),
      original: mockFile,
      error: None,
      preview: None,
      tiny: None,
      quality: None,
      metadata: None,
      colorGroup: None,
    }
    t->expect(Nullable.toOption(item.id))->Expect.toEqual(Some("123"))
    t->expect(item.original)->Expect.toEqual(mockFile)
  })

  test("should allow mutation of uploadItem fields", t => {
    let mockFile: ReBindings.File.t = Obj.magic({"name": "test.jpg"})
    let item: uploadItem = {
      id: Nullable.null,
      original: mockFile,
      error: None,
      preview: None,
      tiny: None,
      quality: None,
      metadata: None,
      colorGroup: None,
    }

    item.error = Some("error")
    t->expect(item.error)->Expect.toEqual(Some("error"))

    item.colorGroup = Some("blue")
    t->expect(item.colorGroup)->Expect.toEqual(Some("blue"))
  })

  test("should define processResult correctly", t => {
    let report: Types.uploadReport = {
      success: ["img1.jpg"],
      skipped: [],
    }
    let res: processResult = {
      qualityResults: [],
      duration: "10s",
      report,
    }
    t->expect(res.duration)->Expect.toBe("10s")
    t->expect(res.report.success)->Expect.toEqual(["img1.jpg"])
  })
})
