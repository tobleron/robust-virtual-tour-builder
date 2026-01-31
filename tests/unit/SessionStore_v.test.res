// @efficiency: infra-adapter
/* tests/unit/SessionStore_v.test.res */
open Vitest

/* Mock Logger to capture errors */
module LoggerMock = {
  let lastError = ref("")
  let error = (~module_ as _, ~message, ~data as _=?, ()) => {
    lastError := message
  }
}

/* We need to mock Logger module before it's used.
   But since we are running in Vitest, we can use global mocks or module mocks.
   The simplest way to see what's wrong is to look at the implementation of SessionStore.res
   It calls Logger.error.
   Let's use %raw to mock Logger.
*/
let _ = %raw(`
  globalThis.vi.mock('../../src/utils/Logger.bs.js', () => {
    return {
      error: (args) => {
        console.error("MOCKED LOGGER ERROR:", args.message);
      },
      castToJson: (v) => v
    }
  })
`)


describe("SessionStore", () => {
  test("Module exists and exports functions", t => {
    let _ = SessionStore.saveState
    let _ = SessionStore.loadState
    t->expect(true)->Expect.toBe(true)
  })

  test("saveState and loadState roundtrip", t => {
    // Mock localStorage
    let _ = %raw(`
      (() => {
        const store = {};
        globalThis.localStorage = {
          setItem: (key, val) => { store[key] = val },
          getItem: (key) => store[key] || null,
          removeItem: (key) => { delete store[key] }
        }
      })()
    `)

    let initialState = State.initialState
    let testState = {
      ...initialState,
      tourName: "Session Test",
      activeIndex: 3,
      isLinking: true,
    }

    SessionStore.saveState(testState)

    let loaded = SessionStore.loadState()
    switch loaded {
    | Some(ls) => {
        t->expect(ls.tourName)->Expect.toBe("Session Test")
        t->expect(ls.activeIndex)->Expect.toBe(3)
        t->expect(ls.isLinking)->Expect.toBe(true)
      }
    | None => t->expect(false)->Expect.toBe(true)
    }

    SessionStore.clearState()
    t->expect(SessionStore.loadState())->Expect.toBe(None)
  })
})
