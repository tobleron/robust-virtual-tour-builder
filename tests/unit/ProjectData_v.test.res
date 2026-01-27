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
      "file": "dummy.jpg",
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
      "file": "full.jpg",
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
    }

    let mockState: Types.state = {
      ...State.initialState,
      tourName: "Test Tour",
      activeIndex: 5,
      deletedSceneIds: ["del1"],
      scenes: [s1],
      lastUsedCategory: "custom-cat",
      exifReport: Some(JSON.Encode.string("mock-exif")),
    }

    let json = toJSON(mockState)
    let d = (Obj.magic(json): {..})

    t->expect(d["tourName"])->Expect.toBe("Test Tour")
    t->expect(d["activeIndex"])->Expect.toBe(5)
    t->expect(d["deletedSceneIds"])->Expect.toEqual(["del1"])
    t->expect(d["lastUsedCategory"])->Expect.toBe("custom-cat")
    t->expect(Obj.magic(d["exifReport"]))->Expect.toBe("mock-exif")

    let scenes = (Obj.magic(d["scenes"]): array<{..}>)
    t->expect(Belt.Array.length(scenes))->Expect.toBe(1)
    t->expect(Belt.Array.getExn(scenes, 0)["id"])->Expect.toBe("s1")
    t->expect(Belt.Array.getExn(scenes, 0)["_metadataSource"])->Expect.toBe("user")
  })

  test("Round-trip serialization preserves data", t => {
    let s1: scene = {
      id: "s1",
      name: "S1",
      file: Url("f"),
      tinyFile: None,
      originalFile: None,
      hotspots: [
        {
          linkId: "l1",
          yaw: 0.0,
          pitch: 0.0,
          target: "target",
          targetYaw: None,
          targetPitch: None,
          targetHfov: None,
          startYaw: None,
          startPitch: None,
          startHfov: None,
          isReturnLink: None,
          viewFrame: None,
          returnViewFrame: None,
          waypoints: None,
          displayPitch: None,
          transition: None,
          duration: None,
        },
      ],
      category: "cat1",
      floor: "1",
      label: "label1",
      quality: None,
      colorGroup: Some("red"),
      _metadataSource: "user",
      categorySet: true,
      labelSet: true,
      isAutoForward: true,
    }

    let originalState: Types.state = {
      ...State.initialState,
      tourName: "Round Trip Tour",
      activeIndex: 0,
      scenes: [s1],
      lastUsedCategory: "custom-cat",
      sessionId: Some("session_123"),
      deletedSceneIds: ["del1", "del2"],
    }

    let json = toJSON(originalState)

    // Simulate ProjectManagerLogic enrichment (backend restores file paths)
    let jsonDict = Obj.magic(json)
    let scenes = jsonDict["scenes"]
    Belt.Array.forEach(
      scenes,
      s => {
        s["file"] = "mock_file_url"
      },
    )

    // We use SceneHelpers.parseProject to simulate loading the project
    let restoredState = SceneHelpers.parseProject(Obj.magic(json))

    t->expect(restoredState.tourName)->Expect.toBe(originalState.tourName)
    t->expect(restoredState.sessionId)->Expect.toBe(originalState.sessionId)
    t->expect(Array.length(restoredState.scenes))->Expect.toBe(1)

    let rs1 = restoredState.scenes[0]->Option.getOrThrow
    t->expect(rs1.id)->Expect.toBe(s1.id)
    t->expect(rs1.name)->Expect.toBe(s1.name)
    t->expect(rs1.colorGroup)->Expect.toBe(s1.colorGroup)
    // Check file was restored (from our mock injection)
    switch rs1.file {
    | Url(u) => t->expect(u)->Expect.toBe("mock_file_url")
    | _ => t->expect(false)->Expect.toBe(true)
    }

    // Check if deletedSceneIds are preserved
    t->expect(restoredState.deletedSceneIds)->Expect.toEqual(originalState.deletedSceneIds)
  })
})
