open Vitest
open Types
open Actions

describe("InteractionQueue", () => {
  beforeEach(() => {
    GlobalStateBridge.setDispatch(_ => ())
    GlobalStateBridge.setState(State.initialState)
  })

  testAsync("processes actions sequentially when idle", async t => {
    let receivedActions = []
    let mockDispatch = action => {
      let _ = Js.Array.push(action, receivedActions)
    }
    GlobalStateBridge.setDispatch(mockDispatch)

    InteractionQueue.dispatch(SetTourName("First"))
    InteractionQueue.dispatch(SetTourName("Second"))

    // Wait for async processing
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = setTimeout(() => resolve(), 100)
      },
    )

    t->expect(receivedActions)->Expect.toEqual([SetTourName("First"), SetTourName("Second")])
  })

  testAsync("waits for stability before processing next action", async t => {
    let receivedActions = []

    let mockDispatch = action => {
      let _ = Js.Array.push(action, receivedActions)

      switch action {
      | SetTourName("Trigger Busy") =>
        // Simulate becoming busy immediately after dispatch
        GlobalStateBridge.setState({
          ...State.initialState,
          navigationFsm: NavigationFSM.Transitioning({
            fromSceneId: None,
            toSceneId: "x",
            progress: 0.0,
          }),
        })
      | _ => ()
      }
    }
    GlobalStateBridge.setDispatch(mockDispatch)

    // 1. Dispatch trigger
    InteractionQueue.dispatch(SetTourName("Trigger Busy"))

    // 2. Dispatch next action immediately (should be queued)
    InteractionQueue.dispatch(SetTourName("Should Wait"))

    // Wait 100ms - App is busy, so queue should stall
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = setTimeout(() => resolve(), 100)
      },
    )

    // Expect only first action
    t->expect(receivedActions)->Expect.toEqual([SetTourName("Trigger Busy")])

    // 3. Make App Idle
    GlobalStateBridge.setState(State.initialState)

    // Wait > 50ms (interval)
    let _ = await Promise.make(
      (resolve, _) => {
        let _ = setTimeout(() => resolve(), 150)
      },
    )

    // Expect second action to have run
    t
    ->expect(receivedActions)
    ->Expect.toEqual([SetTourName("Trigger Busy"), SetTourName("Should Wait")])
  })
})
