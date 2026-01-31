// @efficiency: infra-adapter
/* tests/unit/Logger_v.test.res */
open Vitest
open Logger

// Mock global fetch
%%raw(`
  globalThis.mockFetch = vi.fn(() => Promise.resolve({
    ok: true,
    json: () => Promise.resolve({})
  }));
  globalThis.fetch = globalThis.mockFetch;
`)

// Mock RequestQueue to execute immediately
%%raw(`
  vi.mock('../../src/utils/RequestQueue.res', () => ({
    schedule: vi.fn(fn => fn())
  }))
`)

describe("Logger", () => {
  beforeEach(() => {
    ignore(%raw(`Logger.telemetryQueue.length = 0`))
    ignore(%raw(`Logger.isFlushing.contents = false`))
    ignore(%raw(`globalThis.mockFetch.mockClear()`))
    setBypassTestEnvCheck(true)
  })

  testAsync("sendTelemetry batches Medium priority logs", async t => {
    let entry: Logger.logEntry = {
      timestampMs: 123.0,
      timestamp: "2024-01-01",
      module_: "Test",
      level: "info",
      message: "Test message",
      data: None,
      priority: "medium",
      requestId: None,
    }

    await sendTelemetry(entry)

    let queueLen = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLen)->Expect.toBe(1)
    t->expect(%raw(`globalThis.mockFetch.mock.calls.length`))->Expect.toBe(0)
  })

  testAsync("sendTelemetry sends High/Critical priority logs immediately", async t => {
    let entry: Logger.logEntry = {
      timestampMs: 123.0,
      timestamp: "2024-01-01",
      module_: "Test",
      level: "error",
      message: "Critical error",
      data: None,
      priority: "critical",
      requestId: None,
    }

    await sendTelemetry(entry)

    let queueLen = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLen)->Expect.toBe(0)
    t->expect(%raw(`globalThis.mockFetch.mock.calls.length`))->Expect.toBe(1)
    t
    ->expect(%raw(`globalThis.mockFetch.mock.calls[0][0]`))
    ->Expect.toContain("/api/telemetry/error")
  })

  testAsync("flushTelemetry sends batch and clears queue", async t => {
    let entry: Logger.logEntry = {
      timestampMs: 123.0,
      timestamp: "2024-01-01",
      module_: "Test",
      level: "info",
      message: "Batch item",
      data: None,
      priority: "medium",
      requestId: None,
    }

    // Add items to queue
    ignore(%raw(`(e) => Logger.telemetryQueue.push(e, e)`)(entry))

    await flushTelemetry()

    t->expect(%raw(`globalThis.mockFetch.mock.calls.length`))->Expect.toBe(1)
    t->expect(%raw(`Logger.telemetryQueue.length`))->Expect.toBe(0)

    let body = %raw(`JSON.parse(globalThis.mockFetch.mock.calls[0][1].body)`)
    t->expect(Array.length(body["entries"]))->Expect.toBe(2)
  })

  testAsync("sendTelemetry triggers flush when batch size reached", async t => {
    let entry: Logger.logEntry = {
      timestampMs: 123.0,
      timestamp: "2024-01-01",
      module_: "Test",
      level: "info",
      message: "Filler",
      data: None,
      priority: "medium",
      requestId: None,
    }

    let batchSize = Constants.Telemetry.batchSize

    // Send batchSize - 1 items
    for _ in 1 to batchSize - 1 {
      await sendTelemetry(entry)
    }

    t->expect(%raw(`Logger.telemetryQueue.length`))->Expect.toBe(batchSize - 1)
    t->expect(%raw(`globalThis.mockFetch.mock.calls.length`))->Expect.toBe(0)

    // Send the last one to trigger flush
    await sendTelemetry(entry)

    t->expect(%raw(`globalThis.mockFetch.mock.calls.length`))->Expect.toBe(1)
    t->expect(%raw(`Logger.telemetryQueue.length`))->Expect.toBe(0)
  })
})
