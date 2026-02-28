open Vitest

describe("CircuitBreaker", () => {
  let cfg = (
    ~failureThreshold: int,
    ~successThreshold: int,
    ~timeout: int,
  ): CircuitBreaker.config => {
    failureThreshold,
    successThreshold,
    timeout,
    onStateTransition: None,
    onCircuitOpen: None,
  }

  test("starts in Closed state", t => {
    let cb = CircuitBreaker.make()
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Closed)
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(true)
  })

  test("transitions to Open after failure threshold", t => {
    let cb = CircuitBreaker.make(
      ~config=cfg(~failureThreshold=3, ~successThreshold=1, ~timeout=1000),
    )
    CircuitBreaker.recordFailure(cb)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Closed)
    CircuitBreaker.recordFailure(cb)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Closed)
    CircuitBreaker.recordFailure(cb)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Open)
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(false)
  })

  test("transitions to HalfOpen after timeout", t => {
    let _ = Vitest.Vi.useFakeTimers()
    let cb = CircuitBreaker.make(
      ~config=cfg(~failureThreshold=1, ~successThreshold=1, ~timeout=1000),
    )
    CircuitBreaker.recordFailure(cb)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Open)

    // Advance time
    let _ = Vitest.Vi.advanceTimersByTime(1100)

    // First call allows execution and transitions to HalfOpen
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(true)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(HalfOpen)

    let _ = Vitest.Vi.useRealTimers()
  })

  test("HalfOpen allows only one probe (sequential)", t => {
    let _ = Vitest.Vi.useFakeTimers()
    let cb = CircuitBreaker.make(
      ~config=cfg(~failureThreshold=1, ~successThreshold=2, ~timeout=1000),
    )
    CircuitBreaker.recordFailure(cb)
    let _ = Vitest.Vi.advanceTimersByTime(1100)

    // Probe 1
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(true)
    // Probe 2 (blocked)
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(false)

    // Probe 1 succeeds
    CircuitBreaker.recordSuccess(cb)
    // Still HalfOpen (need 2 successes)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(HalfOpen)

    // Probe 3 (allowed)
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(true)

    // Probe 3 succeeds
    CircuitBreaker.recordSuccess(cb)
    // Now Closed
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Closed)

    let _ = Vitest.Vi.useRealTimers()
  })

  test("HalfOpen transitions to Open on repeated failure", t => {
    let _ = Vitest.Vi.useFakeTimers()
    let cb = CircuitBreaker.make(
      ~config=cfg(~failureThreshold=1, ~successThreshold=2, ~timeout=1000),
    )
    CircuitBreaker.recordFailure(cb)
    let _ = Vitest.Vi.advanceTimersByTime(1100)

    let _ = CircuitBreaker.canExecute(cb) // Trigger HalfOpen
    CircuitBreaker.recordFailure(cb) // 1st failure

    // Should still be HalfOpen
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(HalfOpen)

    // Trigger another probe
    let _ = CircuitBreaker.canExecute(cb)
    CircuitBreaker.recordFailure(cb) // 2nd failure

    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(Open)
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(false)

    let _ = Vitest.Vi.useRealTimers()
  })

  test("HalfOpen tolerates one failure and remains HalfOpen", t => {
    let _ = Vitest.Vi.useFakeTimers()
    let cb = CircuitBreaker.make(
      ~config=cfg(~failureThreshold=1, ~successThreshold=2, ~timeout=1000),
    )
    CircuitBreaker.recordFailure(cb)
    let _ = Vitest.Vi.advanceTimersByTime(1100)

    let _ = CircuitBreaker.canExecute(cb) // Trigger HalfOpen, sets probing=true

    // First failure
    CircuitBreaker.recordFailure(cb)

    // Should still be HalfOpen (not Open yet)
    t->expect(CircuitBreaker.getState(cb))->Expect.toBe(HalfOpen)

    // Next execution should be allowed (since we are back to probing=false in HalfOpen)
    t->expect(CircuitBreaker.canExecute(cb))->Expect.toBe(true)

    let _ = Vitest.Vi.useRealTimers()
  })
})
