/* tests/unit/JsonTypesTest.res */
open JsonTypes

let run = () => {
  Console.log("Running JsonTypes tests...")

  // Test 1: decodeProject - Valid project with scenes
  let projectJson = JSON.parseOrThrow(`{
    "tourName": "Test Tour",
    "scenes": []
  }`)
  switch decodeProject(projectJson) {
  | Ok(p) => 
      assert(Nullable.toOption(p.tourName) == Some("Test Tour"))
      assert(Array.length(p.scenes) == 0)
      Console.log("✓ decodeProject with valid data")
  | Error(msg) => Console.error("decodeProject failed: " ++ msg)
  }

  // Test 2: decodeProject - Error case with non-object
  let invalidProjectJson = JSON.parseOrThrow(`"not an object"`)
  switch decodeProject(invalidProjectJson) {
  | Ok(_) => Console.error("decodeProject should have failed for non-object")
  | Error(msg) => {
      assert(msg == "Invalid project JSON")
      Console.log("✓ decodeProject rejects non-object")
    }
  }

  // Test 3: decodeProject - Error case with array
  let arrayJson = JSON.parseOrThrow(`[]`)
  switch decodeProject(arrayJson) {
  | Ok(_) => Console.error("decodeProject should have failed for array")
  | Error(msg) => {
      assert(msg == "Invalid project JSON")
      Console.log("✓ decodeProject rejects array")
    }
  }

  // Test 4: decodeImportScene - Valid scene
  let sceneJson = JSON.parseOrThrow(`{
    "id": "s1",
    "name": "s1.webp",
    "preview": "url1"
  }`)
  switch decodeImportScene(sceneJson) {
  | Ok(s) => {
      assert(s.id == "s1")
      assert(s.name == "s1.webp")
      Console.log("✓ decodeImportScene with valid data")
    }
  | Error(msg) => Console.error("decodeImportScene failed: " ++ msg)
  }

  // Test 5: decodeImportScene - Error case with non-object
  let invalidSceneJson = JSON.parseOrThrow(`123`)
  switch decodeImportScene(invalidSceneJson) {
  | Ok(_) => Console.error("decodeImportScene should have failed for number")
  | Error(msg) => {
      assert(msg == "Invalid import scene JSON")
      Console.log("✓ decodeImportScene rejects number")
    }
  }

  // Test 6: decodeImportScene - Error case with string
  let stringJson = JSON.parseOrThrow(`"invalid"`)
  switch decodeImportScene(stringJson) {
  | Ok(_) => Console.error("decodeImportScene should have failed for string")
  | Error(msg) => {
      assert(msg == "Invalid import scene JSON")
      Console.log("✓ decodeImportScene rejects string")
    }
  }

  // Test 7: decodeTimelineItem - Valid timeline item
  let timelineJson = JSON.parseOrThrow(`{
    "id": "t1",
    "linkId": "l1",
    "sceneId": "s1",
    "targetScene": "s2",
    "transition": "fade",
    "duration": 1000
  }`)
  switch decodeTimelineItem(timelineJson) {
  | Ok(t) => {
      assert(t.id == "t1")
      assert(t.linkId == "l1")
      assert(t.sceneId == "s1")
      assert(t.targetScene == "s2")
      assert(t.transition == "fade")
      assert(t.duration == 1000)
      Console.log("✓ decodeTimelineItem with valid data")
    }
  | Error(msg) => Console.error("decodeTimelineItem failed: " ++ msg)
  }

  // Test 8: decodeTimelineItem - Error case with non-object
  let invalidTimelineJson = JSON.parseOrThrow(`null`)
  switch decodeTimelineItem(invalidTimelineJson) {
  | Ok(_) => Console.error("decodeTimelineItem should have failed for null")
  | Error(msg) => {
      assert(msg == "Invalid timeline item JSON")
      Console.log("✓ decodeTimelineItem rejects null")
    }
  }

  // Test 9: decodeTimelineItem - Error case with boolean
  let boolJson = JSON.parseOrThrow(`true`)
  switch decodeTimelineItem(boolJson) {
  | Ok(_) => Console.error("decodeTimelineItem should have failed for boolean")
  | Error(msg) => {
      assert(msg == "Invalid timeline item JSON")
      Console.log("✓ decodeTimelineItem rejects boolean")
    }
  }

  // Test 10: decodeProject - Project with multiple scenes
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
      assert(Nullable.toOption(p.tourName) == Some("Multi Scene Tour"))
      assert(Array.length(p.scenes) == 2)
      Console.log("✓ decodeProject with multiple scenes")
    }
  | Error(msg) => Console.error("decodeProject with scenes failed: " ++ msg)
  }

  // Test 11: decodeImportScene - Scene with optional fields
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
      assert(s.id == "s2")
      assert(s.name == "scene2.webp")
      assert(Nullable.toOption(s.tiny) != None)
      assert(Nullable.toOption(s.colorGroup) == Some("blue"))
      Console.log("✓ decodeImportScene with optional fields")
    }
  | Error(msg) => Console.error("decodeImportScene with optional fields failed: " ++ msg)
  }

  Console.log("✓ All JsonTypes tests passed")
}
