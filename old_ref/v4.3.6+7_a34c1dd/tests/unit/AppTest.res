open Vitest

test("App component exists", t => {
  let _ = App.make
  t->expect(1)->Expect.toBe(1)
})
