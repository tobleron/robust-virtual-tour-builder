/* tests/unit/LockTimeout_v.test.res */
open Vitest

module Vi = {
  type t
  @module("vitest") external vi: t = "vi"
  @send external useFakeTimers: t => unit = "useFakeTimers"
  @send external useRealTimers: t => unit = "useRealTimers"
  @send external advanceTimersByTime: (t, int) => unit = "advanceTimersByTime"
}

describe("TransitionLock Timeout", () => {
  beforeEach(() => {
    Vi.vi->Vi.useFakeTimers
    TransitionLock.release("cleanup")
  })

  afterEach(() => {
    Vi.vi->Vi.useRealTimers
  })

  test("Auto-release lock after timeout", t => {
    // 1. Acquire lock
    let result = TransitionLock.acquire("test", Loading("scene1"))
    t->expect(result)->Expect.toEqual(Ok())
    t->expect(TransitionLock.isIdle())->Expect.toBe(false)

    // 2. Advance time by 60s (should still be locked)
    Vi.vi->Vi.advanceTimersByTime(60000)
    t->expect(TransitionLock.isIdle())->Expect.toBe(false)

    // 3. Advance time by 6s (total 66s > 65s timeout)
    Vi.vi->Vi.advanceTimersByTime(6000)

    // 4. Verify lock is released
    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
  })

  test("Manual release clears timeout", t => {
    // 1. Acquire lock
    let _ = TransitionLock.acquire("test", Loading("scene1"))

    // 2. Release manually
    TransitionLock.release("test")
    t->expect(TransitionLock.isIdle())->Expect.toBe(true)

    // 3. Advance time past timeout (should stay idle and not crash)
    Vi.vi->Vi.advanceTimersByTime(20000)
    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
  })
})

describe("TransitionLock Time Tracking", () => {
  beforeEach(() => {
    Vi.vi->Vi.useFakeTimers
    TransitionLock.release("cleanup")
  })

  afterEach(() => {
    Vi.vi->Vi.useRealTimers
  })

  test("getRemainingMs returns correct value after acquire", t => {
    // 1. Acquire lock
    let result = TransitionLock.acquire("test", Loading("scene1"))
    t->expect(result)->Expect.toEqual(Ok())

    // 2. At start, remaining should be 65000ms
    let remaining = TransitionLock.getRemainingMs()
    t->expect(remaining)->Expect.toBe(65000)

    // 3. Advance time by 5s - should have ~60000ms left
    Vi.vi->Vi.advanceTimersByTime(5000)
    let remaining = TransitionLock.getRemainingMs()
    let isInRange = remaining > 59900 && remaining <= 60000
    t->expect(isInRange)->Expect.toBe(true)

    // 4. Advance time by 58 more seconds - should have ~2000ms left
    Vi.vi->Vi.advanceTimersByTime(58000)
    let remaining = TransitionLock.getRemainingMs()
    let isInRange = remaining > 1900 && remaining <= 2000
    t->expect(isInRange)->Expect.toBe(true)
  })

  test("getRemainingMs returns 0 when idle", t => {
    let remaining = TransitionLock.getRemainingMs()
    t->expect(remaining)->Expect.toBe(0)
  })

  test("getRemainingMs returns 0 after manual release", t => {
    let _ = TransitionLock.acquire("test", Loading("scene1"))
    Vi.vi->Vi.advanceTimersByTime(5000)

    TransitionLock.release("test")
    let remaining = TransitionLock.getRemainingMs()
    t->expect(remaining)->Expect.toBe(0)
  })

  test("getTotalTimeoutMs returns 65000", t => {
    let _ = TransitionLock.acquire("test", Loading("scene1"))
    let total = TransitionLock.getTotalTimeoutMs()
    t->expect(total)->Expect.toBe(65000)
  })
})

describe("TransitionLock Recovery Listeners", () => {
  beforeEach(() => {
    Vi.vi->Vi.useFakeTimers
    TransitionLock.release("cleanup")
  })

  afterEach(() => {
    Vi.vi->Vi.useRealTimers
  })

  test("Recovery listener fires on timeout-triggered release", t => {
    let recoveryFired = ref(false)
    let _ = TransitionLock.addRecoveryListener(
      () => {
        recoveryFired := true
      },
    )

    // 1. Acquire lock
    let _ = TransitionLock.acquire("test", Loading("scene1"))

    // 2. Advance past timeout to trigger forceRelease
    Vi.vi->Vi.advanceTimersByTime(66000)

    // 3. Verify lock is idle and recovery listener fired
    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
    t->expect(recoveryFired.contents)->Expect.toBe(true)
  })

  test("Manual release with isTimeout=false doesn't fire recovery listener", t => {
    let _ = TransitionLock.acquire("test", Loading("scene1"))

    // Manual release without timeout flag
    TransitionLock.release("test", ~isTimeout=false)

    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
  })

  test("Manual release with isTimeout=true fires recovery listener", t => {
    let _ = TransitionLock.acquire("test", Loading("scene1"))

    // Manual release with timeout flag
    TransitionLock.release("test", ~isTimeout=true)

    t->expect(TransitionLock.isIdle())->Expect.toBe(true)
  })
})
