/* tests/unit/TourLogicTest.res */
open TourLogic

let run = () => {
  Console.log("Running TourLogic tests...")

  // Test sanitizeName
  assert(sanitizeName("Living Room") == "Living_Room")
  assert(sanitizeName("Kitchen/Dining") == "Kitchen_Dining")
  assert(sanitizeName("") == "Untitled")
  assert(sanitizeName("   ") == "Untitled")
  assert(sanitizeName("Test?*|<>") == "Test")
  Console.log("✓ sanitizeName")

  // Test generateLinkId
  let used = Belt.Set.String.fromArray(["A01", "A02"])
  let id1 = generateLinkId(used)
  assert(id1 == "A00") // Loop starts from 00

  let used2 = Belt.Set.String.fromArray(["A00", "A01"])
  let id2 = generateLinkId(used2)
  assert(id2 == "A02")
  Console.log("✓ generateLinkId")

  // Test computeSceneFilename
  assert(computeSceneFilename(0, "Living Room") == "01_living_room.webp")
  assert(computeSceneFilename(9, "") == "10_unnamed.webp")
  Console.log("✓ computeSceneFilename")

  // Test validateTourIntegrity
  let state = {
    scenes: [
      {
        name: "Scene1",
        hotspots: [{target: "Scene2"}],
      },
      {
        name: "Scene2",
        hotspots: [{target: "Scene3"}], // Missing
      },
    ],
  }
  let integrity = validateTourIntegrity(state)
  assert(integrity.totalHotspots == 2)
  assert(integrity.orphanedLinks == 1)
  assert(Array.getUnsafe(integrity.details, 0)["sourceScene"] == "Scene2")
  assert(Array.getUnsafe(integrity.details, 0)["targetMissing"] == "Scene3")
  Console.log("✓ validateTourIntegrity")

  Console.log("TourLogic tests passed!")
}
