open StateInspector

let run = () => {
  Console.log("Running StateInspector tests...")
  
  // Test createSnapshot
  let state = GlobalStateBridge.getState()
  let snapshot = createSnapshot(state)
  
  assert(snapshot.tourName == state.tourName)
  assert(snapshot.activeSceneIndex == state.activeIndex)
  assert(snapshot.sceneCount == Belt.Array.length(state.scenes))
  assert(snapshot.isLinking == state.isLinking)
  assert(snapshot.isSimulationMode == state.isSimulationMode)
  assert(snapshot.timestamp > 0.0)
  
  Console.log("✓ StateInspector: createSnapshot verified")
}
