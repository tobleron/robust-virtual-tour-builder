// @efficiency: infra-adapter
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
    AppStateBridge.updateState(State.initialState)
    // Ensure network status is initialized and online by default
    let _ = %raw(`
      Object.defineProperty(navigator, 'onLine', {
        configurable: true,
        value: true
      })
    `)
    NetworkStatus.initialize()
  })

  afterEach(() => {
    // Restore online status and cleanup
    let _ = %raw(`
      Object.defineProperty(navigator, 'onLine', {
        configurable: true,
        value: true
      })
    `)
    NetworkStatus.cleanup()
  })

  let mockFile = (name): File.t => {
    Obj.magic({
      "name": name,
      "size": 1024.0,
      "type": "image/jpeg",
    })
  }

  testAsync("processUploads: should handle empty file array", async t => {
    let result = await UploadProcessor.processUploads(
      [],
      None,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

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
    let result = await UploadProcessor.processUploads(
      [f1],
      None,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

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
    let _ = await UploadProcessor.processUploads(
      [f1],
      Some(cb),
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    t->expect(Array.length(progressLog) > 0)->Expect.toBe(true)
    let (firstPct, _, _, firstPhase) = Belt.Array.getExn(progressLog, 0)
    t->expect(firstPct)->Expect.toBe(0.0)
    t->expect(firstPhase)->Expect.toBe("Health Check")
  })

  testAsync(
    "processUploads: should handle browser offline differently from backend offline",
    async t => {
      // Mock navigator.onLine to be false
      let _ = %raw(`
      Object.defineProperty(navigator, 'onLine', {
        configurable: true,
        value: false
      })
    `)
      // Mock fetch to fail (simulating offline)
      let _ = %raw(`
      globalThis.fetch = (url) => Promise.reject(new Error("Network Error"))
    `)

      // Also need to re-initialize NetworkStatus because it might have cached the initial value
      NetworkStatus.initialize()

      let progressLog = []
      let cb = (pct, msg, isProc, phase) => {
        let _ = Array.push(progressLog, (pct, msg, isProc, phase))
      }

      let f1 = mockFile("test.jpg")
      let _ = await UploadProcessor.processUploads(
        [f1],
        Some(cb),
        ~getState=AppStateBridge.getState,
        ~dispatch=AppStateBridge.dispatch,
      )

      // Check if we get the "Error: No Internet Connection" message
      let foundOfflineError =
        progressLog->Belt.Array.some(((_, msg, _, _)) => msg == "Error: No Internet Connection")
      t->expect(foundOfflineError)->Expect.toBe(true)
    },
  )
})
