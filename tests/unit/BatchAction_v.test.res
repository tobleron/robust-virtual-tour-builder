/* tests/unit/BatchAction_v.test.res */
open Vitest
open Actions
open Types

describe("Batch Action", () => {
  let initialState = State.initialState

  test("Applies multiple actions atomically", t => {
    let actions = [SetTourName("New Tour"), IncrementJourneyId]

    let batchAction = Batch(actions)
    let newState = Reducer.reducer(initialState, batchAction)

    t->expect(newState.tourName)->Expect.toEqual("New_Tour")
    t
    ->expect(newState.navigationState.currentJourneyId)
    ->Expect.toEqual(initialState.navigationState.currentJourneyId + 1)
  })

  test("Handles nested batches", t => {
    let actions = [Batch([SetTourName("Nested Tour")]), IncrementJourneyId]

    let batchAction = Batch(actions)
    let newState = Reducer.reducer(initialState, batchAction)

    t->expect(newState.tourName)->Expect.toEqual("Nested_Tour")
    t
    ->expect(newState.navigationState.currentJourneyId)
    ->Expect.toEqual(initialState.navigationState.currentJourneyId + 1)
  })

  test("State is passed correctly through sequence", t => {
    let actions = [IncrementJourneyId, IncrementJourneyId, IncrementJourneyId]

    let batchAction = Batch(actions)
    let newState = Reducer.reducer(initialState, batchAction)

    t
    ->expect(newState.navigationState.currentJourneyId)
    ->Expect.toEqual(initialState.navigationState.currentJourneyId + 3)
  })
})
