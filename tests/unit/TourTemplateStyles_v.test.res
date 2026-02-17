// @efficiency: infra-adapter
/* tests/unit/TourTemplateStyles_v.test.res */
open Vitest
open TourTemplates.TourTemplateStyles

let _ = describe("TourTemplateStyles", () => {
  test("generateCSS creates correct styles for Desktop 4K", t => {
    let css = generateCSS("scene1.jpg", "4k", 32, 40)

    t->expect(String.includes(css, "scene1.jpg"))->Expect.toBe(true)
    t->expect(String.includes(css, "max-width: 1024px"))->Expect.toBe(true)
    t->expect(String.includes(css, "min-width: 640px"))->Expect.toBe(true)
    t->expect(String.includes(css, "height: 32px"))->Expect.toBe(true) // Base size
    t->expect(String.includes(css, "height: 40px"))->Expect.toBe(true) // Logo size
    t->expect(String.includes(css, "margin-left: -16px"))->Expect.toBe(true) // Half base size
  })

  test("generateCSS creates responsive styles for HD (same viewport model as 2k)", t => {
    let css = generateCSS("mob.jpg", "hd", 24, 30)

    t->expect(String.includes(css, "mob.jpg"))->Expect.toBe(true)
    t->expect(String.includes(css, "width: clamp(375px, 95vw, 640px)"))->Expect.toBe(true)
    t->expect(String.includes(css, "min-width: 375px"))->Expect.toBe(true)
    t->expect(String.includes(css, "max-width: 640px"))->Expect.toBe(true)
    t->expect(String.includes(css, "height: 24px"))->Expect.toBe(true)
    t->expect(String.includes(css, "margin-left: -12px"))->Expect.toBe(true)
  })
})
