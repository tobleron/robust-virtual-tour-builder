# 1621 - Comprehensive Operation Lifecycle & Reliability Audit

## Objective
Perform a comprehensive audit of operation lifecycle, cancellation semantics, and scene-related reliability gates to explain recent false-green E2E outcomes and prevent production regressions.

## Audit Targets
- `src/systems/OperationLifecycle.res`
- Teaser/export operation orchestration modules and UI progress wiring
- Navigation/task cancellation precedence during rapid scene switching
- Readiness gates for scene-linked overlays (hotspots, waypoint arrows, labels, floor/visual pipeline state)
- E2E assertions and fixtures that may allow regressions to pass

## Key Questions
- [ ] Why did E2E pass while real usage regressed?
- [ ] Which checks were weakened, bypassed, or over-mocked?
- [ ] Which reliability gates are missing between scene load completion and interactive overlays?
- [ ] Which hardening metrics should be tuned later vs. fixed now?

## Execution Plan
- [ ] Build a behavior matrix: expected vs actual for New/About/hotspot navigation/upload health-check/teaser/export cancel.
- [ ] Trace operation lifecycle subscriptions from producer to sidebar/UI consumers.
- [ ] Audit abort propagation across navigation, teaser, and export async boundaries.
- [ ] Audit scene transition readiness sequencing for linked interactive elements.
- [ ] Review E2E tests for over-permissive waits, mock shortcuts, and missing assertions.
- [ ] Produce prioritized remediation list: P0 reliability, P1 correctness, P2 telemetry/metrics.

## Deliverables
- [ ] Root-cause report (module-level, reproducible steps, concrete evidence).
- [ ] Tight remediation plan with minimal-risk order of implementation.
- [ ] Test hardening delta list (unit + E2E assertions to add/replace).
- [ ] Metrics tuning backlog (deferred, clearly separated from must-fix bugs).

## Acceptance Criteria
- [ ] Each regression maps to a verified technical cause (no speculative-only conclusions).
- [ ] E2E gap analysis includes exact assertions missing or too weak.
- [ ] Remediation plan preserves recent performance/reliability improvements where possible.
- [ ] Findings are actionable and can be executed as follow-up tasks without extra discovery.

## Verification Checklist
- [ ] `npm run build`
- [ ] Targeted unit tests for touched lifecycle/navigation/teaser/export modules
- [ ] Focused E2E reruns for scenarios tied to identified gaps

## Notes
- This is an analysis-and-hardening task; implementation should be split into follow-up tasks if scope exceeds one safe patch.
