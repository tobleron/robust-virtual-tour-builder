open Vitest
open Api

describe("AuthenticatedClient", () => {
  beforeEach(() => {
    let _ = %raw(`(() => {
      if (typeof localStorage === 'undefined' || !localStorage.clear) {
        let store = {};
        global.localStorage = {
          getItem: (key) => store[key] || null,
          setItem: (key, value) => { store[key] = value.toString(); },
          removeItem: (key) => { delete store[key]; },
          clear: () => { Object.keys(store).forEach(k => delete store[k]); }
        };
      } else {
        localStorage.clear();
      }
    })()`)
    let _ = %raw("global.fetch = vi.fn()")
    // Reset NotificationManager
    NotificationManager.clear()
    ignore(Promise.resolve())
  })

  testAsync("adds Authorization header if token exists", async t => {
    Dom.Storage2.localStorage->Dom.Storage2.setItem("auth_token", "test-token")

    let fetchMock = %raw("global.fetch")
    let _ = %raw(`function(m){m.mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.resolve({}),
      text: () => Promise.resolve('')
    })}`)(fetchMock)

    let _ = await AuthenticatedClient.request("/test", ())

    let authHeader = %raw(
      "(function(m){ return m.mock.calls[0][1]['headers']['Authorization'] || (m.mock.calls[0][1]['headers'].get && m.mock.calls[0][1]['headers'].get('Authorization')) })(fetchMock)"
    )
    t->expect(authHeader)->Expect.toBe("Bearer test-token")
  })

  testAsync("dispatches logout event on 401", async t => {
    let dispatchMock = %raw("vi.spyOn(window, 'dispatchEvent')")
    let _ = dispatchMock

    let fetchMock = %raw("global.fetch")
    let _ = %raw(`function(m){m.mockResolvedValue({
      ok: false,
      status: 401,
      statusText: 'Unauthorized',
      json: () => Promise.resolve({}),
      text: () => Promise.resolve('')
    })}`)(fetchMock)

    try {
      let _ = await AuthenticatedClient.request("/test", ())
    } catch {
    | AuthenticatedClient.HttpError(401, _) =>
      let calls = %raw(`function(m){return m.mock.calls}`)(dispatchMock)
      t->expect(Array.length(calls) > 0)->Expect.toBe(true)
      let eventType = %raw("(function(c){ return c[0][0].type })(calls)")
      t->expect(eventType)->Expect.toBe("auth:logout")
    | _ => t->expect(false)->Expect.toBe(true)
    }

    let _ = %raw("(function(m){ m.mockRestore() })(dispatchMock)")
    let _ = fetchMock // use fetchMock to avoid unused warning
  })

  testAsync("dispatches notification on first retry", async t => {
    // 1. Subscribe to notifications
    let notificationReceived = ref(false)
    let unsubscribe = NotificationManager.subscribe(state => {
      let messages = Belt.Array.concat(state.active, state.pending)
      let hasRetryMessage = Belt.Array.some(messages, n =>
        String.includes(n.message, "Retrying request...") &&
        String.includes(n.message, "(attempt 1)")
      )
      if hasRetryMessage {
        notificationReceived := true
      }
    })

    // 2. Mock fetch to fail once then succeed
    let fetchMock = %raw("global.fetch")
    let _ = %raw(`function(m){
      m.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error'
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({}),
        text: () => Promise.resolve('')
      })
    }`)(fetchMock)

    // 3. Call requestWithRetry
    let retryConfig: Retry.config = {
      maxRetries: 3,
      initialDelayMs: 10,
      maxDelayMs: 100,
      backoffMultiplier: 1.0,
      jitter: false,
    }

    // Must simulate local environment for dev-token bypass if no token set
    // Or just set a token
    Dom.Storage2.localStorage->Dom.Storage2.setItem("auth_token", "test-token")

    let _ = await AuthenticatedClient.requestWithRetry(
      "/test-retry",
      ~retryConfig,
      ()
    )

    // 4. Assert
    t->expect(notificationReceived.contents)->Expect.toBe(true)

    unsubscribe()
  })
})
