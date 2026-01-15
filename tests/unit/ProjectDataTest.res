/* tests/unit/ProjectDataTest.res */
open ProjectData

let run = () => {
  Console.log("Running ProjectData tests...")
  
  // Test: version exists
  assert(version != "")
  
  // Test: sanitizeLoadedScenes handles empty array
  let empty = sanitizeLoadedScenes([])
  assert(Array.length(empty) == 0)
  
  Console.log("✓ ProjectData tests passed")
}
