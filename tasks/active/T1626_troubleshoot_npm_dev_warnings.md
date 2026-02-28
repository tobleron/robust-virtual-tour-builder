# T1626 - Troubleshoot npm run dev Warnings

## Objective
Identify all warnings shown during `npm run dev`, classify them as valid-risk vs benign noise, and either fix root causes or safely suppress non-actionable warnings.

## Hypothesis (Ordered Expected Solutions)
- [ ] Highest probability: Node/rsbuild runtime warnings (e.g., `NO_COLOR` vs `FORCE_COLOR`) are benign and should be suppressed at script/config level.
- [ ] Backend/frontend startup warnings indicate environment mismatch (ports, health checks, or optional deps) and need explicit handling rather than suppression.
- [ ] Some warnings are from browser runtime logging and should be gated by environment flags in dev only.

## Activity Log
- [x] Create troubleshooting task.
- [x] Reproduce warnings with `npm run dev`.
- [x] Categorize warnings by source (frontend, backend, playwright/rsbuild/node, app logs).
- [x] Propose per-warning action: fix, keep, or suppress.
- [x] Implement safe suppressions/fixes.
- [x] Verify `npm run dev` warning output is clean/reduced with no behavior regressions.

## Code Change Ledger
- [x] `backend/src/api/media/video_logic.rs`
  - Removed unused compatibility wrapper functions/type aliases that were generating dead-code warnings.
  - Rollback: restore wrappers if legacy call path is intentionally revived.
- [x] `backend/src/api/media/video_logic_runtime.rs`
  - Removed unused runtime wrapper functions/type aliases; retained only functions used by live path.
  - Rollback: restore wrapper exports if external modules/tests need them.
- [x] `backend/src/api/media/video_runtime_impl.rs`
  - Removed now-unused local type aliases/import noise.
  - Rollback: restore aliases/import if future signatures reintroduce direct usage.
- [x] `backend/src/services/project/package.rs`
  - Removed unused local helper wrappers (`infer_mime_from_filename`, `data_uri_for_bytes`) that delegated to `package_utils`.
  - Rollback: restore local wrappers if module-level façade boundary is reintroduced.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Warning Classification
- `npm audit` vulnerabilities during setup: **valid**.
  - Action: keep visible; handle in dedicated dependency maintenance task (`npm audit` + selective upgrades).
- `[HPM] ECONNREFUSED ... /api/health` at frontend startup: **valid transient** while backend is still compiling/booting.
  - Action: keep visible (do not suppress globally), because it signals real backend unavailability if persistent.
- Rust `dead_code` / `unused` warnings in teaser/runtime/package modules: **non-actionable noise** from stale wrappers.
  - Action taken: removed stale wrappers; warnings eliminated with `cargo check --quiet`.
- `port 3000 is in use, using port 3001`: **environmental informational warning**.
  - Action: keep; close previous dev session when stable fixed port is needed.

## Verification
- `cd backend && cargo check --quiet` ✅ (no warnings after cleanup).
- `npm run dev` re-sample confirms warning set reduced; remaining items are valid environment/runtime warnings.

## Context Handoff
User asked to carefully handle all `npm run dev` warnings by distinguishing real warnings from noise.  
If warning is valid, we should keep it and propose/fix root cause.  
If warning is non-actionable noise, we should suppress safely in code/config.
