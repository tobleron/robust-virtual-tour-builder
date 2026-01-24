/* tests/unit/ExifReportGenerator_v.test.res */
open Vitest
open ExifReportGenerator

describe("ExifReportGenerator", () => {
  describe("generateProjectName", () => {
    test(
      "generates name from address and date",
      t => {
        let addr = Some("123 Main St, Los Angeles, CA")
        let dateTime = Some("2025:01:15 14:30:00")
        let name = generateProjectName(addr, dateTime)

        // Expected suffix: 15 (day), 01 (month), 25 (short year), 1430 (time)
        switch name {
        | Some(n) => t->expect(String.startsWith(n, "123_Main_St_150125_1430"))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    test(
      "handles unicode characters in address",
      t => {
        let addr = Some("Straße 123, München, Bayern")
        let dateTime = Some("2024:12:31 23:59:59")
        let name = generateProjectName(addr, dateTime)

        // Capitalization: Strasse -> Strasse (S stays upper, trasse lower)
        // München -> Munchen depends on regex, but if it's \p{L}, it keeps ü
        // ReScript String.charAt and toUpperCase/toLowerCase are Unicode-aware in modern JS.
        switch name {
        | Some(n) =>
          t->expect(String.includes(n, "Stra"))->Expect.toBe(true)
          t->expect(String.includes(n, "311224_2359"))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    test(
      "falls back to 'Tour' when address is missing",
      t => {
        let dateTime = Some("2023:05:20 10:00:00")
        let name = generateProjectName(None, dateTime)

        switch name {
        | Some(n) => t->expect(String.startsWith(n, "Tour_200523_1000"))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    test(
      "falls back to current time when date is missing or invalid",
      t => {
        let addr = Some("Office")
        let name = generateProjectName(addr, None)

        let now = Date.make()
        let day = String.padStart(Belt.Int.toString(Date.getDate(now)), 2, "0")
        let month = String.padStart(Belt.Int.toString(Date.getMonth(now) + 1), 2, "0")

        // name should match Office_DDMMYY_HHmm
        switch name {
        | Some(n) => t->expect(String.startsWith(n, "Office_" ++ day ++ month))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )
  })

  testAsync("generateExifReport: handles empty file list", async t => {
    let result = await generateExifReport([])
    t->expect(String.includes(result.report, "Total Files Analyzed: 0"))->Expect.toBe(true)

    // Suggested name should be generated even with empty list using current timestamp and "Tour"
    switch result.suggestedName {
    | Some(name) => t->expect(String.startsWith(name, "Tour_"))->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }
  })
})
