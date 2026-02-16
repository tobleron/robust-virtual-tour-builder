open Vitest
open VisualPipelineLogic

describe("VisualPipelineLogic", () => {
  let mockItem = (id): Types.timelineItem => {
    id,
    linkId: "l-" ++ id,
    sceneId: "s-" ++ id,
    targetScene: "t-" ++ id,
    transition: "fade",
    duration: 1000,
  }

  test("calculateReorder should return correct indices for forward move", t => {
    let timeline = [mockItem("1"), mockItem("2"), mockItem("3")]
    // Move item "1" to after "2" (drop index 2)
    let result = Logic.calculateReorder(timeline, "1", 2)
    t->expect(result)->Expect.toEqual(Some((0, 1)))
  })

  test("calculateReorder should return correct indices for backward move", t => {
    let timeline = [mockItem("1"), mockItem("2"), mockItem("3")]
    // Move item "3" to before "2" (drop index 1)
    let result = Logic.calculateReorder(timeline, "3", 1)
    t->expect(result)->Expect.toEqual(Some((2, 1)))
  })

  test("calculateReorder should return None if no actual move", t => {
    let timeline = [mockItem("1"), mockItem("2"), mockItem("3")]
    let result = Logic.calculateReorder(timeline, "1", 0)
    t->expect(result)->Expect.toBe(None)
  })
})
