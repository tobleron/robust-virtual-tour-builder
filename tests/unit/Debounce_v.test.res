open Vitest

describe("Debounce", () => {
  testAsync("should debounce trailing calls", async t => {
    let callCount = ref(0)
    let fn = async arg => {
      callCount := callCount.contents + 1
      arg
    }

    let debounced = Debounce.make(~fn, ~wait=50, ~trailing=true)

    let _ = debounced.call(1)
    let _ = debounced.call(2)
    let _ = debounced.call(3)

    // Wait for debounce
    await Promise.make(
      (resolve, _) => {
        let _ = setTimeout(resolve, 100)
      },
    )

    t->expect(callCount.contents)->Expect.toBe(1)
  })

  testAsync("should handle leading edge", async t => {
    let callCount = ref(0)
    let fn = async () => {
      callCount := callCount.contents + 1
      ()
    }
    let debounced = Debounce.make(~fn, ~wait=50, ~leading=true, ~trailing=false)

    let _ = debounced.call() // Should call immediately
    let _ = debounced.call() // Should be ignored

    t->expect(callCount.contents)->Expect.toBe(1)

    await Promise.make(
      (resolve, _) => {
        let _ = setTimeout(resolve, 100)
      },
    )

    // Call again after wait
    let _ = debounced.call()
    t->expect(callCount.contents)->Expect.toBe(2)
  })
})
