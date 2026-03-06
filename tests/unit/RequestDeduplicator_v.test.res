open Vitest

let wait = (ms: int): promise<unit> =>
  Promise.make((resolve, _) => {
    let _ = ReBindings.Window.setTimeout(() => resolve(), ms)
  })

describe("RequestDeduplicator", () => {
  testAsync("coalesces concurrent requests with same key", async t => {
    RequestDeduplicator.clear()
    let invoked = ref(0)

    let task = () => {
      invoked := invoked.contents + 1
      wait(25)->Promise.then(_ => Promise.resolve("ok"))
    }

    let p1 = RequestDeduplicator.run(~key="save:123", ~task)
    let p2 = RequestDeduplicator.run(~key="save:123", ~task)
    let results = await Promise.all([p1, p2])

    t->expect(invoked.contents)->Expect.toBe(1)
    t->expect(Array.length(results))->Expect.toBe(2)
    t->expect(Array.get(results, 0)->Option.getOrThrow)->Expect.toBe("ok")
    t->expect(Array.get(results, 1)->Option.getOrThrow)->Expect.toBe("ok")
  })

  testAsync("allows new request after previous one resolves", async t => {
    RequestDeduplicator.clear()
    let invoked = ref(0)

    let task = () => {
      invoked := invoked.contents + 1
      wait(5)->Promise.then(_ => Promise.resolve("done"))
    }

    let _ = await RequestDeduplicator.run(~key="export:abc", ~task)
    let _ = await RequestDeduplicator.run(~key="export:abc", ~task)

    t->expect(invoked.contents)->Expect.toBe(2)
  })
})
