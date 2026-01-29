/* tests/unit/Logger_v.test.res */
open Vitest

describe("Logger", () => {
  test("levelPriority returns correct integer values", t => {
    t->expect(Logger.levelPriority(Trace))->Expect.toBe(0)
    t->expect(Logger.levelPriority(Debug))->Expect.toBe(1)
    t->expect(Logger.levelPriority(Info))->Expect.toBe(2)
    t->expect(Logger.levelPriority(Perf))->Expect.toBe(2)
    t->expect(Logger.levelPriority(Warn))->Expect.toBe(3)
    t->expect(Logger.levelPriority(Logger.Error))->Expect.toBe(4)
  })

  test("levelToTelemetryPriority maps correctly", t => {
    t
    ->expect(Logger.levelToTelemetryPriority(Logger.Error))
    ->Expect.toEqual(Logger.Critical)
    t->expect(Logger.levelToTelemetryPriority(Warn))->Expect.toEqual(Logger.High)
    t->expect(Logger.levelToTelemetryPriority(Info))->Expect.toEqual(Logger.Medium)
    t->expect(Logger.levelToTelemetryPriority(Perf))->Expect.toEqual(Logger.Medium)
    t->expect(Logger.levelToTelemetryPriority(Trace))->Expect.toEqual(Logger.Low)
    t->expect(Logger.levelToTelemetryPriority(Debug))->Expect.toEqual(Logger.Low)
  })

  test("levelToString returns correct strings", t => {
    t->expect(Logger.levelToString(Trace))->Expect.toBe("trace")
    t->expect(Logger.levelToString(Debug))->Expect.toBe("debug")
    t->expect(Logger.levelToString(Info))->Expect.toBe("info")
    t->expect(Logger.levelToString(Warn))->Expect.toBe("warn")
    t->expect(Logger.levelToString(Logger.Error))->Expect.toBe("error")
    t->expect(Logger.levelToString(Perf))->Expect.toBe("perf")
  })

  test("priorityToString returns correct strings", t => {
    t->expect(Logger.priorityToString(Logger.Critical))->Expect.toBe("critical")
    t->expect(Logger.priorityToString(Logger.High))->Expect.toBe("high")
    t->expect(Logger.priorityToString(Logger.Medium))->Expect.toBe("medium")
    t->expect(Logger.priorityToString(Logger.Low))->Expect.toBe("low")
  })

  test("stringToLevel parses strings correctly", t => {
    t->expect(Logger.stringToLevel("trace"))->Expect.toEqual(Trace)
    t->expect(Logger.stringToLevel("debug"))->Expect.toEqual(Logger.Debug)
    t->expect(Logger.stringToLevel("info"))->Expect.toEqual(Logger.Info)
    t->expect(Logger.stringToLevel("warn"))->Expect.toEqual(Logger.Warn)
    t->expect(Logger.stringToLevel("error"))->Expect.toEqual(Logger.Error)
    t->expect(Logger.stringToLevel("perf"))->Expect.toEqual(Logger.Perf)
    t->expect(Logger.stringToLevel("unknown"))->Expect.toEqual(Logger.Info)
  })

  test("getErrorMessage extracts message from JsError", t => {
    let msg = try {
      %raw(`(function() { throw new Error("Test error message") })()`)
    } catch {
    | e => Logger.getErrorMessage(e)
    }
    t->expect(msg)->Expect.toBe("Test error message")
  })

  test("getErrorDetails extracts message and stack", t => {
    let (msg, stack) = try {
      %raw(`(function() {
        const e = new Error("Test error");
        e.stack = "Test stack";
        throw e;
      })()`)
    } catch {
    | e => Logger.getErrorDetails(e)
    }
    t->expect(msg)->Expect.toBe("Test error")
    t->expect(stack)->Expect.toBe("Test stack")
  })
})
