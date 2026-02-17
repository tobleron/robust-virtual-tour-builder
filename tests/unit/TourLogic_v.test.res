open Vitest
open TourLogic

describe("TourLogic", () => {
  test("padStart", t => {
    t->expect(padStart("1", 2, "0"))->Expect.toBe("01")
    t->expect(padStart("10", 2, "0"))->Expect.toBe("10")
    t->expect(padStart("5", 3, "x"))->Expect.toBe("xx5")
  })

  test("sanitizeName", t => {
    t->expect(sanitizeName("Living Room"))->Expect.toBe("Living_Room")
    t->expect(sanitizeName("Kitchen/Dining"))->Expect.toBe("Kitchen_Dining")
    t->expect(sanitizeName(""))->Expect.toBe("Untitled")
    t->expect(sanitizeName("   "))->Expect.toBe("Untitled")
    t->expect(sanitizeName("Test?*|<>"))->Expect.toBe("Test")
    // Test maxLength
    t->expect(String.length(sanitizeName(String.repeat("a", 300))))->Expect.toBe(255)
  })

  test("isUnknownName", t => {
    t->expect(isUnknownName("New Tour"))->Expect.toBe(true)
    t->expect(isUnknownName("new tour..."))->Expect.toBe(true)
    t->expect(isUnknownName("Untitled"))->Expect.toBe(true)
    t->expect(isUnknownName("Real Tour"))->Expect.toBe(false)
    t->expect(isUnknownName("tour_123456_1234"))->Expect.toBe(true)
    t->expect(isUnknownName("saved_rmx_abc"))->Expect.toBe(true)
  })

  test("generateLinkId", t => {
    let used = Belt.Set.String.fromArray(["A01", "A02"])
    t->expect(generateLinkId(used))->Expect.toBe("A00")

    let used2 = Belt.Set.String.fromArray(["A00", "A01"])
    t->expect(generateLinkId(used2))->Expect.toBe("A02")
  })

  test("computeSceneFilename", t => {
    // Standard case: Prefix + Slug (baseName ignored)
    t
    ->expect(computeSceneFilename(0, "Living Room", "DSC001"))
    ->Expect.toBe("001_Living_Room.webp")

    // Empty label case: Just Prefix
    t->expect(computeSceneFilename(9, "", "img_555"))->Expect.toBe("010_Untagged.webp")

    // Dedup case: Doesn't matter anymore as baseName is ignored
    t->expect(computeSceneFilename(1, "Kitchen", "Kitchen"))->Expect.toBe("002_Kitchen.webp")

    // Sanitization check
    t->expect(computeSceneFilename(2, "Bed/Bath", "orig"))->Expect.toBe("003_Bed_Bath.webp")
  })

  test("validateTourIntegrity", t => {
    let state: state = {
      scenes: [
        {
          name: "Scene1",
          hotspots: [{target: "Scene2"}],
        },
        {
          name: "Scene2",
          hotspots: [{target: "Scene3"}], // Missing
        },
      ],
    }
    let integrity = validateTourIntegrity(state)
    t->expect(integrity.totalHotspots)->Expect.toBe(2)
    t->expect(integrity.orphanedLinks)->Expect.toBe(1)
    t->expect(Array.getUnsafe(integrity.details, 0)["sourceScene"])->Expect.toBe("Scene2")
    t->expect(Array.getUnsafe(integrity.details, 0)["targetMissing"])->Expect.toBe("Scene3")
  })
})
