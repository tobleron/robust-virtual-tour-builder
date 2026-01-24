/* tests/unit/ProjectData_v.test.res */
open Vitest
open ProjectData
open Types

let _ = describe("ProjectData", () => {
  test("VersionData.version should exist", t => {
    t->expect(VersionData.version != "")->Expect.toBe(true)
  })

  test("sanitizeLoadedScenes handles empty array", t => {
    let res = sanitizeLoadedScenes([])
    t->expect(Belt.Array.length(res))->Expect.toBe(0)
  })

  test("sanitizeLoadedScenes fills defaults", t => {
    let mockRaw = {
      "name": "Minimal",
    }
    let res = sanitizeLoadedScenes([Obj.magic(mockRaw)])
    t->expect(Belt.Array.length(res))->Expect.toBe(1)

    let s = (Obj.magic(Belt.Array.getExn(res, 0)): {..})
    t->expect(s["id"])->Expect.toBe("legacy_Minimal")
    t->expect(s["category"])->Expect.toBe("outdoor")
    t->expect(s["isAutoForward"])->Expect.toBe(false)
  })

  test("sanitizeLoadedScenes preserves data", t => {
    let mockRaw = {
      "id": "uniq",
      "name": "Full",
      "category": "indoor",
      "isAutoForward": true,
      "hotspots": [
        {
          "pitch": 10.0,
          "yaw": 20.0,
          "target": "target1",
        },
      ],
    }
    let res = sanitizeLoadedScenes([Obj.magic(mockRaw)])
    let s = (Obj.magic(Belt.Array.getExn(res, 0)): {..})

    t->expect(s["id"])->Expect.toBe("uniq")
    t->expect(s["name"])->Expect.toBe("Full")
    t->expect(s["isAutoForward"])->Expect.toBe(true)
    t->expect(Belt.Array.length(s["hotspots"]))->Expect.toBe(1)
  })

  test("toJSON serializes state correctly", t => {
    let s1: scene = {
      id: "s1",
      name: "S1",
      file: Url("f"),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "cat1",
      floor: "1",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "user",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      preCalculatedSnapshot: None,
    }

    let mockState: Types.state = {
      ...State.initialState,
      tourName: "Test Tour",
      activeIndex: 5,
      deletedSceneIds: ["del1"],
      scenes: [s1],
    }

    let json = toJSON(mockState)
    let d = (Obj.magic(json): {..})

    t->expect(d["tourName"])->Expect.toBe("Test Tour")
    t->expect(d["activeIndex"])->Expect.toBe(5)
    t->expect(d["deletedSceneIds"])->Expect.toEqual(["del1"])

    let scenes = (Obj.magic(d["scenes"]): array<{..}>)
    t->expect(Belt.Array.length(scenes))->Expect.toBe(1)
    t->expect(Belt.Array.getExn(scenes, 0)["id"])->Expect.toBe("s1")
  })
})
