/* tests/unit/Resizer_v.test.res */
open Vitest
open Resizer

describe("Resizer", () => {
  describe("getMemoryUsage", () => {
    test(
      "returns usage when performance.memory is available",
      t => {
        let _ = %raw(`
        globalThis.performance.memory = {
          usedJSHeapSize: 100 * 1024 * 1024,
          totalJSHeapSize: 200 * 1024 * 1024,
          jsHeapSizeLimit: 500 * 1024 * 1024
        }
      `)

        let usage = getMemoryUsage()
        t->expect(usage["used"])->Expect.toBe("100MB")
        t->expect(usage["total"])->Expect.toBe("200MB")
        t->expect(usage["limit"])->Expect.toBe("500MB")
      },
    )

    test(
      "returns N/A when performance.memory is missing",
      t => {
        let _ = %raw(`delete globalThis.performance.memory`)

        let usage = getMemoryUsage()
        t->expect(usage["used"])->Expect.toBe("N/A")
      },
    )
  })

  describe("checkBackendHealth", () => {
    beforeEach(
      () => {
        let _ = %raw(`globalThis.fetch = vi.fn()`)
      },
    )

    testAsync(
      "returns true when backend is healthy",
      async t => {
        let _ = %raw(`
        globalThis.fetch.mockResolvedValue({
          ok: true,
          status: 200,
          statusText: "OK"
        })
      `)

        let healthy = await checkBackendHealth()
        t->expect(healthy)->Expect.toBe(true)
      },
    )

    testAsync(
      "returns false when backend returns error",
      async t => {
        let _ = %raw(`
        globalThis.fetch.mockResolvedValue({
          ok: false,
          status: 500,
          statusText: "Error"
        })
      `)

        let healthy = await checkBackendHealth()
        t->expect(healthy)->Expect.toBe(false)
      },
    )

    testAsync(
      "returns false on network error",
      async t => {
        let _ = %raw(`
        globalThis.fetch.mockRejectedValue(new Error("Network Error"))
      `)

        let healthy = await checkBackendHealth()
        t->expect(healthy)->Expect.toBe(false)
      },
    )
  })
})
