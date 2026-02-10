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

  testAsync("completes and prunes an operation", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id = await startOperation(~operation="TestOp", ~context, ~retryable=true)

    await completeOperation(id)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)

    t->expect(found)->Expect.toBe(None)
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

  testAsync("cleans up failed operations on completion of another operation", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id1 = await startOperation(~operation="FailedOp", ~context, ~retryable=true)
    await failOperation(id1, "Some error")

    let id2 = await startOperation(~operation="SuccessOp", ~context, ~retryable=true)
    await completeOperation(id2)

    let journal = await load()
    let found1 = Belt.Array.getBy(journal.entries, e => e.id == id1)
    let found2 = Belt.Array.getBy(journal.entries, e => e.id == id2)

    t->expect(found1)->Expect.toBe(None)
    t->expect(found2)->Expect.toBe(None)
  })
})
