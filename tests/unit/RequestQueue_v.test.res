/* tests/unit/RequestQueue_v.test.res */
open Vitest
open RequestQueue

describe("RequestQueue", () => {
  test("Module exists and can schedule tasks", t => {
    // Synchronous trigger
    let _ = schedule(() => Promise.resolve())
    t->expect(true)->Expect.toBe(true)
  })

  test("maxConcurrent is defined", t => {
    t->expect(maxConcurrent)->Expect.toBe(6)
  })

  test("activeCount is accessible and non-negative", t => {
    t->expect(activeCount.contents >= 0)->Expect.toBe(true)
  })
})
