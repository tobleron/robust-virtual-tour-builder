/* tests/unit/ReducerJsonTest.res */
open Types
open ReducerHelpers

let run = () => {
  Console.log("Running ReducerJson tests (Obj.magic elimination verification)...")

  // Test 1: Full structure with hotspots and duration
  let json = JSON.parseOrThrow(`{
    "tourName": "Full Project",
    "scenes": [
      {
        "id": "s1",
        "name": "s1.webp",
        "file": {"some": "file"},
        "hotspots": [
           {
             "linkId": "h1",
             "yaw": 10.0,
             "pitch": 20.0,
             "target": "s2.webp",
             "duration": 500,
             "viewFrame": {"yaw": 1.0, "pitch": 2.0, "hfov": 90.0}
           }
        ]
      }
    ]
  }`)
  
  let state = parseProject(json)
  assert(state.tourName == "Full Project")
  
  let s1 = Belt.Array.getExn(state.scenes, 0)
  assert(s1.id == "s1")
  
  let h1 = Belt.Array.getExn(s1.hotspots, 0)
  assert(h1.linkId == "h1")
  assert(h1.yaw == 10.0)
  
  // Verify duration int conversion
  switch h1.duration {
  | Some(d) => assert(d == 500)
  | None => Console.error("Expected duration 500")
  }

  // Verify viewFrame
  switch h1.viewFrame {
  | Some(vf) => 
      // types: vf is viewFrame
      assert(vf.yaw == 1.0)
      assert(vf.pitch == 2.0)
  | None => Console.error("Expected viewFrame")
  }

  Console.log("✓ Parse full project structure")

  // Test 2: Missing optional fields
  let json2 = JSON.parseOrThrow(`{
    "scenes": [
      {
        "name": "min.webp",
        "file": "foo"
      }
    ]
  }`)
  
  let state2 = parseProject(json2)
  assert(state2.tourName == "Imported Tour") // Default
  let s2 = Belt.Array.getExn(state2.scenes, 0)
  assert(s2.id == "legacy_min.webp") // Fallback
  assert(Belt.Array.length(s2.hotspots) == 0)

  Console.log("✓ Parse minimal project structure")

  // Test 3: Timeline Item parsing
  let timelineJson = JSON.parseOrThrow(`{
    "id": "t1",
    "linkId": "l1",
    "sceneId": "s1",
    "targetScene": "s2",
    "transition": "fade",
    "duration": 1000
  }`)
  
  let item = parseTimelineItem(timelineJson)
  assert(item.id == "t1")
  assert(item.duration == 1000)
  
  Console.log("✓ Parse timeline item")
}
