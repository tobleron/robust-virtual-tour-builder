# [1360] FIX: CI Environment Budget Thresholds

## Objective
Make performance budget thresholds environment-aware to prevent false positives in high-overhead environments (like restricted sandboxes or heavily loaded CI runners) while maintaining strict enforcement in production-like environments.

## Context
The `longTaskCount` in the `rapid navigation` budget exceeded the initial threshold of 15 (reaching 21-22) due to the resource constraints of the execution environment. Hard-coded thresholds should be replaced with environment-sensitive defaults or configurable overrides.

## Deliverables
1. Refactored `scripts/check-runtime-budgets.mjs` to support environment-based threshold scaling.
2. Updated `tests/e2e/perf-budgets.spec.ts` to use configurable limits.
3. Documentation of "Baseline" vs "Sandbox/CI" performance expectations.

## Verification
- `npm run budget:ci` passes in the target environment.
- Verified that strict limits still apply when `NODE_ENV=production`.
