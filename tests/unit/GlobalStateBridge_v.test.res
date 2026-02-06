open Vitest
open Types
open Actions

describe("GlobalStateBridge", _ => {
  beforeEach(() => {
    // Reset state before each test
    GlobalStateBridge.setState(State.initialState)
  })

  test("Initial state is correct", t => {
    // Ensuring clean slate
    GlobalStateBridge.setState(State.initialState)
    let state = GlobalStateBridge.getState()
    t->expect(state.tourName)->Expect.toBe("Untitled Tour")
  })

  test("setState and getState work", t => {
    let newState = {...State.initialState, tourName: "Test Tour"}
    GlobalStateBridge.setState(newState)
    t->expect(GlobalStateBridge.getState().tourName)->Expect.toBe("Test Tour")
  })

  test("subscribe and notification work (including unsubscribe)", t => {
    let callCount = ref(0)
    let receivedState = ref(State.initialState)

    let unsubscribe = GlobalStateBridge.subscribe(
      s => {
        callCount := callCount.contents + 1
        receivedState := s
      },
    )

    let state2 = {...State.initialState, tourName: "Notified Tour"}
    GlobalStateBridge.setState(state2)

    t->expect(callCount.contents >= 1)->Expect.toBe(true)
    t->expect(receivedState.contents.tourName)->Expect.toBe("Notified Tour")

    unsubscribe()
    let countAfterUnsub = callCount.contents
    GlobalStateBridge.setState({...State.initialState, tourName: "Ignored Update"})

    t->expect(callCount.contents)->Expect.toBe(countAfterUnsub)
  })

  test("setDispatch and dispatch work", t => {
    let dispatchedAction = ref(None)
    GlobalStateBridge.setDispatch(a => dispatchedAction := Some(a))

    let testAction = SetTourName("New Name")
    GlobalStateBridge.dispatch(testAction)

    switch dispatchedAction.contents {
    | Some(SetTourName(name)) => t->expect(name)->Expect.toBe("New Name")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })
})
