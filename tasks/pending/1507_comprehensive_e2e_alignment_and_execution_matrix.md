# Task 1507: Comprehensive E2E Alignment and Execution Matrix

## Objective
Bring the Playwright E2E suite fully in sync with the latest architecture/UX behavior and produce a deterministic certification runbook that can be executed later without ad-hoc troubleshooting.

## Context
Recent platform changes modified interaction semantics and timing behavior:
- Operation lifecycle visibility thresholds by operation type.
- Utility interaction capability gating.
- Visual pipeline tooltip reveal delay (`600ms`) and resized hover card.
- Scene link-clearing behavior now prunes timeline entries for the cleared scene.

This task formalizes E2E alignment so tests validate the current product contract, not historical behavior.

## Scope
1. Audit all E2E specs for stale assumptions (timing, selector, lock-policy, operation messaging).
2. Update brittle selectors to role/semantic locators where possible.
3. Encode deterministic waits for async transitions (navigation settle, delayed tooltip visibility, operation lifecycle transitions).
4. Add explicit coverage for clear-links timeline pruning behavior.
5. Add explicit coverage for capability-gated actions (link/sim controls while blocked).
6. Ensure upload/load/export scenarios assert final state, not transient implementation details.
7. Produce execution matrix and triage rubric for failed runs.

## Required Updates
1. **Visual Pipeline Timing**
- Ensure hover-tooltip tests account for `600ms` delayed reveal.
- Ensure tooltip assertions target visible state and not immediate hover side effects.

2. **Scene Link-Clear Contract**
- Add/adjust scenario:
  - Create link(s) for scene.
  - Verify pipeline node count reflects linked step(s).
  - Trigger `Clear Links` on that scene.
  - Verify corresponding pipeline node(s) are removed.

3. **Capability/Lock Policy Contract**
- Add/adjust scenarios verifying user actions are blocked when policy denies mutation/simulation.
- Validate no unintended dispatch-visible side effects while blocked.

4. **Processing/Progress Contract**
- Align assertions with OperationLifecycle-driven critical operations.
- Avoid legacy `UpdateProcessing` assumptions unless explicitly under compatibility tests.

5. **Selector Hardening**
- Replace fragile CSS-only hooks with role/name/data-testid where available.
- Keep a selector fallback strategy documented for portal-based UI elements.

## Execution Plan
1. Static audit and classify each spec: `Aligned` / `Needs Update` / `Needs New Coverage`.
2. Apply updates in small, isolated commits grouped by concern.
3. Run targeted spec subsets per concern.
4. Run full `npm run test:e2e` once targeted subsets pass.
5. Capture failures in matrix and patch deterministically.
6. Re-run full suite until stable pass.

## Verification Matrix
- `tests/e2e/editor.spec.ts`
- `tests/e2e/feature-deep-dive.spec.ts`
- `tests/e2e/upload-link-export-workflow.spec.ts`
- `tests/e2e/rapid-scene-switching.spec.ts`
- `tests/e2e/robustness.spec.ts`
- `tests/e2e/perf-budgets.spec.ts`
- Additional affected suites discovered during audit.

## Acceptance Criteria
- No E2E spec relies on outdated timing/behavior assumptions from pre-T1501..T1506 flows.
- Tooltip-related tests are stable under delayed reveal behavior.
- Clear-links behavior is covered and verified end-to-end against pipeline state.
- Capability/lock gating is validated in E2E.
- Full `npm run test:e2e` completes with pass status in the target environment.
- Flaky tests are either hardened or explicitly documented with root-cause and owner.

## Deliverables
- Updated E2E spec files.
- E2E execution matrix with pass/fail notes and remediation mapping.
- Short residual-risk note for any environment-dependent limitations.
