# 1362: Align E2E Tests & Task Tracking

## Objective
Polish the core Playwright suite so every spec is properly instrumented, resilient, and accounted for, and refresh the related task descriptions (reports, priorities, and scopes) so there are no untracked or "zombie" E2E checks in the backlog.

## Context
Some suites (desktop import, ingestion, navigation, optimistic rollback, operation recovery, rapid scene switching) still lack the AI observability plumbing used elsewhere and were never re-checked after the new performance budgets test landed. The task tracker references dated report locations and doesn’t include the `perf-budgets` guardrails.

## Scope
- `tests/e2e/desktop-import.spec.ts`
- `tests/e2e/ingestion.spec.ts`
- `tests/e2e/navigation.spec.ts`
- `tests/e2e/rapid-scene-switching.spec.ts`
- `tests/e2e/operation-recovery.spec.ts`
- `tests/e2e/optimistic-rollback.spec.ts`
- `tasks/pending/1319_E2E_Test_Ingestion_Import.md`
- `tasks/pending/1320_E2E_Test_Upload_Link_Export.md`
- `tasks/pending/1321_E2E_Test_Editor_Features.md`
- `tasks/pending/1322_E2E_Test_Navigation_Switching.md`
- `tasks/pending/1323_E2E_Test_Simulation_Teaser.md`
- `tasks/pending/1324_E2E_Test_Recovery_Persistence.md`
- `tasks/pending/1325_E2E_Test_Robustness_Resilience.md`
- `tasks/pending/1326_E2E_Test_Performance_Regression.md`

## Steps
1. Add `setupAIObservability` to the tests above (import the helper, call it before the first navigation, and keep the storage-clearing + reload guard used by the other suites).
2. Confirm the Playwright logs stay clean (remove duplicated console listeners only if they conflict with the helper).
3. Update every affected task to point reports at `docs/_pending_integration/e2e_<summary>_report.md` and keep the `perf-budgets` spec under the performance/regression umbrella (include the `chromium-budget` project run and the artifact path).
4. Ensure no other specs exist without a corresponding task (i.e., the tracker now mentions `tests/e2e/perf-budgets.spec.ts`).
5. Run `npm run build` to prove the code still compiles.
6. Summarize the test and task updates in the completion note; the new task file becomes the official delivery ticket.

## Verification
- `npm run build`
- Each modified test calls `setupAIObservability` and still clears storage before importing/uploading.
- Task 1326 now lists `tests/e2e/perf-budgets.spec.ts` and describes how to run it (`--project=chromium-budget`).
- Report guidelines all point to `docs/_pending_integration`.
