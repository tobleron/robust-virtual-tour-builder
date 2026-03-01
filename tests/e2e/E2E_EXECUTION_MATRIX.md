# E2E Execution Matrix (Task 1507)

## Scope
Behavior-alignment tracking for Playwright specs after architecture/UX updates.

## Status Legend
- `Aligned`: selectors/timing/contract reflect current behavior.
- `Needs Run`: aligned statically, requires runtime verification in target environment.
- `Needs Update`: stale assumptions still present.

## Matrix
| Spec | Status | Notes |
|---|---|---|
| `editor.spec.ts` | Aligned | Tooltip delay assertions use `650ms`. |
| `feature-deep-dive.spec.ts` | Aligned | Visual-pipeline tooltip delay already hardened. |
| `timeline-management.spec.ts` | Aligned | Includes clear-links timeline pruning assertion. |
| `hotspot-move.spec.ts` | Needs Run | Added in current cycle; runtime blocked by local Playwright hang. |
| `scene-delete-undo.spec.ts` | Needs Run | Added in current cycle; list/build verified. |
| `esc-key-cancel.spec.ts` | Needs Run | Added in current cycle; list/build verified. |
| `robustness.spec.ts` | Aligned | Contains lock/capability barrier assertions. |
| `rapid-scene-switching.spec.ts` | Aligned | Navigation stabilization pattern in place. |
| `upload-link-export-workflow.spec.ts` | Needs Update | Requires targeted review for latest export-flow assertions. |
| `perf-budgets.spec.ts` | Needs Update | Needs contract re-check against current operation lifecycle gating. |
| `hotspot-label-sidebar-guard.spec.ts` | Aligned | Covers persistent hotspot labels (builder) and sidebar spinner guardrails. |

## Deterministic Run Order
1. `npx playwright test --list`
2. `npx playwright test tests/e2e/editor.spec.ts --project=chromium`
3. `npx playwright test tests/e2e/timeline-management.spec.ts --project=chromium`
4. `npx playwright test tests/e2e/hotspot-move.spec.ts --project=chromium`
5. `npx playwright test tests/e2e/scene-delete-undo.spec.ts --project=chromium`
6. `npx playwright test tests/e2e/esc-key-cancel.spec.ts --project=chromium`
7. `npm run test:e2e`

## Triage Rubric
- `Timeout waiting for selector`: replace brittle locator with role/name first, then add explicit settle wait.
- `Navigation race`: add `waitForNavigationStabilization(page)` immediately after click.
- `Tooltip flake`: enforce hover + deterministic delay (`650ms+`) before assertion.
- `Blocked-action mismatch`: assert user-visible warning (`Please wait for current operation to finish`) and no state change.
- `Portal/modal selector misses`: use role-based modal/button locators, avoid class-only selectors.

## Residual Risk
- Local environment intermittently hangs during Playwright runtime execution for single-spec runs. Static discovery and build validation pass; runtime certification should be executed in CI or stable host runner.
