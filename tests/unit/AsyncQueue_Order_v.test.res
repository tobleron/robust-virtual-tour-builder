open Vitest
open AsyncQueue

describe("AsyncQueue Order", () => {
  testAsync("execute processes items in order regardless of completion time", async t => {
    let items = [100, 50, 10, 200, 30] // Delays in ms
    let maxConcurrency = 5

    // Worker that waits for the specified duration then returns the duration string
    let worker = (_index, duration, _updateStatus) => {
      let promise = Promise.make(
        (resolve, _reject) => {
          let _ = setTimeout(
            () => {
              resolve(Belt.Int.toString(duration))
            },
            duration,
          )
        },
      )
      promise
    }

    let onProgress = (_pct, _msg) => ()

    let results = await execute(items, maxConcurrency, worker, onProgress)

    // Expected: ["100", "50", "10", "200", "30"]
    // Actual (buggy): ["10", "30", "50", "100", "200"] (ordered by completion)

    t->expect(results)->Expect.toEqual(["100", "50", "10", "200", "30"])
  })
})
