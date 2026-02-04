open Vitest

describe("RateLimiter", () => {
  test("should limit calls", t => {
    let limiter = RateLimiter.make(~maxCalls=2, ~windowMs=1000)

    t->expect(RateLimiter.canCall(limiter))->Expect.toBe(true)
    RateLimiter.recordCall(limiter)

    t->expect(RateLimiter.canCall(limiter))->Expect.toBe(true)
    RateLimiter.recordCall(limiter)

    t->expect(RateLimiter.canCall(limiter))->Expect.toBe(false)
  })

  testAsync("should reset after window", async t => {
    let limiter = RateLimiter.make(~maxCalls=1, ~windowMs=50)

    RateLimiter.recordCall(limiter)
    t->expect(RateLimiter.canCall(limiter))->Expect.toBe(false)

    await Promise.make(
      (resolve, _) => {
        let _ = setTimeout(resolve, 100)
      },
    )

    t->expect(RateLimiter.canCall(limiter))->Expect.toBe(true)
  })
})
