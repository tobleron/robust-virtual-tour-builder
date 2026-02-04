open Vitest
open OperationJournal

let setup = async () => {
  await IdbBindings.clear()
  let _ = await load()
}

describe("OperationJournal", () => {
  testAsync("starts and persists an operation", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.object([
      ("foo", JsonCombinators.Json.Encode.string("bar")),
    ])
    let id = startOperation(~operation="TestOp", ~context, ~retryable=true)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)

    t->expect(found->Option.isSome)->Expect.toBe(true)
    let entry = found->Belt.Option.getExn
    t->expect(entry.operation)->Expect.toBe("TestOp")
    t->expect(entry.status)->Expect.toBe(InProgress)
  })

  testAsync("completes and prunes an operation", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id = startOperation(~operation="TestOp", ~context, ~retryable=true)

    completeOperation(id)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)

    t->expect(found)->Expect.toBe(None)
  })

  testAsync("fails an operation and persists failure", async t => {
    await setup()
    let context = JsonCombinators.Json.Encode.null
    let id = startOperation(~operation="TestOp", ~context, ~retryable=true)

    failOperation(id, "Something went wrong")

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
    let _ = startOperation(~operation="InterruptedOp", ~context, ~retryable=true)

    let journal = await load()
    let interrupted = getInterrupted(journal)

    t->expect(Array.length(interrupted))->Expect.toBe(1)
    t
    ->expect((interrupted->Belt.Array.get(0)->Belt.Option.getExn).operation)
    ->Expect.toBe("InterruptedOp")
  })
})
