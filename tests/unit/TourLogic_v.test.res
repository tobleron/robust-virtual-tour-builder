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
    ->expect(computeSceneFilename(1, "Living Room", "DSC001"))
    ->Expect.toBe("001_Living_Room.webp")

    // Empty label case: Just Prefix
    t->expect(computeSceneFilename(10, "", "img_555"))->Expect.toBe("010_Untagged.webp")

    // Dedup case: Doesn't matter anymore as baseName is ignored
    t->expect(computeSceneFilename(2, "Kitchen", "Kitchen"))->Expect.toBe("002_Kitchen.webp")

    // Sanitization check
    t->expect(computeSceneFilename(3, "Bed/Bath", "orig"))->Expect.toBe("003_Bed_Bath.webp")
  })

  test("toUnderscoreDisplayName formats words into underscore-separated title case", t => {
    t->expect(toUnderscoreDisplayName("living room"))->Expect.toBe("Living_Room")
    t->expect(toUnderscoreDisplayName("LIVING_room-main"))->Expect.toBe("Living_Room_Main")
    t->expect(toUnderscoreDisplayName("032_untagged"))->Expect.toBe("032_Untagged")
  })

  test(
    "formatDisplayLabel applies underscore display formatting consistently with persistence naming",
    t => {
      let labeledScene: Types.scene = {
        id: "s1",
        name: "001_living_room.webp",
        file: Url(""),
        tinyFile: None,
        originalFile: None,
        hotspots: [],
        category: "",
        floor: "G",
        label: "living room_main",
        quality: None,
        colorGroup: None,
        _metadataSource: "user",
        categorySet: false,
        labelSet: false,
        isAutoForward: false,
        sequenceId: 1,
      }
      let unnamedScene: Types.scene = {
        ...labeledScene,
        id: "s2",
        name: "032_untagged.webp",
        label: "",
        sequenceId: 0,
      }

      t->expect(formatDisplayLabel(labeledScene))->Expect.toBe("001_Living_Room_Main")
      t->expect(formatDisplayLabel(unnamedScene))->Expect.toBe("032_Untagged")
      t
      ->expect(computeSceneFilename(1, "living room_main", "ignored"))
      ->Expect.toBe("001_Living_Room_Main.webp")
    },
  )

  test("validateTourIntegrity", t => {
    let scenes = [
      {
        name: "Scene1",
        hotspots: [{target: "Scene2"}],
      },
      {
        name: "Scene2",
        hotspots: [{target: "Scene3"}], // Missing
      },
    ]
    let integrity = validateTourIntegrity(scenes)
    t->expect(integrity.totalHotspots)->Expect.toBe(2)
    t->expect(integrity.orphanedLinks)->Expect.toBe(1)
    t->expect(Array.getUnsafe(integrity.details, 0)["sourceScene"])->Expect.toBe("Scene2")
    t->expect(Array.getUnsafe(integrity.details, 0)["targetMissing"])->Expect.toBe("Scene3")
  })
})
