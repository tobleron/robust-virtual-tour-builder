open RescriptMocha

describe("SimulationSystem Reducer", () => {
  it("StartAutoPilot sets isAutoPilot to true", () => {
    let initial = SimulationSystem.makeInitialState()
    let updated = SimulationSystem.reduceSimulation(initial, StartAutoPilot(42, false))
    
    Assert.equal(updated.isAutoPilot, true)
    Assert.equal(updated.autoPilotJourneyId, 42)
    Assert.equal(Array.length(updated.visitedScenes), 0)
  })
  
  it("StopAutoPilot resets state", () => {
    let initial = {...SimulationSystem.makeInitialState(), isAutoPilot: true, pendingAdvanceId: Some(5)}
    let updated = SimulationSystem.reduceSimulation(initial, StopAutoPilot)
    
    Assert.equal(updated.isAutoPilot, false)
    Assert.equal(updated.pendingAdvanceId, None)
  })
  
  it("AddVisitedScene appends to array", () => {
    let initial = {...SimulationSystem.makeInitialState(), visitedScenes: [1, 2]}
    let updated = SimulationSystem.reduceSimulation(initial, AddVisitedScene(3))
    
    Assert.deepEqual(updated.visitedScenes, [1, 2, 3])
  })
  
  it("IncrementJourneyId increments", () => {
    let initial = {...SimulationSystem.makeInitialState(), autoPilotJourneyId: 5}
    let updated = SimulationSystem.reduceSimulation(initial, IncrementJourneyId)
    
    Assert.equal(updated.autoPilotJourneyId, 6)
  })
})
