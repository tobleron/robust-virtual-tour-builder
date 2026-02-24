open Vitest

describe("JsonParsers Domain", () => {
  test("project decoder with valid data", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "tourName": "Test Tour",
        "scenes": []
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }

    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.project) {
    | Ok(p) => {
        t->expect(p.tourName)->Expect.toBe("Test Tour")
        t
        ->expect(Array.length(SceneInventory.getActiveScenes(p.inventory, p.sceneOrder)))
        ->Expect.toBe(0)
      }
    | Error(msg) => {
        Console.log("project decoder failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("project decoder rejects non-object", t => {
    let json = try {
      JSON.parseOrThrow(`"not an object"`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.project) {
    | Ok(_) => t->expect(true)->Expect.toBe(false)
    | Error(msg) => t->expect(String.length(msg) > 0)->Expect.toBe(true)
    }
  })

  test("importScene decoder with valid data", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "id": "s1",
        "name": "s1.webp",
        "file": "url1"
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }

    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.importScene) {
    | Ok(s) => {
        t->expect(s.id)->Expect.toBe("s1")
        t->expect(s.name)->Expect.toBe("s1.webp")
        // Check file
        switch s.file {
        | Url(u) => t->expect(u)->Expect.toBe("url1")
        | _ => t->expect(true)->Expect.toBe(false)
        }
      }
    | Error(msg) => {
        Console.log("importScene decoder failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("timelineItem decoder with valid data", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "id": "t1",
        "linkId": "l1",
        "sceneId": "s1",
        "targetScene": "s2",
        "transition": "fade",
        "duration": 1000
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.timelineItem) {
    | Ok(t_item) => {
        t->expect(t_item.id)->Expect.toBe("t1")
        t->expect(t_item.linkId)->Expect.toBe("l1")
        t->expect(t_item.sceneId)->Expect.toBe("s1")
        t->expect(t_item.targetScene)->Expect.toBe("s2")
        t->expect(t_item.transition)->Expect.toBe("fade")
        t->expect(t_item.duration)->Expect.toBe(1000)
      }
    | Error(msg) => {
        Console.log("timelineItem decoder failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("project decoder with multiple scenes", t => {
    let json = try {
      JSON.parseOrThrow(`{
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
    } catch {
    | _ => failwith("Invalid JSON setup")
    }
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.project) {
    | Ok(p) => {
        t->expect(p.tourName)->Expect.toBe("Multi Scene Tour")
        let scenes = SceneInventory.getActiveScenes(p.inventory, p.sceneOrder)
        t->expect(Array.length(scenes))->Expect.toBe(2)
        let s0 = scenes[0]->Option.getOrThrow
        t->expect(s0.name)->Expect.toBe("Scene 1")
      }
    | Error(msg) => {
        Console.log("project with scenes failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("importScene decoder with optional fields", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "id": "s2",
        "name": "scene2.webp",
        "file": "url2",
        "tinyFile": "tiny_url",
        "originalFile": "original_url",
        "quality": "high",
        "colorGroup": "blue"
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.importScene) {
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
  test("project decoder with modern inventory data and hotspots", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "tourName": "Modern Tour",
        "scenes": [
          { "id": "s1", "name": "S1", "file": "f1.jpg", "hotspots": [
            { "linkId": "L1", "yaw": 10.0, "pitch": 5.0, "target": "S2" }
          ]}
        ],
        "inventory": [
          { "id": "s1", "entry": { 
            "scene": { 
              "id": "s1", 
              "name": "S1", 
              "file": "f1.jpg", 
              "hotspots": [
                { "linkId": "L1", "yaw": 10.0, "pitch": 5.0, "target": "S2" }
              ]
            }, 
            "status": "active" 
          } }
        ],
        "sceneOrder": ["s1"]
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.project) {
    | Ok(p) => {
        t->expect(p.tourName)->Expect.toBe("Modern Tour")
        t->expect(p.sceneOrder)->Expect.toEqual(["s1"])
        let entry = p.inventory->Belt.Map.String.get("s1")->Option.getOrThrow
        t->expect(Array.length(entry.scene.hotspots))->Expect.toBe(1)
        let h = entry.scene.hotspots[0]->Option.getOrThrow
        t->expect(h.linkId)->Expect.toBe("L1")
        t->expect(h.target)->Expect.toBe("S2")
      }
    | Error(msg) => {
        Console.log("modern project with hotspots failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })

  test("project decoder handles legacy migration", t => {
    let json = try {
      JSON.parseOrThrow(`{
        "tourName": "Legacy Tour",
        "scenes": [
          { "id": "legacy1", "name": "Legacy 1", "file": "legacy1.jpg" }
        ]
      }`)
    } catch {
    | _ => failwith("Invalid JSON setup")
    }
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.project) {
    | Ok(p) => {
        t->expect(p.tourName)->Expect.toBe("Legacy Tour")
        // Migration should populate inventory and order from scenes
        t->expect(p.sceneOrder)->Expect.toEqual(["legacy1"])
        t->expect(Belt.Map.String.has(p.inventory, "legacy1"))->Expect.toBe(true)
      }
    | Error(msg) => {
        Console.log("legacy migration failed: " ++ msg)
        t->expect(true)->Expect.toBe(false)
      }
    }
  })
})
