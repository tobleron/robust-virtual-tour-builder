open Vitest
open VisualPipelineLogic

describe("VisualPipelineLogic V2", () => {
  test("Styles module should export a non-empty CSS string", t => {
    t->expect(String.length(Styles.styles) > 0)->Expect.toBe(true)
  })
})
