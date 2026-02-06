/* tests/unit/TransitionLock_v.test.res */
open Vitest

describe("TransitionLock", () => {
  beforeEach(() => {
    TransitionLock.release("cleanup")
  })

  test("Initial state is idle", t => {
    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
  })

  test("Acquire lock successfully", t => {
    let result = TransitionLock.acquire("test", Loading("scene1"))
    t->expect(result)->Expect.toEqual(Ok())
    t->expect(TransitionLock.isIdle())->Expect.toBe(false)
  })

  test("Reject second acquisition", t => {
    let _ = TransitionLock.acquire("test1", Loading("scene1"))
    let result = TransitionLock.acquire("test2", Loading("scene2"))
    t->expect(result)->Expect.toEqual(Error("Transition lock occupied by Loading(scene1)"))
  })

  test("Release lock", t => {
    let _ = TransitionLock.acquire("test", Loading("scene1"))
    TransitionLock.release("test")
    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
  })

  test("Transition lock state", t => {
    let _ = TransitionLock.acquire("test", Loading("scene1"))
    TransitionLock.transition("test", Swapping("scene1"))
    t->expect(TransitionLock.isSwapping())->Expect.toBe(true)
  })

  test("onIdle callbacks", t => {
    let called = ref(false)
    let _ = TransitionLock.acquire("test", Loading("scene1"))
    TransitionLock.onIdle(
      () => {
        called := true
      },
    )
    t->expect(called.contents)->Expect.toBe(false)
    TransitionLock.release("test")
    t->expect(called.contents)->Expect.toBe(true)
  })

  test("onIdle immediate execution if idle", t => {
    let called = ref(false)
    TransitionLock.onIdle(
      () => {
        called := true
      },
    )
    t->expect(called.contents)->Expect.toBe(true)
  })
})
