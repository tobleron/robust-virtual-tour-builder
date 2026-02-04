open Vitest

let _ = describe("RecoveryManager", () => {
  let _ = testAsync("registers and retries handler", async t => {
    let called = ref(false)
    let handler = (_entry) => {
      called := true
      Promise.resolve(true)
    }

    RecoveryManager.registerHandler("TestOp", handler)

    let entry: OperationJournal.journalEntry = {
      id: "1",
      operation: "TestOp",
      status: Pending,
      startTime: 123.0,
      endTime: None,
      context: JsonCombinators.Json.Encode.null,
      retryable: true
    }

    let _ = await RecoveryManager.retry(entry)
    t->expect(called.contents)->Expect.toBe(true)
  })
})
