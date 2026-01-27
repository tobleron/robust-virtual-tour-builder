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

  describe("getChecksum", () => {
    testAsync(
      "generates checksum using crypto.subtle",
      async t => {
        // Mock crypto using Object.defineProperty because it's read-only in some environments
        let _ = %raw(`
        Object.defineProperty(globalThis, 'crypto', {
          value: {
            subtle: {
              digest: async (algo, data) => {
                return new Uint8Array(32).fill(0xAA).buffer
              }
            }
          },
          configurable: true,
          writable: true
        })
      `)

        let mockFile: ReBindings.File.t = %raw(`{
        size: 1000,
        arrayBuffer: async () => new ArrayBuffer(1000),
        slice: (s, e) => ({ arrayBuffer: async () => new ArrayBuffer(e - s) })
      }`)

        let checksum = await getChecksum(mockFile)
        // 32 bytes of 0xAA -> "aaaaaaaa..."
        // Result format: hash + "_" + size
        t->expect(String.startsWith(checksum, "aa"))->Expect.toBe(true)
        t->expect(String.endsWith(checksum, "_1000"))->Expect.toBe(true)
      },
    )

    testAsync(
      "generates checksum for large files (sampled)",
      async t => {
        // Reuse mock from previous test or ensure it persists/re-applied.
        // Since we didn't clear it, it should be there.
        // But safer to apply again if tests are isolated?
        // Vitest tests run in same context usually unless configured otherwise.

        let _ = %raw(`
        Object.defineProperty(globalThis, 'crypto', {
          value: {
            subtle: {
              digest: async (algo, data) => {
                return new Uint8Array(32).fill(0xAA).buffer
              }
            }
          },
          configurable: true,
          writable: true
        })
      `)

        let mockFile: ReBindings.File.t = %raw(`{
        size: 20 * 1024 * 1024,
        arrayBuffer: async () => new ArrayBuffer(1000),
        slice: (s, e) => ({ arrayBuffer: async () => new ArrayBuffer(e - s) })
      }`)

        let checksum = await getChecksum(mockFile)
        t->expect(String.startsWith(checksum, "aa"))->Expect.toBe(true)
        t->expect(String.endsWith(checksum, "_20971520"))->Expect.toBe(true)
      },
    )
  })
})
