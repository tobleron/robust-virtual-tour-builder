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
    Logger.setBypassTestEnvCheck(true)
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

  test("perf maps duration to level correctly", t => {
    // 1. Slow (> 500ms) -> Warn
    clearLoggerState()
    Logger.perf(~module_="Test", ~message="Slow op", ~durationMs=600.0, ())
    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["level"])->Expect.toBe("warn")

    // 2. Medium (> 100ms) -> Info
    Logger.perf(~module_="Test", ~message="Med op", ~durationMs=200.0, ())
    let lastEntry2 = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry2["level"])->Expect.toBe("info")

    // 3. Fast -> Debug
    Logger.perf(~module_="Test", ~message="Fast op", ~durationMs=50.0, ())
    let lastEntry3 = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry3["level"])->Expect.toBe("debug")
  })

  test("timed measures duration and returns result", t => {
    let result = Logger.timed(
      ~module_="Test",
      ~operation="SyncOp",
      () => {
        42
      },
    )
    t->expect(result.result)->Expect.toBe(42)
    t->expect(result.durationMs >= 0.0)->Expect.toBe(true)
  })

  testAsync("timedAsync measures duration and returns result", async t => {
    let result = await Logger.timedAsync(
      ~module_="Test",
      ~operation="AsyncOp",
      async () => {
        43
      },
    )
    t->expect(result.result)->Expect.toBe(43)
    t->expect(result.durationMs >= 0.0)->Expect.toBe(true)
  })

  test("attempt catches errors and logs them", t => {
    let result = Logger.attempt(
      ~module_="Test",
      ~operation="FailOp",
      () => {
        %raw(`(function(){ throw new Error("Boom") })()`)
      },
    )
    t->expect(result)->Expect.toEqual(Error("Boom"))

    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["level"])->Expect.toBe("error")
    t->expect(lastEntry["message"])->Expect.toBe("FailOp_FAILED")
  })
})
