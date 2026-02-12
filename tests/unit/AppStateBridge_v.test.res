open Vitest
open Types
open Actions

describe("AppStateBridge", _ => {
  beforeEach(() => {
    // Reset state before each test
    AppStateBridge.updateState(State.initialState)
  })

  test("Initial state is correct", t => {
    // Ensuring clean slate
    AppStateBridge.updateState(State.initialState)
    let state = AppStateBridge.getState()
    t->expect(state.tourName)->Expect.toBe("Untitled Tour")
  })

  test("updateState and getState work", t => {
    let newState = {...State.initialState, tourName: "Test Tour"}
    AppStateBridge.updateState(newState)
    t->expect(AppStateBridge.getState().tourName)->Expect.toBe("Test Tour")
  })

  test("subscribe and notification work (including unsubscribe)", t => {
    let callCount = ref(0)
    let receivedState = ref(State.initialState)

    let unsubscribe = AppStateBridge.subscribe(
      s => {
        callCount := callCount.contents + 1
        receivedState := s
      },
    )

    let state2 = {...State.initialState, tourName: "Notified Tour"}
    AppStateBridge.updateState(state2)

    t->expect(callCount.contents >= 1)->Expect.toBe(true)
    t->expect(receivedState.contents.tourName)->Expect.toBe("Notified Tour")

    unsubscribe()
    let countAfterUnsub = callCount.contents
    AppStateBridge.updateState({...State.initialState, tourName: "Ignored Update"})

    t->expect(callCount.contents)->Expect.toBe(countAfterUnsub)
  })

  test("registerDispatch and dispatch work", t => {
    let dispatchedAction = ref(None)
    AppStateBridge.registerDispatch(a => dispatchedAction := Some(a))

    let testAction = SetTourName("New Name")
    AppStateBridge.dispatch(testAction)

    switch dispatchedAction.contents {
    | Some(SetTourName(name)) => t->expect(name)->Expect.toBe("New Name")
    | _ => t->expect(true)->Expect.toBe(false)
    }
  })
})
