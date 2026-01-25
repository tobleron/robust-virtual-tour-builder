/* tests/unit/DownloadSystem_v.test.res */
open Vitest
open DownloadSystem

describe("DownloadSystem", () => {
  beforeEach(() => {
    let _ = %raw(`globalThis._originalShowSaveFilePicker = globalThis.window.showSaveFilePicker`)
  })

  afterEach(() => {
    let _ = %raw(`globalThis.window.showSaveFilePicker = globalThis._originalShowSaveFilePicker`)
  })

  test("getExtension: correctly identifies extensions", t => {
    t->expect(getExtension("test.jpg"))->Expect.toBe(".jpg")
    t->expect(getExtension("TEST.PNG"))->Expect.toBe(".png")
    t->expect(getExtension("no_ext"))->Expect.toBe(".dat")
    t->expect(getExtension("archive.tar.gz"))->Expect.toBe(".gz")
    t->expect(getExtension(".config"))->Expect.toBe(".config")
    t->expect(getExtension("file."))->Expect.toBe(".")
  })

  test("saveBlob: executes without error", t => {
    let blob = %raw(`new globalThis.Blob(["test content"], {type: "text/plain"})`)
    // Mock URL.createObjectURL to avoid issues
    let _ = %raw(`globalThis.URL.createObjectURL = () => "blob:mock"`)

    // Should not throw in headless environment
    saveBlob(blob, "test.txt")
    t->expect(true)->Expect.toBe(true)
  })

  testAsync("saveBlobWithConfirmation: handles fallback if API missing", async t => {
    let _ = %raw(`delete globalThis.window.showSaveFilePicker`)
    let blob = %raw(`new globalThis.Blob(["content"])`)

    let result = await saveBlobWithConfirmation(blob, "fallback.txt")
    t->expect(result)->Expect.toEqual(Ok(true))
  })

  testAsync("saveBlobWithConfirmation: handles USER_CANCELLED on AbortError", async t => {
    let _ = %raw(`
      globalThis.window.showSaveFilePicker = () => {
        const err = new Error("AbortError: The user aborted a request.");
        err.name = "AbortError";
        return Promise.reject(err);
      }
    `)
    let blob = %raw(`new globalThis.Blob(["content"])`)

    let result = await saveBlobWithConfirmation(blob, "cancel.txt")
    t->expect(result)->Expect.toEqual(Error("USER_CANCELLED"))
  })

  testAsync("saveBlobWithConfirmation: handles successful native save", async t => {
    let _ = %raw(`
      globalThis.window.showSaveFilePicker = async () => ({
        createWritable: async () => ({
          write: async () => {},
          close: async () => {}
        })
      })
    `)
    let blob = %raw(`new globalThis.Blob(["content"])`)

    let result = await saveBlobWithConfirmation(blob, "native.txt")
    t->expect(result)->Expect.toEqual(Ok(true))
  })

  test("downloadZip: should handle null zip safely", t => {
    downloadZip(Nullable.null, "empty.zip")
    t->expect(true)->Expect.toBe(true)
  })
})
