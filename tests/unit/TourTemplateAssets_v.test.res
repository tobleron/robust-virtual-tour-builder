// @efficiency: infra-adapter
/* tests/unit/TourTemplateAssets_v.test.res */
open Vitest
open TourTemplates.TourTemplateAssets

describe("TourTemplateAssets", () => {
  test("generateExportIndex: performs all replacements", t => {
    let tourName = "My_Office_Tour"
    let version = "5.6.7"
    let index = generateExportIndex(tourName, version)

    // Check __TOUR_NAME__
    t->expect(String.includes(index, "My_Office_Tour"))->Expect.toBe(true)

    // Check __TOUR_NAME_PRETTY__
    t->expect(String.includes(index, "My Office Tour"))->Expect.toBe(true)

    // Check __VERSION__
    t->expect(String.includes(index, "Virtual Tour v5.6.7"))->Expect.toBe(true)

    // Check __YEAR__
    let year = Date.make()->Date.getFullYear->Belt.Int.toString
    t->expect(String.includes(index, year))->Expect.toBe(true)

    // Check that placeholders are gone
    t->expect(String.includes(index, "__TOUR_NAME__"))->Expect.toBe(false)
    t->expect(String.includes(index, "__TOUR_NAME_PRETTY__"))->Expect.toBe(false)
    t->expect(String.includes(index, "__VERSION__"))->Expect.toBe(false)
    t->expect(String.includes(index, "__YEAR__"))->Expect.toBe(false)
  })

  test("generateEmbedCodes: returns correct structure for all resolutions", t => {
    let tourName = "Mansion_360"
    let version = "1.0.0"
    let embed = generateEmbedCodes(tourName, version)

    t->expect(String.includes(embed, "Version: 1.0.0"))->Expect.toBe(true)
    t->expect(String.includes(embed, "Property: Mansion_360"))->Expect.toBe(true)

    // Check 4K iframe
    t->expect(String.includes(embed, "tour_4k/index.html"))->Expect.toBe(true)
    t->expect(String.includes(embed, "height=\"640\""))->Expect.toBe(true)

    // Check 2K iframe
    t->expect(String.includes(embed, "tour_2k/index.html"))->Expect.toBe(true)
    t->expect(String.includes(embed, "height=\"400\""))->Expect.toBe(true)

    // Check HD iframe
    t->expect(String.includes(embed, "tour_hd/index.html"))->Expect.toBe(true)
    t->expect(String.includes(embed, "height=\"667\""))->Expect.toBe(true)

    // Basic HTML tag check
    t->expect(String.includes(embed, "<iframe"))->Expect.toBe(true)
  })
})
