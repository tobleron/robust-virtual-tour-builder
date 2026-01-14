open ReBindings
open StateInspector

let run = () => {
  Console.log("Running StateInspector tests...")
  // Smoke test for creation of snapshot
  let state = GlobalStateBridge.getState()
  let snapshot = createSnapshot(state)
  assert(snapshot.tourName == state.tourName)
  Console.log("✓ StateInspector: createSnapshot verified")
}
