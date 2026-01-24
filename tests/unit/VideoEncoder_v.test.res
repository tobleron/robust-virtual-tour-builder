/* tests/unit/VideoEncoder_v.test.res */
open Vitest
open VideoEncoder
open ReBindings

// Global mocks
%%raw(`
  globalThis.fetch = vi.fn().mockResolvedValue({
    ok: true,
    blob: () => Promise.resolve({ size: 2048, type: 'video/mp4' }),
    json: () => Promise.resolve({ success: true }),
    status: 200
  });

  // Mock RequestQueue
  globalThis.RequestQueue = {
    schedule: (fn) => fn()
  };

  // Mock DownloadSystem
  globalThis.DownloadSystem = {
    saveBlob: vi.fn()
  };
`)

describe("VideoEncoder - Remote Transcoding Service", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
  })

  let makeBlob: (string, string) => Blob.t = %raw(`(data, t) => new Blob([data], { type: t })`)

  testAsync("transcodeWebMToMP4 rejects blobs smaller than 1024 bytes", async t => {
    let tinyBlob: Blob.t = makeBlob("test", "video/webm")
    let result = await transcodeWebMToMP4(tinyBlob, "test", None)

    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(false)
    | Error(msg) => t->expect(msg)->Expect.String.toContain("too small")
    }
  })

  testAsync("transcodeWebMToMP4 handles successful transcoding flow", async t => {
    // Need at least 1024 bytes to pass early check
    let largeContent = String.repeat("a", 2048)
    let webmBlob: Blob.t = makeBlob(largeContent, "video/webm")
    let callbackCount = ref(0)
    let progressCallback = (pct, msg) => {
      let _ = msg
      let _ = pct
      callbackCount := callbackCount.contents + 1
    }

    let result = await transcodeWebMToMP4(webmBlob, "my-tour", Some(progressCallback))

    t->expect(result)->Expect.toEqual(Ok())
    // 10.0 (start), 50.0 (processing), 100.0 (done)
    t->expect(callbackCount.contents)->Expect.Int.toBeGreaterThanOrEqual(3)

    let fetchCalls = %raw(`globalThis.fetch.mock.calls.length`)
    t->expect(fetchCalls)->Expect.toBe(1)
  })

  testAsync("transcodeWebMToMP4 handles network failure", async t => {
    let _ = %raw(`globalThis.fetch.mockRejectedValueOnce(new Error("Network Error"))`)

    let largeContent = String.repeat("a", 2048)
    let webmBlob: Blob.t = makeBlob(largeContent, "video/webm")
    let result = await transcodeWebMToMP4(webmBlob, "test", None)

    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(false)
    | Error(msg) => t->expect(msg)->Expect.String.toContain("Network Error")
    }
  })
})
