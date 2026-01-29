/* tests/unit/Logger_v.test.res */
open Vitest
open Logger

// Global mock for telemetry to avoid network calls
%%raw(`
  vi.mock('../../src/utils/Logger.res', () => ({
    sendTelemetry: vi.fn(() => Promise.resolve()),
    flushTelemetry: vi.fn(() => Promise.resolve()),
    setBypassTestEnvCheck: vi.fn()
  }))
`)

// Capture console calls - Top level setup
%%raw(`
  globalThis.mockConsole = {
    log: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn()
  };
  globalThis.console["log"] = globalThis.mockConsole.log;
  globalThis.console["info"] = globalThis.mockConsole.info;
  globalThis.console["warn"] = globalThis.mockConsole.warn;
  globalThis.console["error"] = globalThis.mockConsole.error;
`)

describe("Logger", () => {
  beforeEach(() => {
    ignore(%raw(`Logger.entries.length = 0`))
    ignore(%raw(`Logger.appLog.length = 0`))
    ignore(%raw(`globalThis.mockConsole.log.mockClear()`))
    ignore(%raw(`globalThis.mockConsole.info.mockClear()`))
    ignore(%raw(`globalThis.mockConsole.warn.mockClear()`))
    ignore(%raw(`globalThis.mockConsole.error.mockClear()`))
    Logger.enabled := true
    Logger.minLevel := Info
  })

  test("log adds entry to entries and appLog", t => {
    Logger.log(~module_="Test", ~level=Info, ~message="Test message", ())

    let entriesLen = %raw(`Logger.entries.length`)
    t->expect(entriesLen)->Expect.toBe(1)

    let appLogLen = %raw(`Logger.appLog.length`)
    t->expect(appLogLen)->Expect.toBe(1)

    let firstEntry = %raw(`Logger.entries[0]`)
    t->expect(firstEntry["message"])->Expect.toBe("Test message")
    t->expect(firstEntry["level"])->Expect.toBe("info")
  })

  test("log level filtering works", t => {
    Logger.minLevel := Warn
    Logger.log(~module_="Test", ~level=Info, ~message="Should not show", ())
    t->expect(%raw(`globalThis.mockConsole.info.mock.calls.length`))->Expect.toBe(0)

    Logger.log(~module_="Test", ~level=Warn, ~message="Should show", ())
    t->expect(%raw(`globalThis.mockConsole.warn.mock.calls.length`))->Expect.toBe(1)
  })

  test("perf logs with correct thresholds", t => {
    // Fast
    Logger.perf(~module_="Test", ~message="Fast", ~durationMs=50.0, ())
    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["level"])->Expect.toBe("debug")
    t->expect(lastEntry["data"]["threshold"])->Expect.toBe("OK")

    // Slow
    Logger.perf(~module_="Test", ~message="Slow", ~durationMs=150.0, ())
    let lastEntry2 = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry2["level"])->Expect.toBe("info")
    t->expect(lastEntry2["data"]["threshold"])->Expect.toBe("SLOW")

    // Very Slow
    Logger.perf(~module_="Test", ~message="Very Slow", ~durationMs=600.0, ())
    let lastEntry3 = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry3["level"])->Expect.toBe("warn")
    t->expect(lastEntry3["data"]["threshold"])->Expect.toBe("VERY_SLOW")
  })

  test("timed measures and logs duration", t => {
    let result = Logger.timed(~module_="Test", ~operation="SyncOp", () => 42)
    t->expect(result.result)->Expect.toBe(42)
    t->expect(result.durationMs >= 0.0)->Expect.toBe(true)

    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["message"])->Expect.toContain("SyncOp")
  })

  testAsync("timedAsync measures and logs duration", async t => {
    let result = await Logger.timedAsync(~module_="Test", ~operation="AsyncOp", async () => 43)
    t->expect(result.result)->Expect.toBe(43)

    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["message"])->Expect.toContain("AsyncOp")
  })

  test("attempt catches errors and logs them", t => {
    let result = Logger.attempt(
      ~module_="Test",
      ~operation="FailOp",
      () => {
        %raw(`(function(){ throw new Error("Boom") })()`)
      },
    )
    t->expect(result)->Expect.toEqual(Belt.Result.Error("Boom"))

    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["level"])->Expect.toBe("error")
    t->expect(lastEntry["message"])->Expect.toBe("FailOp_FAILED")
    t->expect(lastEntry["data"]["error"])->Expect.toBe("Boom")
  })

  testAsync("attemptAsync catches errors and logs them", async t => {
    let result = await Logger.attemptAsync(
      ~module_="Test",
      ~operation="FailOpAsync",
      async () => {
        %raw(`(function(){ throw new Error("BoomAsync") })()`)
      },
    )
    t->expect(result)->Expect.toEqual(Belt.Result.Error("BoomAsync"))

    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["level"])->Expect.toBe("error")
    t->expect(lastEntry["data"]["error"])->Expect.toBe("BoomAsync")
  })

  test("enabledModules filtering works", t => {
    Logger.enabledModules := Belt.Set.String.fromArray(["Specific"])

    Logger.log(~module_="Other", ~level=Info, ~message="Skip", ())
    t->expect(%raw(`globalThis.mockConsole.info.mock.calls.length`))->Expect.toBe(0)

    Logger.log(~module_="Specific", ~level=Info, ~message="Keep", ())
    t->expect(%raw(`globalThis.mockConsole.info.mock.calls.length`))->Expect.toBe(1)
  })
})
