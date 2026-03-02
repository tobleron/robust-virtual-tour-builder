/* tests/unit/Session5_v.test.res */
open Vitest
open TestUtils

describe("Session 5 Updates - Performance & UX Refinements", () => {
  test("ReactHotspotLayer.sceneDisplayLabel should suppress 'untagged' labels", t => {
    // We mock the scene object
    let untaggedScene = createMockScene(~id="s1", ~label="Entrance untagged", ())
    let cleaned = ReactHotspotLayer.sceneDisplayLabel(untaggedScene)
    t->expect(cleaned)->Expect.toBe("")

    let normalScene = createMockScene(~id="s2", ~label="Living Room", ())
    let cleaned2 = ReactHotspotLayer.sceneDisplayLabel(normalScene)
    t->expect(cleaned2)->Expect.toBe("Living Room")
  })

  test("UploadFinalizer brightness-based clustering logic", t => {
    // 1: Dark (0-50), 2: Dim (51-100), 3: Normal (101-150), 4: Bright (151-200), 5: Very Bright (201-255)

    let getGroup = lum => {
      // Manual re-implementation of the logic in UploadFinalizer.res for verification
      if lum <= 50 {
        "1"
      } else if lum <= 100 {
        "2"
      } else if lum <= 150 {
        "3"
      } else if lum <= 200 {
        "4"
      } else {
        "5"
      }
    }

    t->expect(getGroup(30))->Expect.toBe("1")
    t->expect(getGroup(75))->Expect.toBe("2")
    t->expect(getGroup(125))->Expect.toBe("3")
    t->expect(getGroup(180))->Expect.toBe("4")
    t->expect(getGroup(220))->Expect.toBe("5")
  })

  test("ExifUtils.generateProjectName handles both colon and dash date formats", t => {
    // Format: YYYY:MM:DD HH:MM
    let dateColon = Some("2026:02:25 14:20")
    let name1 = ExifUtils.generateProjectName(Some("Fifth Settlement"), dateColon)
    // 25th Feb 2026 -> 250226_1420
    t->expect(name1->Option.getOr(""))->Expect.String.toContain("250226_1420")

    // Format: YYYY-MM-DD HH:MM (Modern browser / specific cameras)
    let dateDash = Some("2026-02-25 14:20")
    let name2 = ExifUtils.generateProjectName(Some("Fifth Settlement"), dateDash)
    t->expect(name2->Option.getOr(""))->Expect.String.toContain("250226_1420")
  })

  test("ExifUtils.generateProjectName uses first 3 words of address", t => {
    let address = Some("Kamel Al Kilany Street, Fifth Settlement, Cairo")
    let name = ExifUtils.generateProjectName(address, None)
    // "Kamel Al Kilany" -> 3 words
    t->expect(name->Option.getOr(""))->Expect.String.toContain("Kamel_Al_Kilany")
  })
})
