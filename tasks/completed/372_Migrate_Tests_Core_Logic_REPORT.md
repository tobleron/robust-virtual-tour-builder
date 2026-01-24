# Task 372: Migrate Core Logic & Communication Tests to Vitest

## Objective
Migrate the following legacy unit tests to Vitest and ensure 100% coverage:
- `ActionsTest.res`
- `EventBusTest.res`
- `GlobalStateBridgeTest.res`
- `SharedTypesTest.res`
- `StateInspectorTest.res`

## Outcome
Successfully migrated all specified legacy tests to Vitest.

### Technical Details
1.  **Created Vitest Versions**:
    - `tests/unit/Actions_v.test.res`: Covers 100% of action string representations.
    - `tests/unit/EventBus_v.test.res`: Covers pub/sub logic, unsubscription (single/all), error handling isolation, and payload delivery for all event types.
    - `tests/unit/GlobalStateBridge_v.test.res`: Covers singleton state access, updates, subscription notifications, and dispatch bridging.
    - `tests/unit/SharedTypes_v.test.res`: Covers JSON mapping for `metadataResponse` (using strict `Nullable` checks) and `validationReport`.
    - `tests/unit/StateInspector_v.test.res`: Covers snapshot creation and data integrity.

2.  **Legacy Cleanup**:
    - Removed `tests/unit/ActionsTest.res`, `eventBusTest.res`, `GlobalStateBridgeTest.res`, `SharedTypesTest.res`, `StateInspectorTest.res`.
    - Updated `tests/TestRunner.res` to remove calls to these legacy modules.
    - Cleaned up build artifacts.

3.  **Verification**:
    - Running `npm run test:frontend` confirms 84 test files passed (up from ~79-81), with 502 total tests passed.
    - Legacy test runner no longer executes the migrated tests.
    - Vitest execution confirms all new tests pass.

## Breaking Changes
None. Internal test infrastructure update only.
