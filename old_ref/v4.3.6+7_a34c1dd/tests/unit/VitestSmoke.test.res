open Vitest

test("Vitest smoke test", t => {
  t->expect(1 + 2)->Expect.toBe(3)
})

test("Vitest string comparison", t => {
  t->expect("hello")->Expect.toBe("hello")
})
