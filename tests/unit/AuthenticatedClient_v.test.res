open Vitest

describe("AuthenticatedClient", () => {
  beforeEach(() => {
    Dom.Storage2.localStorage->Dom.Storage2.clear
    let _ = %raw("global.fetch = vi.fn()")
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
})
