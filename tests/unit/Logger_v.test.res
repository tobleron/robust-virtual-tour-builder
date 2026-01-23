/* tests/unit/Logger_v.test.res */
open Vitest

// Global mock for fetch
let _ = %raw(`globalThis.fetch = () => Promise.resolve({ ok: true, json: () => Promise.resolve({}) })`)

// Helper to clear Logger internal state between tests
let clearLoggerState = () => {
  let _ = %raw(`Logger.entries.length = 0`)
  let _ = %raw(`Logger.appLog.length = 0`)
  let _ = %raw(`Logger.telemetryQueue.length = 0`)
}

describe("Logger Priority & Telemetry Logic", () => {
  beforeEach(() => {
    clearLoggerState()
  })

  test("levelToTelemetryPriority maps correctly", t => {
    t->expect(Logger.levelToTelemetryPriority(Error))->Expect.toEqual(Logger.Critical)
    t->expect(Logger.levelToTelemetryPriority(Warn))->Expect.toEqual(Logger.High)
    t->expect(Logger.levelToTelemetryPriority(Info))->Expect.toEqual(Logger.Medium)
    t->expect(Logger.levelToTelemetryPriority(Perf))->Expect.toEqual(Logger.Medium)
    t->expect(Logger.levelToTelemetryPriority(Trace))->Expect.toEqual(Logger.Low)
    t->expect(Logger.levelToTelemetryPriority(Debug))->Expect.toEqual(Logger.Low)
  })

  test("Medium priority logs are added to telemetryQueue", t => {
    // Info level maps to Medium priority
    Logger.log(~module_="Test", ~level=Logger.Info, ~message="Test message", ())

    let queueLen = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLen)->Expect.toBe(1)

    let firstEntry = %raw(`Logger.telemetryQueue[0]`)
    t->expect(firstEntry["priority"])->Expect.toBe("medium")
  })

  test("Low priority logs are NOT added to telemetryQueue", t => {
    // Debug level maps to Low priority
    Logger.log(~module_="Test", ~level=Logger.Debug, ~message="Low priority test", ())

    let queueLen = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLen)->Expect.toBe(0)
  })

  test("Critical/High priority logs are NOT added to telemetryQueue (sent immediately)", t => {
    // Error level maps to Critical priority
    Logger.log(~module_="Test", ~level=Logger.Error, ~message="Critical error", ())

    let queueLen = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLen)->Expect.toBe(0)
  })

  test("Queue flushes when reaching batchSize", t => {
    let batchSize = Constants.Telemetry.batchSize

    // Fill queue up to batchSize - 1
    for _ in 1 to batchSize - 1 {
      Logger.log(~module_="Test", ~level=Logger.Info, ~message="Filling...", ())
    }

    let queueLenBefore = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLenBefore)->Expect.toBe(batchSize - 1)

    // Add one more to trigger flush
    Logger.log(~module_="Test", ~level=Logger.Info, ~message="Trigger flush", ())

    // Since flushTelemetry is async and not awaited in log(),
    // and it immediately clears the queue via splice, the queue should be 0.
    let queueLenAfter = %raw(`Logger.telemetryQueue.length`)
    t->expect(queueLenAfter)->Expect.toBe(0)
  })
})
