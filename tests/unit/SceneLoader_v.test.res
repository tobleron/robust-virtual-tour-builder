// @efficiency: infra-adapter
open Vitest

describe("SceneLoader", () => {
  test("getPanoramaUrl handles Url file type", t => {
    let f = Types.Url("test.webp")
    let url = Types.fileToUrl(f)
    t->expect(url)->Expect.toBe("test.webp")
  })
})
