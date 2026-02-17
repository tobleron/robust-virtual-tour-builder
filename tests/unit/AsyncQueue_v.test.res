@@warning("-3")
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
    t->expect(String.includes(msg, "Processing: 1"))->Expect.toBe(true)
    t->expect(String.includes(msg, "Pending: 1"))->Expect.toBe(true)
    t->expect(String.includes(msg, "__DONE__"))->Expect.toBe(false)
  })

  testAsync("execute processes all items successfully", async t => {
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

    t->expect(results)->Expect.toEqual([
      Success(2),
      Success(4),
      Success(6),
      Success(8),
      Success(10),
    ])
  })

  testAsync("execute captures worker errors", async t => {
    let items = [10, 20, 30]
    let worker = (_index, item, _updateStatus) => {
      if item == 20 {
        Promise.resolve()->Promise.then(_ => {
             let _ = Js.Exn.raiseError("Test Failure")
             Promise.resolve(0)
        })
      } else {
        Promise.resolve(item * 2)
      }
    }
    let onProgress = (_pct, _msg) => ()

    let results = await execute(items, 2, worker, onProgress)

    t->expect(Array.length(results))->Expect.toBe(3)

    t->expect(results)->Expect.toEqual([
      Success(20),
      Failed(1, "Test Failure"),
      Success(60),
    ])
  })

  testAsync("execute handles empty list", async t => {
    let items = []
    let worker = (_, _, _) => Promise.resolve(0)
    let onProgress = (_, _) => ()

    let results = await execute(items, 2, worker, onProgress)
    t->expect(Array.length(results))->Expect.toBe(0)
  })
})
