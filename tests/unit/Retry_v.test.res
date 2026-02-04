// @efficiency: infra-adapter
/* tests/unit/Retry_v.test.res */
open Vitest
open Retry

describe("Retry", () => {
  testAsync("execute returns success immediately if fn succeeds", async t => {
    let controller = ReBindings.AbortController.newAbortController()
    let signal = ReBindings.AbortController.signal(controller)

    let result = await execute(
      ~fn=async (~signal as _) => Ok("success"),
      ~signal,
      ~config=defaultConfig,
    )

    switch result {
    | Success(val, attempt) => {
        t->expect(val)->Expect.toBe("success")
        t->expect(attempt)->Expect.toBe(1)
      }
    | Exhausted(_) => t->expect(true)->Expect.toBe(false)
    }
  })

  testAsync("execute retries on failure and eventually succeeds", async t => {
    let controller = ReBindings.AbortController.newAbortController()
    let signal = ReBindings.AbortController.signal(controller)
    let count = ref(0)

    let fn = async (~signal as _) => {
      count := count.contents + 1
      if count.contents < 3 {
        Error("NetworkError")
      } else {
        Ok("success")
      }
    }

    // config: 3 retries, small delay for test speed
    let config = {
      ...defaultConfig,
      maxRetries: 3,
      initialDelayMs: 1, // very fast
      jitter: false,
    }

    let result = await execute(~fn, ~signal, ~config)

    switch result {
    | Success(val, attempt) => {
        t->expect(val)->Expect.toBe("success")
        t->expect(attempt)->Expect.toBe(3) // 1st fail, 2nd fail, 3rd success
      }
    | Exhausted(e) => t->expect(e)->Expect.toBe("Should not happen")
    }
  })

  testAsync("execute exhausted after maxRetries", async t => {
    let controller = ReBindings.AbortController.newAbortController()
    let signal = ReBindings.AbortController.signal(controller)
    let count = ref(0)

    let fn = async (~signal as _) => {
      count := count.contents + 1
      Error("NetworkError")
    }

    let config = {
      ...defaultConfig,
      maxRetries: 2,
      initialDelayMs: 1,
      jitter: false,
    }

    let result = await execute(~fn, ~signal, ~config)

    switch result {
    | Success(_) => t->expect(true)->Expect.toBe(false)
    | Exhausted(e) => {
        t->expect(e)->Expect.toBe("NetworkError")
        // 1 initial + 2 retries = 3 attempts
        t->expect(count.contents)->Expect.toBe(3)
      }
    }
  })

  testAsync("shouldRetry respects boolean return", async t => {
    let controller = ReBindings.AbortController.newAbortController()
    let signal = ReBindings.AbortController.signal(controller)

    let fn = async (~signal as _) => Error("404 Not Found")

    // Default shouldRetry returns false for 404
    let result = await execute(~fn, ~signal, ~config=defaultConfig)

    switch result {
    | Success(_) => t->expect(true)->Expect.toBe(false)
    | Exhausted(e) => t->expect(e)->Expect.toBe("404 Not Found")
    }
  })

  testAsync("aborted signal stops retrying", async t => {
    let controller = ReBindings.AbortController.newAbortController()
    let signal = ReBindings.AbortController.signal(controller)

    let fn = async (~signal as _) => {
      // Abort after first call
      ReBindings.AbortController.abort(controller)
      Error("NetworkError")
    }

    let config = {
      ...defaultConfig,
      maxRetries: 5,
      initialDelayMs: 10,
      jitter: false,
    }

    let result = await execute(~fn, ~signal, ~config)

    switch result {
    | Success(_) => t->expect(true)->Expect.toBe(false)
    | Exhausted(e) =>
      // Depending on race condition of check vs signal update
      // The check 'aborted(signal)' is at start of loop.
      // Loop 1 starts. aborted=false. fn returns Error.
      // Fn aborted controller.
      // Loop calls itself recursively (loop 2).
      // Loop 2 checks aborted(signal). True.
      // Returns Exhausted("Aborted").
      t->expect(e)->Expect.toBe("Aborted")
    }
  })
})
