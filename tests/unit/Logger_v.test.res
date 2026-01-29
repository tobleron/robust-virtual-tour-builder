// @efficiency: infra-adapter
/* tests/unit/Logger_v.test.res */
open Vitest

// Global mocks - Top level setup
%%raw(`
  globalThis.mockWindow = {
    addEventListener: vi.fn(),
    setInterval: vi.fn(),
    setTimeout: vi.fn(),
    location: { hostname: 'localhost' }
  };
  globalThis.window = globalThis.mockWindow;
  globalThis.setInterval = globalThis.mockWindow.setInterval;
  globalThis.setTimeout = globalThis.mockWindow.setTimeout;
`)

describe("Logger Facade Integration", () => {
  beforeEach(() => {
    Logger.enable()
  })

  test("enable/disable updates state", t => {
    Logger.disable()
    t->expect(Logger.enabled.contents)->Expect.toBe(false)
    Logger.enable()
    t->expect(Logger.enabled.contents)->Expect.toBe(true)
  })

  test("toggle flips state", t => {
    Logger.disable()
    let res = Logger.toggle()
    t->expect(res)->Expect.toBe(true)
    t->expect(Logger.enabled.contents)->Expect.toBe(true)

    let res2 = Logger.toggle()
    t->expect(res2)->Expect.toBe(false)
    t->expect(Logger.enabled.contents)->Expect.toBe(false)
  })

  test("setLevel updates minLevel", t => {
    Logger.setLevel(Error)
    t->expect(Logger.minLevel.contents)->Expect.toEqual(Logger.Error)
  })

  test("init sets up window objects", t => {
    Logger.init()

    let debugObj = %raw(`globalThis.window.DEBUG`)
    t->expect(debugObj)->Expect.toBeDefined
    t->expect(debugObj["enable"])->Expect.toBeDefined

    let appLog = %raw(`globalThis.window.appLog`)
    t->expect(appLog)->Expect.toBeDefined

    // Check if setInterval was called for telemetry
    t
    ->expect(%raw(`globalThis.mockWindow.setInterval.mock.calls.length`))
    ->Expect.Int.toBeGreaterThan(0)
  })

  test("Integration: log call routes correctly to Logger", t => {
    ignore(%raw(`Logger.entries.length = 0`))
    Logger.info(~module_="FacadeTest", ~message="Hello Integration", ())

    let lastEntry = %raw(`Logger.entries[Logger.entries.length - 1]`)
    t->expect(lastEntry["module"])->Expect.toBe("FacadeTest")
    t->expect(lastEntry["message"])->Expect.toBe("Hello Integration")
  })
})
