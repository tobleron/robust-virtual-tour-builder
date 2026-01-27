/* tests/unit/LoggerTypes_v.test.res */
open Vitest

describe("LoggerTypes", () => {
  test("levelPriority returns correct integer values", t => {
    t->expect(LoggerTypes.levelPriority(Trace))->Expect.toBe(0)
    t->expect(LoggerTypes.levelPriority(Debug))->Expect.toBe(1)
    t->expect(LoggerTypes.levelPriority(Info))->Expect.toBe(2)
    t->expect(LoggerTypes.levelPriority(Perf))->Expect.toBe(2)
    t->expect(LoggerTypes.levelPriority(Warn))->Expect.toBe(3)
    t->expect(LoggerTypes.levelPriority(LoggerTypes.Error))->Expect.toBe(4)
  })

  test("levelToTelemetryPriority maps correctly", t => {
    t
    ->expect(LoggerTypes.levelToTelemetryPriority(LoggerTypes.Error))
    ->Expect.toEqual(LoggerTypes.Critical)
    t->expect(LoggerTypes.levelToTelemetryPriority(Warn))->Expect.toEqual(LoggerTypes.High)
    t->expect(LoggerTypes.levelToTelemetryPriority(Info))->Expect.toEqual(LoggerTypes.Medium)
    t->expect(LoggerTypes.levelToTelemetryPriority(Perf))->Expect.toEqual(LoggerTypes.Medium)
    t->expect(LoggerTypes.levelToTelemetryPriority(Trace))->Expect.toEqual(LoggerTypes.Low)
    t->expect(LoggerTypes.levelToTelemetryPriority(Debug))->Expect.toEqual(LoggerTypes.Low)
  })

  test("levelToString returns correct strings", t => {
    t->expect(LoggerTypes.levelToString(Trace))->Expect.toBe("trace")
    t->expect(LoggerTypes.levelToString(Debug))->Expect.toBe("debug")
    t->expect(LoggerTypes.levelToString(Info))->Expect.toBe("info")
    t->expect(LoggerTypes.levelToString(Warn))->Expect.toBe("warn")
    t->expect(LoggerTypes.levelToString(LoggerTypes.Error))->Expect.toBe("error")
    t->expect(LoggerTypes.levelToString(Perf))->Expect.toBe("perf")
  })

  test("priorityToString returns correct strings", t => {
    t->expect(LoggerTypes.priorityToString(LoggerTypes.Critical))->Expect.toBe("critical")
    t->expect(LoggerTypes.priorityToString(LoggerTypes.High))->Expect.toBe("high")
    t->expect(LoggerTypes.priorityToString(LoggerTypes.Medium))->Expect.toBe("medium")
    t->expect(LoggerTypes.priorityToString(LoggerTypes.Low))->Expect.toBe("low")
  })

  test("stringToLevel parses strings correctly", t => {
    t->expect(LoggerTypes.stringToLevel("trace"))->Expect.toEqual(Trace)
    t->expect(LoggerTypes.stringToLevel("debug"))->Expect.toEqual(LoggerTypes.Debug)
    t->expect(LoggerTypes.stringToLevel("info"))->Expect.toEqual(LoggerTypes.Info)
    t->expect(LoggerTypes.stringToLevel("warn"))->Expect.toEqual(LoggerTypes.Warn)
    t->expect(LoggerTypes.stringToLevel("error"))->Expect.toEqual(LoggerTypes.Error)
    t->expect(LoggerTypes.stringToLevel("perf"))->Expect.toEqual(LoggerTypes.Perf)
    t->expect(LoggerTypes.stringToLevel("unknown"))->Expect.toEqual(LoggerTypes.Info)
  })

  test("getErrorMessage extracts message from JsError", t => {
    let msg = try {
      %raw(`(function() { throw new Error("Test error message") })()`)
    } catch {
    | e => LoggerTypes.getErrorMessage(e)
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
    | e => LoggerTypes.getErrorDetails(e)
    }
    t->expect(msg)->Expect.toBe("Test error")
    t->expect(stack)->Expect.toBe("Test stack")
  })
})
