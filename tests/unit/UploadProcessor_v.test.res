/* tests/unit/UploadProcessor_v.test.res */
open Vitest
open ReBindings
open Types

describe("UploadProcessor", () => {
  // Global mock for fetch
  beforeEach(() => {
    let _ = %raw(`
      globalThis.fetch = (url) => {
        if (url.includes('/health')) {
          return Promise.resolve({ 
            ok: true, 
            status: 200, 
            statusText: 'OK',
            text: () => Promise.resolve('Tour Builder Backend is running!') 
          });
        }
        return Promise.resolve({ ok: true, json: () => Promise.resolve({}) });
      }
    `)
    GlobalStateBridge.setState(State.initialState)
  })

  let mockFile = (name): File.t => {
    Obj.magic({
      "name": name,
      "size": 1024.0,
      "type": "image/jpeg",
    })
  }

  testAsync("processUploads: should handle empty file array", async t => {
    let result = await UploadProcessor.processUploads([], None)

    let report: uploadReport = result.report
    t->expect(Array.length(report.success))->Expect.toBe(0)
    t->expect(Array.length(report.skipped))->Expect.toBe(0)
  })

  testAsync("processUploads: should handle backend offline", async t => {
    // Mock fetch to fail for health check
    let _ = %raw(`
      globalThis.fetch = (url) => {
        if (url.includes('/health')) {
          return Promise.resolve({ ok: false, status: 500, statusText: 'Internal Server Error' });
        }
        return Promise.resolve({ ok: true });
      }
    `)

    let f1 = mockFile("test.jpg")
    let result = await UploadProcessor.processUploads([f1], None)

    let report: uploadReport = result.report
    t->expect(Array.length(report.success))->Expect.toBe(0)
  })

  testAsync("processUploads: should report progress during phases", async t => {
    let progressLog = []
    let cb = (pct, msg, isProc, phase) => {
      let _ = Array.push(progressLog, (pct, msg, isProc, phase))
    }

    let f1 = mockFile("test.jpg")
    // This will likely complete or fail based on other logic,
    // but the first progress call is synchronous or very early.
    let _ = await UploadProcessor.processUploads([f1], Some(cb))

    t->expect(Array.length(progressLog) > 0)->Expect.toBe(true)
    let (firstPct, _, _, firstPhase) = Belt.Array.getExn(progressLog, 0)
    t->expect(firstPct)->Expect.toBe(0.0)
    t->expect(firstPhase)->Expect.toBe("Health Check")
  })
})
