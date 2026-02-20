# Task 1504: Race Reliability Certification Sweep + T1495 Closure Criteria

## Objective
Run a determinism-focused validation sweep after Tasks `1501`-`1503`, close remaining race-risk gaps, and produce evidence-based closure recommendation for `T1495`.

## Hard Dependency Gate
- Requires Tasks `1501`, `1502`, and `1503` complete first.
- This is the final task in the sequence.

## Prerequisite Guardrail
- `1504` must explicitly verify that `1503` lock policy keeps navigation interruptible (rapid scene re-targeting must still cancel/replace in-flight navigation).

## Problem Statement
Architecture has significantly improved race handling, but closure of `T1495` requires explicit stress evidence and residual risk accounting, not assumptions.

## Why This Matters
- Converts “likely fixed” into measured reliability.
- Prevents regressions when async flows evolve.
- Provides merge-ready confidence gates for future PR reviews.

## In Scope
- `tasks/active/T1495_frontend_race_condition_audit.md` (status updates/checklist completion)
- `src/core/Capability.res` policy contract verification (no drift from task `1503`)
- Existing e2e stress suites and perf budgets
- Targeted new tests/instrumentation where evidence is missing
- Diagnostics/log correlation for stale callback rejection

## Out of Scope
- New architecture redesign unrelated to race/determinism closure.

## Required Implementation
1. Build a deterministic verification matrix mapped directly to `T1495` success criteria.
2. Add capability-policy drift checks so lock behavior remains centralized and deterministic.
3. Add missing instrumentation to measure stale callback rejection and operation ordering.
4. Execute repeated stress loops (CPU throttle + rapid interaction + ambient contention).
5. Document residual risk explicitly (none/small/known limits) with mitigation notes.
6. Update `T1495` with objective evidence and closure recommendation.

## Mandatory Validation Runs
- 100-run rapid scene interaction stress loop.
- CPU throttle (6x) + slow network simulation for load/upload/export.
- Ambient thumbnail generation contention during navigation.
- Cancellation and interruption scenarios with operation lifecycle evidence.
- Replayability check: same scenario sequence should produce stable ordering.
- Lock-policy regression check: controls disabled only when capability matrix requires it, and no accidental hard-lock during ordinary navigation.
- Hard-lock overlay verification: full-screen lock appears only for integrity-critical states (project load/export/initialization), not ordinary navigation.

## Execution Plan
1. Prepare test matrix linked to each `T1495` success criterion.
2. Extend/add tests where current coverage is insufficient.
3. Run matrix and collect metrics/log traces.
4. Fix any uncovered race edge cases.
5. Update `T1495` with final evidence and explicit go/no-go recommendation.

## Acceptance Criteria
- [ ] All `T1495` success criteria have mapped, executed evidence.
- [ ] No reproducible stale-callback mutation after ownership change in stress runs.
- [ ] No deterministic ordering regressions under contention scenarios.
- [ ] Residual risks are documented with concrete guardrails.
- [ ] Capability matrix behavior remains centralized in `Capability.Policy` with no ad hoc lock regressions.
- [ ] `T1495` receives evidence-backed closure recommendation.

## Handoff Evidence Required
- Stress run report with pass/fail counts and environment settings.
- Metrics snapshot (latency, long-task count, ordering anomalies).
- Log excerpts proving stale-task rejection and correct terminal states.
- Updated `T1495` checklist with completion notes.
