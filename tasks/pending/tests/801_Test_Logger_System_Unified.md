# Task: 801 - Test: Logger System Unified Verification (New + Update)

## Objective
Implement comprehensive unit tests for the entire Logger subsystem including logic, telemetry batching, and shared types.

## Merged Tasks
- 783_Test_LoggerLogic_New.md
- 784_Test_LoggerTelemetry_New.md
- 785_Test_LoggerTypes_New.md
- 728_Test_Logger_Update.md

## Technical Context
The Logger system is a critical facade used across the app. This task ensures that console output, async telemetry synchronization, and performance tracking are all verified in a single testing session.

## Implementation Plan
1. **LoggerTypes**: Verify level enumeration and error payload formatting.
2. **LoggerLogic**: Test synchronous log dispatching and performance markers.
3. **LoggerTelemetry**: Mock the backend endpoint and verify that logs are correctly batched and sent via `fetch`.
4. **Logger Facade**: Integration test the main `Logger.res` to ensure it correctly routes calls.

## Verification Criteria
- [ ] Tests pass for `LoggerLogic.res`, `LoggerTelemetry.res`, and `LoggerTypes.res`.
- [ ] Evidence of batching logic working in `LoggerTelemetry`.
- [ ] `npm run test` coverage for logic files > 90%.
