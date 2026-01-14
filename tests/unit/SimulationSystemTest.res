/* tests/unit/SimulationSystemTest.res */

let run = () => {
  Console.log("Running SimulationSystem tests...")

  // Test StartAutoPilot
  let initial = SimulationSystem.makeInitialState()
  let updated = SimulationSystem.reduceSimulation(initial, StartAutoPilot(42, false))
  
  assert(updated.isAutoPilot == true)
  assert(updated.autoPilotJourneyId == 42)
  assert(Array.length(updated.visitedScenes) == 0)
  Console.log("✓ StartAutoPilot")

  // Test StopAutoPilot
  let initialForStop = {...SimulationSystem.makeInitialState(), isAutoPilot: true, pendingAdvanceId: Some(5)}
  let updatedForStop = SimulationSystem.reduceSimulation(initialForStop, StopAutoPilot)
  
  assert(updatedForStop.isAutoPilot == false)
  assert(updatedForStop.pendingAdvanceId == None)
  Console.log("✓ StopAutoPilot")

  // Test AddVisitedScene
  let initialForAdd = {...SimulationSystem.makeInitialState(), visitedScenes: [1, 2]}
  let updatedForAdd = SimulationSystem.reduceSimulation(initialForAdd, AddVisitedScene(3))
  
  // ReScript doesn't have a direct deepEqual for assert, so we'll check manually
  assert(Array.length(updatedForAdd.visitedScenes) == 3)
  assert(Array.getUnsafe(updatedForAdd.visitedScenes, 0) == 1)
  assert(Array.getUnsafe(updatedForAdd.visitedScenes, 1) == 2)
  assert(Array.getUnsafe(updatedForAdd.visitedScenes, 2) == 3)
  Console.log("✓ AddVisitedScene")

  // Test IncrementJourneyId
  let initialForInc = {...SimulationSystem.makeInitialState(), autoPilotJourneyId: 5}
  let updatedForInc = SimulationSystem.reduceSimulation(initialForInc, IncrementJourneyId)
  
  assert(updatedForInc.autoPilotJourneyId == 6)
  Console.log("✓ IncrementJourneyId")

  Console.log("SimulationSystem tests passed!")
}
