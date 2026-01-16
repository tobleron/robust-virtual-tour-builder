/* tests/unit/GlobalStateBridgeTest.res */
open Types
open Actions

let run = () => {
  Console.log("Running GlobalStateBridge tests...")

  // 1. Initial State
  let initial = GlobalStateBridge.getState()
  // Note: Since this is a singleton, previous tests might have modified it.
  // But for a clean run, it should be initial.
  // We can force it back to initial for predictably.
  GlobalStateBridge.setState(State.initialState)
  let state1 = GlobalStateBridge.getState()
  assert(state1.tourName == "")
  Console.log("✓ Initial state is correct")

  // 2. setState and getState
  let newState = {...State.initialState, tourName: "Test Tour"}
  GlobalStateBridge.setState(newState)
  assert(GlobalStateBridge.getState().tourName == "Test Tour")
  Console.log("✓ setState and getState work")

  // 3. subscribe and notify
  let callCount = ref(0)
  let receivedState = ref(State.initialState)

  GlobalStateBridge.subscribe(s => {
    callCount := callCount.contents + 1
    receivedState := s
  })

  let state2 = {...State.initialState, tourName: "Notified Tour"}
  GlobalStateBridge.setState(state2)

  // Note: if other tests subscribed, they would also be called, but we only care about ours.
  assert(callCount.contents >= 1)
  assert(receivedState.contents.tourName == "Notified Tour")
  Console.log("✓ subscribe and notification work")

  // 4. setDispatch and dispatch
  let dispatchedAction = ref(None)
  GlobalStateBridge.setDispatch(a => dispatchedAction := Some(a))

  let testAction = SetTourName("New Name")
  GlobalStateBridge.dispatch(testAction)

  switch dispatchedAction.contents {
  | Some(SetTourName(name)) => assert(name == "New Name")
  | _ => assert(false)
  }
  Console.log("✓ setDispatch and dispatch work")

  Console.log("GlobalStateBridge tests passed!")
}
