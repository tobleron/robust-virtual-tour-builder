# Task 371: Migrate Core Reducer Tests to Vitest - REPORT

## Objective
Migrate the following legacy unit tests to Vitest and ensure 100% coverage:
- `ReducerTest.res`
- `ReducerHelpersTest.res`
- `RootReducerTest.res`
- `ProjectReducerTest.res`
- `TimelineReducerTest.res`

## Realization
1. **Migration to Vitest**: Successfully created 5 new test files in `tests/unit/` using the `_v.test.res` postfix:
    - `Reducer_v.test.res`
    - `ReducerHelpers_v.test.res`
    - `RootReducer_v.test.res`
    - `ProjectReducer_v.test.res`
    - `TimelineReducer_v.test.res`
2. **Standard Alignment**: Followed functional testing standards using `Vitest` bindings (`describe`, `test`, `expect`).
3. **Integration**: Commented out the corresponding legacy `run()` calls in `tests/TestRunner.res`.
4. **Cleanup**: Deleted the legacy `.res` and `.bs.js` files for the migrated tests.
5. **Verification**: 
    - Resolved compilation errors related to `initialState` module pathing and variant constructor mismatches.
    - Verified all 434 frontend tests pass using `npm run test:frontend`.

