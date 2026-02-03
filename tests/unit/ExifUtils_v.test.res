open Vitest
open ExifUtils

describe("ExifUtils", () => {
  test("cleanLocationWord cleans and capitalizes", t => {
    t->expect(cleanLocationWord("pa@ris!"))->Expect.toBe("Paris")
    t->expect(cleanLocationWord("NEW-YORK"))->Expect.toBe("Newyork")
    t->expect(cleanLocationWord("abc"))->Expect.toBe("Abc")
  })

  test("extractLocationName pulls words from address", t => {
    let addr = "123 Main St, Springfield, IL"
    // selectedWords will be ["123", "Main", "St"] (limit 3)
    t->expect(extractLocationName(addr))->Expect.toBe(Some("123_Main_St"))
  })

  test("extractLocationName handles messy address", t => {
    let addr = "Area 51 , Secret Base"
    t->expect(extractLocationName(addr))->Expect.toBe(Some("Area_51_Secret"))
  })

  test("generateProjectName combines location and date", t => {
    let address = Some("White House, DC")
    let dateTime = Some("2024:05:20 14:30:00")

    // locationPart: White_House_Dc (words: ["White", "House,", "DC"] -> ["White", "House", "DC"] -> ["White", "House", "Dc"])
    // timestampPart: 200524_1430
    // Result: White_House_Dc_200524_1430

    t
    ->expect(generateProjectName(address, dateTime))
    ->Expect.toBe(Some("White_House_Dc_200524_1430"))
  })

  test("generateProjectName handles missing parts", t => {
    let dateTime = Some("2024:01:01 12:00:00")
    // loc defaults to "Tour"
    t->expect(generateProjectName(None, dateTime))->Expect.toBe(Some("Tour_010124_1200"))
  })
})
