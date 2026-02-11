# 1326: E2E Test - Performance & Regression

## Objective
Run E2E tests for performance metrics, optimistic rollback behavior, and visual regressions in isolation.

## Context
Validation of the user experience quality, speed, and visual consistency.

## Scope
- `tests/e2e/performance.spec.ts`
- `tests/e2e/optimistic-rollback.spec.ts`
- `tests/e2e/visual-regression.spec.ts`

## Steps
1. Run the specified E2E tests: `npx playwright test tests/e2e/performance.spec.ts tests/e2e/optimistic-rollback.spec.ts tests/e2e/visual-regression.spec.ts`
2. Compare performance metrics against baselines (if any).
3. Verify that visual regressions are detected and analyzed.
4. Prepare a detailed report in `docs/_tmp_test_reports/report_performance_regression.md`.
5. The report MUST include:
   - Pass/Fail status.
   - Specific performance bottlenecks.
   - Any visual deviations found.
   - Proposed technical fixes.

## Report File
`docs/_tmp_test_reports/report_performance_regression.md`
