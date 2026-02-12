# 1326: E2E Test - Performance & Regression

## Objective
Run E2E tests for performance metrics, optimistic rollback behavior, and visual regressions in isolation.

## Context
Validation of the user experience quality, speed, and visual consistency.

## Scope
- `tests/e2e/performance.spec.ts`
- `tests/e2e/optimistic-rollback.spec.ts`
- `tests/e2e/visual-regression.spec.ts`
- `tests/e2e/perf-budgets.spec.ts` (@budget guardrails)

## Steps
1. Run the specified E2E tests: `npx playwright test tests/e2e/performance.spec.ts tests/e2e/optimistic-rollback.spec.ts tests/e2e/visual-regression.spec.ts`
2. Run the budget guardrails: `npx playwright test tests/e2e/perf-budgets.spec.ts --project=chromium-budget` and confirm `artifacts/perf-budget-metrics.json` is generated.
3. Compare performance metrics against baselines (if any) and ensure the budget metrics artifact meets the configured thresholds.
4. Verify that visual regressions are detected and analyzed.
5. Prepare a detailed report in `docs/_pending_integration/e2e_performance_regression_report.md`.
6. The report MUST include:
   - Pass/Fail status for every spec (including `@budget`).
   - Specific performance bottlenecks and budget violations (if any).
   - Visual deviations found.
   - Location of `artifacts/perf-budget-metrics.json` and its key findings.
   - Proposed technical fixes.

## Report File
`docs/_pending_integration/e2e_performance_regression_report.md`
