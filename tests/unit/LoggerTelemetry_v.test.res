/* tests/unit/LoggerTelemetry_v.test.res */
open Vitest

// Mock Fetch global
%%raw(`
  globalThis.fetch = vi.fn(() => Promise.resolve({
    ok: true,
    json: () => Promise.resolve({})
  }));
`)

let setOnline: bool => unit = %raw(`function(online) {
  Object.defineProperty(navigator, 'onLine', {
    value: online,
    configurable: true
  });
  window.dispatchEvent(new Event(online ? 'online' : 'offline'));
}`)

describe("LoggerTelemetry Offline Awareness", () => {
  beforeAll(() => {
    NetworkStatus.initialize()
  })

  beforeEach(() => {
    ignore(%raw(`LoggerTelemetry.telemetryQueue.length = 0`))
    ignore(%raw(`globalThis.fetch.mockClear()`))
    setOnline(true)
    LoggerTelemetry.telemetrySuspendedUntil := 0.0
    LoggerTelemetry.isFlushing := false
  })

  testAsync("flushTelemetry skips when offline", async t => {
    setOnline(false)

    let entry: LoggerCommon.logEntry = {
      timestampMs: 0.0,
      timestamp: "",
      module_: "Test",
      level: "info",
      message: "Test Message",
      data: None,
      priority: "medium",
      requestId: None,
      operationId: None,
      sessionId: None,
    }
    Array.push(LoggerTelemetry.telemetryQueue, entry)

    await LoggerTelemetry.flushTelemetry()

    let calls = %raw(`globalThis.fetch.mock.calls.length`)
    t->expect(calls)->Expect.toBe(0)
  })

  testAsync("flushTelemetry proceeds when online", async t => {
    setOnline(true)

    let entry: LoggerCommon.logEntry = {
      timestampMs: 0.0,
      timestamp: "",
      module_: "Test",
      level: "info",
      message: "Test Message",
      data: None,
      priority: "medium",
      requestId: None,
      operationId: None,
      sessionId: None,
    }
    Array.push(LoggerTelemetry.telemetryQueue, entry)

    await LoggerTelemetry.flushTelemetry()

    let calls = %raw(`globalThis.fetch.mock.calls.length`)
    t->expect(calls)->Expect.toBe(1)
  })

  testAsync("Reconnection triggers flush", async t => {
    setOnline(false)

    let entry: LoggerCommon.logEntry = {
      timestampMs: 0.0,
      timestamp: "",
      module_: "Test",
      level: "info",
      message: "Reconnect Test",
      data: None,
      priority: "medium",
      requestId: None,
      operationId: None,
      sessionId: None,
    }
    Array.push(LoggerTelemetry.telemetryQueue, entry)

    setOnline(true)

    await Promise.make((resolve, _) => {
      let _ = setTimeout(() => resolve(ignore()), 50)
    })

    let calls = %raw(`globalThis.fetch.mock.calls.length`)
    t->expect(calls)->Expect.toBe(1)
  })
})
