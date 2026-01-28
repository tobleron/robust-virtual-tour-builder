open Vitest

describe("Schemas Domain", () => {
  test("project schema with valid data", t => {
    let projectJson = JSON.parseOrThrow(`{
      "tourName": "Test Tour",
      "scenes": []
    }`)

    switch Schemas.parse(projectJson, Schemas.Domain.project) {
    | Ok(p) => {
        t->expect(p.tourName)->Expect.toBe("Test Tour")
        t->expect(Array.length(p.scenes))->Expect.toBe(0)
      }
    | Error(msg) => {
        Console.log("project schema failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("project schema rejects non-object", t => {
    let invalidProjectJson = JSON.parseOrThrow(`"not an object"`)
    switch Schemas.parse(invalidProjectJson, Schemas.Domain.project) {
    | Ok(_) => t->expect(true)->Expect.toBe(false)
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("importScene schema with valid data", t => {
    let sceneJson = JSON.parseOrThrow(`{
      "id": "s1",
      "name": "s1.webp",
      "preview": "url1"
    }`)
    switch Schemas.parse(sceneJson, Schemas.Domain.importScene) {
    | Ok(s) => {
        t->expect(s.id)->Expect.toBe("s1")
        t->expect(s.name)->Expect.toBe("s1.webp")
      }
    | Error(msg) => {
        Console.log("importScene schema failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("timelineItem schema with valid data", t => {
    let timelineJson = JSON.parseOrThrow(`{
      "id": "t1",
      "linkId": "l1",
      "sceneId": "s1",
      "targetScene": "s2",
      "transition": "fade",
      "duration": 1000
    }`)
    switch Schemas.parse(timelineJson, Schemas.Domain.timelineItem) {
    | Ok(t_item) => {
        t->expect(t_item.id)->Expect.toBe("t1")
        t->expect(t_item.linkId)->Expect.toBe("l1")
        t->expect(t_item.sceneId)->Expect.toBe("s1")
        t->expect(t_item.targetScene)->Expect.toBe("s2")
        t->expect(t_item.transition)->Expect.toBe("fade")
        t->expect(t_item.duration)->Expect.toBe(1000)
      }
    | Error(msg) => {
        Console.log("timelineItem schema failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("project schema with multiple scenes", t => {
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
    switch Schemas.parse(projectWithScenesJson, Schemas.Domain.project) {
    | Ok(p) => {
        t->expect(p.tourName)->Expect.toBe("Multi Scene Tour")
        t->expect(Array.length(p.scenes))->Expect.toBe(2)
        let s0 = p.scenes[0]->Option.getOrThrow
        t->expect(s0.name)->Expect.toBe("Scene 1")
      }
    | Error(msg) => {
        Console.log("project with scenes failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("importScene schema with optional fields", t => {
    let sceneWithOptionalJson = JSON.parseOrThrow(`{
      "id": "s2",
      "name": "scene2.webp",
      "file": "url2",
      "tinyFile": "tiny_url",
      "originalFile": "original_url",
      "quality": "high",
      "colorGroup": "blue"
    }`)
    switch Schemas.parse(sceneWithOptionalJson, Schemas.Domain.importScene) {
    | Ok(s) => {
        t->expect(s.id)->Expect.toBe("s2")
        t->expect(s.name)->Expect.toBe("scene2.webp")
        t->expect(Option.isSome(s.tinyFile))->Expect.toBe(true)
        t->expect(s.colorGroup)->Expect.toBe(Some("blue"))
      }
    | Error(msg) => {
        Console.log("importScene with optional fields failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
