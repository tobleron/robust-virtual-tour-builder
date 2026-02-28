# T1627: Resolve Critical Technical Debt & Telemetry Audit

## Assignee
Gemini CLI / Jules

## Capacity Class
`Capacity B` (Implementation + E2E Verification)

## Objective
Address critical technical debt identified in the v5.0 audit, specifically focusing on telemetry reliability, stale state fields, and e2e test robustness.

## Boundary
- `src/systems/Simulation.res`
- `src/core/Types.res`
- `tests/e2e/robustness.spec.ts`
- `src/utils/Logger.res` (Audit only)

## No-Touch Zones
- Backend code (unless specifically required for teaser rendering fixes)
- Project saving/loading logic (outside of verification)

## Owned Interfaces
- Internal telemetry payloads in Simulation and Teaser systems.

## Independent Verification
- Successful execution of `tests/e2e/robustness.spec.ts` without `fixme` on critical paths.
- Audit report confirming no literal "TODO" strings remain in active telemetry paths.

## Depends On
None.

---

## 🛠️ Implementation Steps

### 1. Telemetry Audit & Fixes (Priority 1)
- [ ] **Audit Simulation Telemetry**: Scan `src/systems/Simulation.res` and related logic for any placeholder error strings.
- [ ] **Fix Placeholder Errors**: Replace any `"error": "TODO"` or similar placeholders with structured error messages (e.g., using `Logger.extractMessage`).
- [ ] **Harden Logger**: (Optional) Add a guard in `Logger.res` or `LoggerLogic.res` to warn if a literal `"TODO"` is passed as a data value in production mode.

### 2. E2E Robustness & Regression Fixes (Priority 1)
- [ ] **Fix Operation Cancellation Test**: Investigate and resolve the `test.fixme('Operation Cancellation')` in `tests/e2e/robustness.spec.ts:285`. Ensure that cancelling a bulk upload or scene load correctly cleans up UI state.
- [ ] **Fix Browser-Specific Button States**: Address the `TODO` on `tests/e2e/robustness.spec.ts:81` regarding button state updates in Firefox/Webkit.

### 3. Stale State Audit
- [ ] **Audit `Types.res`**: Check for any fields marked with deprecation comments or mentioned in `AUDIT_REPORT.md` (e.g., `scenes`, `deletedSceneIds`) that are no longer referenced in the main codebase.
- [ ] **Cleanup Stale Fields**: Remove truly unused fields to simplify the core state type.

---

## 🧪 Verification Plan

### Automated Tests
- [ ] Run `npx playwright test tests/e2e/robustness.spec.ts` and ensure all tests pass.
- [ ] Run `npm test` to ensure no regressions in core reducer logic.

### Manual Verification
- [ ] Trigger a simulation error (e.g., by disconnecting network) and verify the telemetry sent to the `Logger` (via `scripts/tail-diagnostics.sh`) contains a meaningful error message, not a placeholder.
