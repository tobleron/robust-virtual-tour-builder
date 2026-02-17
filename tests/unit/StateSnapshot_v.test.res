/* tests/unit/StateSnapshot_v.test.res */
open Vitest
open Types
open Actions
open TestUtils

test("StateSnapshot: clear empties history", t => {
  StateSnapshot.clear()
  let state = createMockState(~tourName="Test", ())
  let _ = StateSnapshot.capture(state, SetTourName("A"))
  StateSnapshot.clear()
  t->expect(StateSnapshot.getLatest())->Expect.toBe(None)
})

test("StateSnapshot: capture stores snapshot", t => {
  StateSnapshot.clear()
  let state = createMockState(~tourName="Test", ())
  let action = SetTourName("B")

  let id = StateSnapshot.capture(state, action)

  let latest = StateSnapshot.getLatest()
  switch latest {
  | Some(s) => {
      t->expect(s.id)->Expect.toBe(id)
      t->expect(s.action)->Expect.toEqual(action)
      t->expect(s.state.tourName)->Expect.toBe("Test")
    }
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("StateSnapshot: rollback returns correct state and consumes it", t => {
  StateSnapshot.clear()
  let state1 = createMockState(~tourName="State1", ())
  let id1 = StateSnapshot.capture(state1, SetTourName("Action1"))

  let state2 = createMockState(~tourName="State2", ())
  let _ = StateSnapshot.capture(state2, SetTourName("Action2"))

  // Current history: [Snap2, Snap1]

  let rolledBack = StateSnapshot.rollback(id1)
  switch rolledBack {
  | Some(s) => t->expect(s.tourName)->Expect.toBe("State1")
  | None => t->expect(false)->Expect.toBe(true)
  }

  // Rollback consumes the snapshot and everything newer
  t->expect(StateSnapshot.rollback(id1))->Expect.toBe(None)
})

test("StateSnapshot: max history limit drops oldest", t => {
  StateSnapshot.clear()
  let state = createMockState(~tourName="Base", ())

  let ids = []
  for i in 1 to 15 {
    let id = StateSnapshot.capture(state, SetTourName(Int.toString(i)))
    let _ = Js.Array.push(id, ids)
  }

  // We captured 15. Limit is 10.
  // History should be [id15, ..., id6] (newest first)
  // id1 to id5 should be dropped.

  // id1 is at index 0 of ids array
  t->expect(StateSnapshot.rollback(Belt.Array.getExn(ids, 0)))->Expect.toBe(None)
  t->expect(StateSnapshot.rollback(Belt.Array.getExn(ids, 4)))->Expect.toBe(None)

  // id6 (index 5) should be present
  let res = StateSnapshot.rollback(Belt.Array.getExn(ids, 5))
  switch res {
  | Some(_) => t->expect(true)->Expect.toBe(true)
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("StateSnapshot: commit removes specific snapshot", t => {
  StateSnapshot.clear()
  let state = createMockState(~tourName="Base", ())
  let id1 = StateSnapshot.capture(state, SetTourName("1"))
  let id2 = StateSnapshot.capture(state, SetTourName("2"))

  StateSnapshot.commit(id2) // Remove id2 (newest)

  // id2 should be gone. id1 remains.
  let latest = StateSnapshot.getLatest()
  switch latest {
  | Some(s) => t->expect(s.id)->Expect.toBe(id1)
  | None => t->expect(false)->Expect.toBe(true)
  }
})

test("StateSnapshot: generated ID format check", t => {
  StateSnapshot.clear()
  let state = createMockState(~tourName="Test", ())
  let action = SetTourName("A")

  let id = StateSnapshot.capture(state, action)

  // Assert it's a string with sufficient length (UUID is 36, fallback is > 20)
  t->expect(String.length(id) > 10)->Expect.toBe(true)
})
