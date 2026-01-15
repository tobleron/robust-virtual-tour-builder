/* tests/unit/JsonTypesTest.res */
open JsonTypes

let run = () => {
  Console.log("Running JsonTypes tests...")

  // Test 1: decodeProject
  let projectJson = JSON.parseOrThrow(`{
    "tourName": "Test Tour",
    "scenes": []
  }`)
  switch decodeProject(projectJson) {
  | Ok(p) => 
      assert(Nullable.toOption(p.tourName) == Some("Test Tour"))
      assert(Array.length(p.scenes) == 0)
  | Error(msg) => Console.error("decodeProject failed: " ++ msg)
  }

  // Test 2: decodeImportScene
  let sceneJson = JSON.parseOrThrow(`{
    "id": "s1",
    "name": "s1.webp",
    "preview": "url1"
  }`)
  switch decodeImportScene(sceneJson) {
  | Ok(s) => 
      assert(s.id == "s1")
      assert(s.name == "s1.webp")
  | Error(msg) => Console.error("decodeImportScene failed: " ++ msg)
  }

  // Test 3: decodeTimelineItem
  let timelineJson = JSON.parseOrThrow(`{
    "id": "t1",
    "linkId": "l1",
    "sceneId": "s1",
    "targetScene": "s2",
    "transition": "fade",
    "duration": 1000
  }`)
  switch decodeTimelineItem(timelineJson) {
  | Ok(t) => 
      assert(t.id == "t1")
      assert(t.duration == 1000)
  | Error(msg) => Console.error("decodeTimelineItem failed: " ++ msg)
  }

  Console.log("✓ JsonTypes tests passed")
}
