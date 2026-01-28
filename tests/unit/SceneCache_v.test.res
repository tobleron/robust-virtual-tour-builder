// @efficiency: infra-adapter
open Vitest
open SceneCache

type mock
@val external expectJs: 'a => 'b = "expect"
@send external toHaveBeenCalledWith: ('a, 'b) => unit = "toHaveBeenCalledWith"
@get external not: 'a => 'a = "not"
@send external toHaveBeenCalled: ('a, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledTimes: ('a, int) => unit = "toHaveBeenCalledTimes"
@send external mockClear: mock => unit = "mockClear"

describe("SceneCache", () => {
  let revokeMock = ref(Nullable.null)

  beforeEach(() => {
    let mockFn: mock = %raw(`vi.fn()`)
    revokeMock.contents = Nullable.make(mockFn)
    let _ = %raw(`globalThis.URL = { revokeObjectURL: mockFn }`)

    clearAll()
    mockClear(mockFn)
  })

  test("getSnapshot returns None for unknown scene", t => {
    t->expect(getSnapshot("unknown"))->Expect.toBe(None)
  })

  test("setSnapshot stores url and getSnapshot retrieves it", t => {
    let id = "s1"
    let url = "blob:s1"
    setSnapshot(id, url)

    t->expect(getSnapshot(id))->Expect.toBe(Some(url))
  })

  test("setSnapshot overwrites existing and revokes old url", t => {
    let id = "s1"
    let url1 = "blob:1"
    let url2 = "blob:2"

    setSnapshot(id, url1)
    setSnapshot(id, url2)

    t->expect(getSnapshot(id))->Expect.toBe(Some(url2))

    switch Nullable.toOption(revokeMock.contents) {
    | Some(mock) => expectJs(mock)->toHaveBeenCalledWith(url1)
    | None => t->expect(false)->Expect.toBeTruthy // Mock not initialized
    }
  })

  test("setSnapshot does not revoke if url is identical", t => {
    let id = "s1"
    let url1 = "blob:1"

    setSnapshot(id, url1)

    switch Nullable.toOption(revokeMock.contents) {
    | Some(mock) =>
      mockClear(mock)
      setSnapshot(id, url1)
      expectJs(mock)->not->toHaveBeenCalled()
    | None => t->expect(false)->Expect.toBeTruthy // Mock not initialized
    }
  })

  test("removeKeyOnly removes entry without revoking", t => {
    let id = "s1"
    let url = "blob:1"

    setSnapshot(id, url)
    removeKeyOnly(id)

    t->expect(getSnapshot(id))->Expect.toBe(None)

    switch Nullable.toOption(revokeMock.contents) {
    | Some(mock) => expectJs(mock)->not->toHaveBeenCalled()
    | None => t->expect(false)->Expect.toBeTruthy // Mock not initialized
    }
  })

  test("clearSnapshot removes entry and revokes url", t => {
    let id = "s1"
    let url = "blob:1"

    setSnapshot(id, url)

    switch Nullable.toOption(revokeMock.contents) {
    | Some(mock) =>
      mockClear(mock)
      clearSnapshot(id)

      t->expect(getSnapshot(id))->Expect.toBe(None)
      expectJs(mock)->toHaveBeenCalledWith(url)
    | None => t->expect(false)->Expect.toBeTruthy // Mock not initialized
    }
  })

  test("clearSnapshot does nothing if key missing", t => {
    clearSnapshot("missing")

    switch Nullable.toOption(revokeMock.contents) {
    | Some(mock) => expectJs(mock)->not->toHaveBeenCalled()
    | None => t->expect(false)->Expect.toBeTruthy // Mock not initialized
    }
  })

  test("clearAll revokes all urls and empties cache", t => {
    setSnapshot("s1", "blob:1")
    setSnapshot("s2", "blob:2")

    switch Nullable.toOption(revokeMock.contents) {
    | Some(mock) =>
      mockClear(mock)
      clearAll()

      t->expect(getSnapshot("s1"))->Expect.toBe(None)
      t->expect(getSnapshot("s2"))->Expect.toBe(None)

      expectJs(mock)->toHaveBeenCalledTimes(2)
      expectJs(mock)->toHaveBeenCalledWith("blob:1")
      expectJs(mock)->toHaveBeenCalledWith("blob:2")
    | None => t->expect(false)->Expect.toBeTruthy // Mock not initialized
    }
  })
})
