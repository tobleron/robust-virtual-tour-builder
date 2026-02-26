open Vitest

describe("TeaserStyleCatalog", () => {
  test("fast shots and simple crossfade remain available and mappable", t => {
    t->expect(TeaserStyleCatalog.isAvailable(FastShots))->Expect.toBe(true)
    t->expect(TeaserStyleCatalog.isAvailable(SimpleCrossfade))->Expect.toBe(true)
    t->expect(TeaserStyleCatalog.fromString("fast_shots"))->Expect.toEqual(FastShots)
    t->expect(TeaserStyleCatalog.fromString("simple_crossfade"))->Expect.toEqual(SimpleCrossfade)
    t->expect(TeaserStyleCatalog.toString(FastShots))->Expect.toEqual("fast_shots")
    t->expect(TeaserStyleCatalog.toString(SimpleCrossfade))->Expect.toEqual("simple_crossfade")
  })
})
