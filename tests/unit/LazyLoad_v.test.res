// @efficiency: infra-adapter
open Vitest

describe("LazyLoad", () => {
  test("checkGlobal works correctly", t => {
    let _ = %raw(`window.testGlobal = true`)
    t->expect(LazyLoad.checkGlobal("testGlobal"))->Expect.toBe(true)
    t->expect(LazyLoad.checkGlobal("nonExistent"))->Expect.toBe(false)
  })

  testAsync("loadPannellum resolves immediately if already loaded", async t => {
    LazyLoad.pannellumLoaded := true
    await LazyLoad.loadPannellum()
    t->expect(true)->Expect.toBe(true)
  })

  testAsync("loadJSZip resolves immediately if already loaded", async t => {
    LazyLoad.jszipLoaded := true
    await LazyLoad.loadJSZip()
    t->expect(true)->Expect.toBe(true)
  })

  testAsync("loadFileSaver resolves immediately if already loaded", async t => {
    LazyLoad.fileSaverLoaded := true
    await LazyLoad.loadFileSaver()
    t->expect(true)->Expect.toBe(true)
  })
})
