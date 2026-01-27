# Task: 819 - Test: Core Reducers & Global State (Unified)

## Objective
Verify the correctness of the Redux-like state reducers that drive the application.

## Merged Tasks
- 648_Test_Reducer_Update.md
- 649_Test_SceneCache_Update.md
- 651_Test_SharedTypes_Update.md
- 653_Test_State_Update.md
- 654_Test_Types_Update.md
- 662_Test_RootReducer_Update.md
- 663_Test_SceneReducer_Update.md
- 665_Test_TimelineReducer_Update.md
- 666_Test_UiReducer_Update.md
- 667_Test_mod_Update.md

## Technical Context
The `Reducer` logic is the source of truth for all state changes. Testing it in isolation is high-value.

## Implementation Plan
1. **RootReducer**: Verify delegation to sub-reducers.
2. **Domain Reducers**: Test Scene, Timeline, and UI specific actions.
3. **Types/State**: Verify initial state factories and type consistency.

## Verification Criteria
- [ ] All reducers allow valid state transitions.
- [ ] Immutability is preserved (ReScript guarantees this, but logic might not).
