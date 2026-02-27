# T1600 — Troubleshoot E2E Export Disabled Mismatch

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [x] E2E test clicks Export before import pipeline finishes scene state hydration (button still legitimately disabled).
  - [x] E2E fixture load path differs from manual flow (`layan_complete_tour.zip` handling), causing zero valid exportable scenes.
  - [x] Post-import blocking state/modal is not dismissed in E2E, leaving app in blocking mode.
  - [x] Reset helper leaves stale lock/operation lifecycle state that keeps export unavailable.
  - [x] Export guard regression in sidebar logic, but masked in manual testing due to slower user pacing.

- [ ] **Activity Log**
  - [x] Capture exact E2E failing assertion and export button disabled reasons.
  - [x] Trace sidebar export eligibility guards against runtime state right after import.
  - [x] Compare manual flow timing vs E2E timing and modal interactions.
  - [x] Apply minimal test-only fix (or helper synchronization) if app logic is correct.
  - [x] Re-run targeted E2E and confirm pass.

- [ ] **Code Change Ledger**
  - [x] `tests/e2e/e2e-helpers.ts`: Added `waitForSidebarInteractive(page)` that repeatedly dismisses import summary actions (`Start Building` / `Close`), waits for lock overlay clearance, and exits only when sidebar actions are enabled.
  - [x] `tests/e2e/import-export-edge-cases.spec.ts`: Added helper usage after project import and explicit `toBeEnabled` guard on Export button to avoid race with blocked app mode.

- [ ] **Rollback Check**
  - [x] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [x] E2E export-disable mismatch investigated with state guard traces.
  - [x] Root cause identified as test-precondition mismatch or true logic bug.
  - [x] Applied minimal safe fix and validated with focused E2E run.
