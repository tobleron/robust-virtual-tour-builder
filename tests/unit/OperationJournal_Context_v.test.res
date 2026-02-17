open Vitest
open OperationJournal

let setup = async () => {
  Dom.Storage2.localStorage->Dom.Storage2.clear
  await IdbBindings.clear()
  let _ = await load()
}

describe("OperationJournal Context Merging", () => {
  testAsync("updates context by merging JSON objects", async t => {
    await setup()

    // Initial context: {foo: "bar"}
    let initialContext = JsonCombinators.Json.Encode.object([
      ("foo", JsonCombinators.Json.Encode.string("bar")),
    ])
    let id = await startOperation(~operation="TestOp", ~context=initialContext, ~retryable=true)

    // Update with {baz: "qux"}
    let updateData = JsonCombinators.Json.Encode.object([
      ("baz", JsonCombinators.Json.Encode.string("qux")),
    ])
    await updateContext(id, updateData)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)
    t->expect(found->Option.isSome)->Expect.toBe(true)
    let entry = found->Belt.Option.getExn

    // Decode and verify merged result {foo: "bar", baz: "qux"}
    let decoder = JsonCombinators.Json.Decode.object(
      field => {
        (
          field.optional("foo", JsonCombinators.Json.Decode.string),
          field.optional("baz", JsonCombinators.Json.Decode.string),
        )
      },
    )

    switch JsonCombinators.Json.decode(entry.context, decoder) {
    | Ok((foo, baz)) =>
      t->expect(foo)->Expect.toBe(Some("bar"))
      t->expect(baz)->Expect.toBe(Some("qux"))
    | Error(msg) => {
        Console.error("Failed to decode context: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  testAsync("overwrites context if new context is not an object", async t => {
    await setup()

    // Initial context: {foo: "bar"}
    let initialContext = JsonCombinators.Json.Encode.object([
      ("foo", JsonCombinators.Json.Encode.string("bar")),
    ])
    let id = await startOperation(~operation="TestOp", ~context=initialContext, ~retryable=true)

    // Update with null (not an object)
    let updateData = JsonCombinators.Json.Encode.null
    await updateContext(id, updateData)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)
    let entry = found->Belt.Option.getExn

    // Verify it is null
    let isNull = switch entry.context {
    | Null => true
    | _ => false
    }
    t->expect(isNull)->Expect.toBe(true)
  })

  testAsync("overwrites context if old context is not an object", async t => {
    await setup()

    // Initial context: null
    let initialContext = JsonCombinators.Json.Encode.null
    let id = await startOperation(~operation="TestOp", ~context=initialContext, ~retryable=true)

    // Update with {foo: "bar"}
    let updateData = JsonCombinators.Json.Encode.object([
      ("foo", JsonCombinators.Json.Encode.string("bar")),
    ])
    await updateContext(id, updateData)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)
    let entry = found->Belt.Option.getExn

    // Verify it is {foo: "bar"}
    let decoder = JsonCombinators.Json.Decode.object(
      field => {
        field.optional("foo", JsonCombinators.Json.Decode.string)
      },
    )

    switch JsonCombinators.Json.decode(entry.context, decoder) {
    | Ok(foo) => t->expect(foo)->Expect.toBe(Some("bar"))
    | Error(msg) => {
        Console.error("Failed to decode context: " ++ msg)
        Console.error("Failed to decode context: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  testAsync("updates existing fields in merged object", async t => {
    await setup()

    // Initial context: {count: 1, name: "test"}
    let initialContext = JsonCombinators.Json.Encode.object([
      ("count", JsonCombinators.Json.Encode.int(1)),
      ("name", JsonCombinators.Json.Encode.string("test")),
    ])
    let id = await startOperation(~operation="TestOp", ~context=initialContext, ~retryable=true)

    // Update with {count: 2}
    let updateData = JsonCombinators.Json.Encode.object([
      ("count", JsonCombinators.Json.Encode.int(2)),
    ])
    await updateContext(id, updateData)

    let journal = await load()
    let found = Belt.Array.getBy(journal.entries, e => e.id == id)
    let entry = found->Belt.Option.getExn

    // Verify result {count: 2, name: "test"}
    let decoder = JsonCombinators.Json.Decode.object(
      field => {
        (
          field.optional("count", JsonCombinators.Json.Decode.int),
          field.optional("name", JsonCombinators.Json.Decode.string),
        )
      },
    )

    switch JsonCombinators.Json.decode(entry.context, decoder) {
    | Ok((count, name)) =>
      t->expect(count)->Expect.toBe(Some(2))
      t->expect(name)->Expect.toBe(Some("test"))
    | Error(msg) => {
        Console.error("Failed to decode context: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
