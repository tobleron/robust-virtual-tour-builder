open Vitest
open NetworkStatus

describe("NetworkStatus", () => {
  test("isOnline returns a boolean", t => {
    let online = isOnline()
    // In jsdom environment, navigator.onLine is usually true
    t->expect(online)->Expect.toBe(true)
  })

  test("subscribe allows subscription", t => {
    let callCount = ref(0)
    let unsubscribe = subscribe(
      _ => {
        callCount := callCount.contents + 1
      },
    )

    unsubscribe()
    t->expect(callCount.contents)->Expect.toBe(0)
  })
})
