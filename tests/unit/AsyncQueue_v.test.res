open Vitest
open AsyncQueue

describe("AsyncQueue", () => {
  test("computeStatus generates correct status message", t => {
    let activeStatuses = Dict.make()
    Dict.set(activeStatuses, "0", "Processing")
    Dict.set(activeStatuses, "1", "Pending")
    Dict.set(activeStatuses, "2", "__DONE__")

    let msg = computeStatus(activeStatuses, 1, 3)

    t->expect(String.includes(msg, "Processing 1/3"))->Expect.toBe(true)
    // Order of dictionary keys is not guaranteed, checking parts
    t->expect(String.includes(msg, "Processing: 1"))->Expect.toBe(true)
    t->expect(String.includes(msg, "Pending: 1"))->Expect.toBe(true)
    t->expect(String.includes(msg, "__DONE__"))->Expect.toBe(false)
  })

  testAsync("execute processes all items", async t => {
    let items = [1, 2, 3, 4, 5]
    let maxConcurrency = 2
    let processed = []

    let worker = (_index, item, updateStatus) => {
      processed->Array.push(item)
      updateStatus("Working")
      Promise.resolve(item * 2)
    }

    let onProgress = (_pct, _msg) => ()

    let results = await execute(items, maxConcurrency, worker, onProgress)

    t->expect(Array.length(results))->Expect.toBe(5)
    t->expect(Array.length(processed))->Expect.toBe(5)

    t->expect(results)->Expect.toContain(2)
    t->expect(results)->Expect.toContain(4)
    t->expect(results)->Expect.toContain(6)
    t->expect(results)->Expect.toContain(8)
    t->expect(results)->Expect.toContain(10)
  })

  testAsync("execute handles empty list", async t => {
      let items = []
      let worker = (_, _, _) => Promise.resolve(0)
      let onProgress = (_, _) => ()

      let results = await execute(items, 2, worker, onProgress)
      t->expect(Array.length(results))->Expect.toBe(0)
  })
})
