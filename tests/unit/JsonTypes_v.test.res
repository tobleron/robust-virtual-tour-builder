open Vitest
open JsonTypes

describe("JsonTypes", () => {
  test("decodeProject with valid data", t => {
    let projectJson = JSON.parseOrThrow(`{
      "tourName": "Test Tour",
      "scenes": []
    }`)

    switch decodeProject(projectJson) {
    | Ok(p) => {
        t->expect(Nullable.toOption(p.tourName))->Expect.toBe(Some("Test Tour"))
        t->expect(Array.length(p.scenes))->Expect.toBe(0)
      }
    | Error(msg) => {
        Console.log("decodeProject failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("decodeProject rejects non-object", t => {
    let invalidProjectJson = JSON.parseOrThrow(`"not an object"`)
    switch decodeProject(invalidProjectJson) {
    | Ok(_) => {
        Console.log("decodeProject should have failed for non-object")
        t->expect(true)->Expect.toBe(false)
      }
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("decodeProject rejects array", t => {
    let arrayJson = JSON.parseOrThrow(`[]`)
    switch decodeProject(arrayJson) {
    | Ok(_) => {
        Console.log("decodeProject should have failed for array")
        t->expect(true)->Expect.toBe(false)
      }
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("decodeImportScene with valid data", t => {
    let sceneJson = JSON.parseOrThrow(`{
      "id": "s1",
      "name": "s1.webp",
      "preview": "url1"
    }`)
    switch decodeImportScene(sceneJson) {
    | Ok(s) => {
        t->expect(s.id)->Expect.toBe("s1")
        t->expect(s.name)->Expect.toBe("s1.webp")
      }
    | Error(msg) => {
        Console.log("decodeImportScene failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("decodeImportScene rejects number", t => {
    let invalidSceneJson = JSON.parseOrThrow(`123`)
    switch decodeImportScene(invalidSceneJson) {
    | Ok(_) => {
        Console.log("decodeImportScene should have failed for number")
        t->expect(true)->Expect.toBe(false)
      }
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("decodeImportScene rejects string", t => {
    let stringJson = JSON.parseOrThrow(`"invalid"`)
    switch decodeImportScene(stringJson) {
    | Ok(_) => {
        Console.log("decodeImportScene should have failed for string")
        t->expect(true)->Expect.toBe(false)
      }
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("decodeTimelineItem with valid data", t => {
    let timelineJson = JSON.parseOrThrow(`{
      "id": "t1",
      "linkId": "l1",
      "sceneId": "s1",
      "targetScene": "s2",
      "transition": "fade",
      "duration": 1000
    }`)
    switch decodeTimelineItem(timelineJson) {
    | Ok(t_item) => {
        t->expect(t_item.id)->Expect.toBe("t1")
        t->expect(t_item.linkId)->Expect.toBe("l1")
        t->expect(t_item.sceneId)->Expect.toBe("s1")
        t->expect(t_item.targetScene)->Expect.toBe("s2")
        t->expect(t_item.transition)->Expect.toBe("fade")
        t->expect(t_item.duration)->Expect.toBe(1000)
      }
    | Error(msg) => {
        Console.log("decodeTimelineItem failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("decodeTimelineItem rejects null", t => {
    let invalidTimelineJson = JSON.parseOrThrow(`null`)
    switch decodeTimelineItem(invalidTimelineJson) {
    | Ok(_) => {
        Console.log("decodeTimelineItem should have failed for null")
        t->expect(true)->Expect.toBe(false)
      }
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("decodeTimelineItem rejects boolean", t => {
    let boolJson = JSON.parseOrThrow(`true`)
    switch decodeTimelineItem(boolJson) {
    | Ok(_) => {
        Console.log("decodeTimelineItem should have failed for boolean")
        t->expect(true)->Expect.toBe(false)
      }
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("decodeProject with multiple scenes", t => {
    let projectWithScenesJson = JSON.parseOrThrow(`{
      "tourName": "Multi Scene Tour",
      "scenes": [
        {
          "id": "scene1",
          "name": "Scene 1",
          "file": "scene1.webp"
        },
        {
          "id": "scene2",
          "name": "Scene 2",
          "file": "scene2.webp"
        }
      ]
    }`)
    switch decodeProject(projectWithScenesJson) {
    | Ok(p) => {
        t->expect(Nullable.toOption(p.tourName))->Expect.toBe(Some("Multi Scene Tour"))
        t->expect(Array.length(p.scenes))->Expect.toBe(2)
      }
    | Error(msg) => {
        Console.log("decodeProject with scenes failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("decodeImportScene with optional fields", t => {
    let sceneWithOptionalJson = JSON.parseOrThrow(`{
      "id": "s2",
      "name": "scene2.webp",
      "preview": "url2",
      "tiny": "tiny_url",
      "original": "original_url",
      "quality": "high",
      "colorGroup": "blue"
    }`)
    switch decodeImportScene(sceneWithOptionalJson) {
    | Ok(s) => {
        t->expect(s.id)->Expect.toBe("s2")
        t->expect(s.name)->Expect.toBe("scene2.webp")
        t->expect(Nullable.toOption(s.tiny)->Belt.Option.isSome)->Expect.toBe(true)
        t->expect(Nullable.toOption(s.colorGroup))->Expect.toBe(Some("blue"))
      }
    | Error(msg) => {
        Console.log("decodeImportScene with optional fields failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
