open Vitest
open OperationJournal

let setup = async () => {
  Dom.Storage2.localStorage->Dom.Storage2.clear
  await IdbBindings.clear()
  let _ = await load()
}

describe("OperationJournal", () => {
  testAsync("starts and persists an operation", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.object([
      ("foo", JsonCombinators.Json.Encode.string("bar")),
    ])
    let id = await startOperation(~operation="TestOp", ~context, ~retryable=true)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)

    t->expect(found->Option.isSome)->Expect.toBe(true)
    let entry = found->Belt.Option.getExn
    t->expect(entry.operation)->Expect.toBe("TestOp")
    t->expect(entry.status)->Expect.toBe(Interrupted)
  })

  testAsync("completes an operation without pruning history", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id = await startOperation(~operation="TestOp", ~context, ~retryable=true)

    await completeOperation(id)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)

    t->expect(found->Option.isSome)->Expect.toBe(true)
    let entry = found->Belt.Option.getExn
    switch entry.status {
    | Completed => t->expect(true)->Expect.toBe(true)
    | _ => t->expect(false)->Expect.toBe(true)
    }
  })

  testAsync("fails an operation and persists failure", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id = await startOperation(~operation="TestOp", ~context, ~retryable=true)

    await failOperation(id, "Something went wrong")

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)

    t->expect(found->Option.isSome)->Expect.toBe(true)
    let entry = found->Belt.Option.getExn

    switch entry.status {
    | Failed(msg) => t->expect(msg)->Expect.toBe("Something went wrong")
    | _ => t->expect(false)->Expect.toBe(true)
    }
  })

  testAsync("getInterrupted returns in-progress operations", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let _ = await startOperation(~operation="InterruptedOp", ~context, ~retryable=true)

    let journal = await load()
    let interrupted = getInterrupted(journal)
    // We expect at least 1, but might have 2 if emergency queue triggered (synthetic + actual)
    t->expect(Array.length(interrupted) >= 1)->Expect.toBe(true)
    t
    ->expect((interrupted->Belt.Array.get(0)->Belt.Option.getExn).operation)
    ->Expect.toBe("InterruptedOp")
  })

  testAsync("retains terminal outcomes for deterministic replay history", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id1 = await startOperation(~operation="FailedOp", ~context, ~retryable=true)
    await failOperation(id1, "Some error")

    let id2 = await startOperation(~operation="SuccessOp", ~context, ~retryable=true)
    await completeOperation(id2)

    let journal = await load()
    let found1 = Belt.Array.getBy(journal.entries, e => e.id == id1)
    let found2 = Belt.Array.getBy(journal.entries, e => e.id == id2)

    t->expect(found1->Option.isSome)->Expect.toBe(true)
    t->expect(found2->Option.isSome)->Expect.toBe(true)
  })

  testAsync("flushAllInFlight should persist all in-flight operations", async t => {
    await setup()

    // Mock localStorage
    let _ = %raw(`
      (() => {
        let store = {};
        globalThis.localStorage = {
          getItem: (key) => store[key] || null,
          setItem: (key, value) => { store[key] = value.toString(); },
          removeItem: (key) => { delete store[key]; },
          clear: () => { store = {}; }
        };
      })()
    `)

    let context = JsonCombinators.Json.Encode.null

    // Start multiple operations
    let id1 = await startOperation(~operation="Op1", ~context, ~retryable=true)
    let id2 = await startOperation(~operation="Op2", ~context, ~retryable=true)

    let emergencyQueueKey = JournalTypes.emergencyQueueKey

    // Clear localStorage to simulate need for flush
    Dom.Storage2.localStorage->Dom.Storage2.removeItem(emergencyQueueKey)

    // Call flushAllInFlight
    flushAllInFlight()

    // Verify they are back
    let rawFinal = Dom.Storage2.localStorage->Dom.Storage2.getItem(emergencyQueueKey)
    t->expect(rawFinal->Belt.Option.isSome)->Expect.toBe(true)

    let json = JsonCombinators.Json.parse(rawFinal->Belt.Option.getExn)->Belt.Result.getExn
    let snapshots =
      JsonCombinators.Json.decode(
        json,
        JsonCombinators.Json.Decode.array(JournalTypes.emergencySnapshotDecoder),
      )->Belt.Result.getExn

    t->expect(Array.length(snapshots))->Expect.toBe(2)
    let ids = snapshots->Belt.Array.map(s => s.id)
    t->expect(ids)->Expect.toContain(id1)
    t->expect(ids)->Expect.toContain(id2)
  })
})
