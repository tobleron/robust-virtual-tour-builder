# Task: OperationLifecycle TTL Enforcement & Zombie Operation Detection

## Objective
Add TTL (Time-To-Live) enforcement and automatic zombie operation detection to `OperationLifecycle.res` to prevent silent operation leaks that accumulate memory and corrupt UI state tracking.

## Problem Statement
`OperationLifecycle.res` tracks active operations in an in-memory `Belt.Map.String`. Operations that fail to call `complete()`/`fail()` (due to unhandled exceptions, page navigation, or code bugs) remain in the map forever. This causes memory leaks (retained operation metadata + cancel callbacks), stale UI indicators (progress bars showing forever), and incorrect `isActive()` checks blocking new operations.

## Acceptance Criteria
- [ ] Add configurable TTL per operation type: `Upload=600s`, `Export=300s`, `ProjectLoad=120s`, `ProjectSave=60s`, `Navigation=30s`
- [ ] Implement a periodic sweep (every 30s) that detects operations exceeding their TTL
- [ ] Expired operations are auto-failed with error `"OPERATION_TIMEOUT_TTL_EXCEEDED"` and cleaned up
- [ ] Add `Logger.error` diagnostic with operation metadata when TTL expires (signals a code bug)
- [ ] Add operation count watermark: warn at 10+ concurrent operations (should never happen normally)
- [ ] Clean up `cancelCallbacks` map entries when operations complete/fail/cancel (currently only cleaned on cancel)
- [ ] Add `OperationLifecycle.getStats()` for `StateInspector` integration: total active, total completed, total leaked

## Technical Notes
- **Files**: `src/systems/OperationLifecycle.res`, `src/systems/OperationLifecycleTypes.res`
- **Pattern**: `setInterval` sweep with TTL comparison against `startedAt` timestamp
- **Risk**: Low — adds guardrails without changing normal operation flow
- **Measurement**: No active operations should persist longer than TTL in production; verify via diagnostic logging
