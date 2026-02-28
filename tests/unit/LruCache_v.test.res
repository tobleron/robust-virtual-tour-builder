open Vitest

describe("LruCache", () => {
  test("evicts least recently used entry when max is exceeded", t => {
    let evictedKeys = ref([])
    let cache = LruCache.make(
      ~maxEntries=2,
      ~onEvict=(key, _) => evictedKeys := [...evictedKeys.contents, key],
    )

    LruCache.set(cache, "a", "A")
    LruCache.set(cache, "b", "B")
    LruCache.set(cache, "c", "C")

    t->expect(LruCache.get(cache, "a"))->Expect.toBe(None)
    t->expect(LruCache.get(cache, "b"))->Expect.toBe(Some("B"))
    t->expect(LruCache.get(cache, "c"))->Expect.toBe(Some("C"))
    t->expect(evictedKeys.contents)->Expect.toEqual(["a"])
  })

  test("get touches key and protects it from next eviction", t => {
    let cache = LruCache.make(~maxEntries=2)
    LruCache.set(cache, "a", "A")
    LruCache.set(cache, "b", "B")
    let _ = LruCache.get(cache, "a")
    LruCache.set(cache, "c", "C")

    t->expect(LruCache.get(cache, "a"))->Expect.toBe(Some("A"))
    t->expect(LruCache.get(cache, "b"))->Expect.toBe(None)
    t->expect(LruCache.get(cache, "c"))->Expect.toBe(Some("C"))
  })

  test("remove invokes onEvict exactly once", t => {
    let evictions = ref(0)
    let cache = LruCache.make(~maxEntries=2, ~onEvict=(_, _) => evictions := evictions.contents + 1)
    LruCache.set(cache, "a", "A")
    LruCache.remove(cache, "a")

    t->expect(evictions.contents)->Expect.toBe(1)
    t->expect(LruCache.get(cache, "a"))->Expect.toBe(None)
  })

  test("clear invokes onEvict for all cached entries", t => {
    let evictions = ref(0)
    let cache = LruCache.make(~maxEntries=5, ~onEvict=(_, _) => evictions := evictions.contents + 1)

    LruCache.set(cache, "a", "A")
    LruCache.set(cache, "b", "B")
    LruCache.set(cache, "c", "C")
    LruCache.clear(cache)

    t->expect(evictions.contents)->Expect.toBe(3)
    t->expect(LruCache.size(cache))->Expect.toBe(0)
  })

  test("shrinkTo removes oldest entries first", t => {
    let evictedKeys = ref([])
    let cache = LruCache.make(
      ~maxEntries=5,
      ~onEvict=(key, _) => evictedKeys := [...evictedKeys.contents, key],
    )

    LruCache.set(cache, "a", "A")
    LruCache.set(cache, "b", "B")
    LruCache.set(cache, "c", "C")
    LruCache.set(cache, "d", "D")
    LruCache.shrinkTo(cache, 2)

    t->expect(evictedKeys.contents)->Expect.toEqual(["a", "b"])
    t->expect(LruCache.get(cache, "c"))->Expect.toBe(Some("C"))
    t->expect(LruCache.get(cache, "d"))->Expect.toBe(Some("D"))
    t->expect(LruCache.size(cache))->Expect.toBe(2)
  })
})
