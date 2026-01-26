open Vitest

describe("TeaserPlayback", () => {
  test("wait helper returns a promise", t => {
    let p = TeaserPlayback.wait(10)
    t->expect(p)->Expect.not->Expect.toEqual(Obj.magic(None))
  })
})
