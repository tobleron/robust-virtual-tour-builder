# 1548 — Remove Deprecated Visual Pipeline Manual Reorder E2E Test

## Priority: P1 — Test Debt

## Objective
Remove or mark as skipped the E2E test in `feature-deep-dive.spec.ts` that tests drag-and-drop reordering of Visual Pipeline nodes, which is deprecated functionality.

## Context
The Visual Pipeline now uses automatic ordering. Manual drag-and-drop reordering was an old feature that has been deprecated. The E2E test for this functionality may pass or fail unpredictably and tests behavior that no longer exists in the product.

## Acceptance Criteria
- [ ] Identify the specific test case(s) in `feature-deep-dive.spec.ts` that test manual pipeline reordering
- [ ] Either remove the test entirely OR wrap it with `test.skip('reason', ...)` with a clear deprecation note
- [ ] If the test file has other valid tests, ensure they still pass
- [ ] Builds cleanly

## Files to Modify
- `tests/e2e/feature-deep-dive.spec.ts`
