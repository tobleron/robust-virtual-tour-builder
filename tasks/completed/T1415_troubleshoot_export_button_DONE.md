# T1415 Troubleshoot Export Button

## Objective
Investigate why the Export button is not functioning and document the current intended behavior path (UI trigger → state/action → export pipeline).

## Hypothesis
- [x] Export click is gated by UI/interaction lock state, missing preconditions, or a failing async branch in project/export orchestration.

## Activity Log
- [x] Read architecture/task context docs (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`).
- [x] Trace Export button handler in UI components.
- [x] Trace dispatched action/reducer pathway (if any).
- [x] Trace export orchestration modules and dependencies.
- [x] Identify current app-dictated behavior, preconditions, side effects, and expected outputs.
- [x] Correlate likely failure points with observed non-working button symptom.
- [x] Backend 500 root cause identified: invalid scene payload bytes when URL-backed scene assets were converted to empty placeholder blobs.
- [x] Export UX hard-failure mitigated: export errors no longer escalate to global critical mode.
- [x] Dev backend instability root cause identified: `cargo watch` restarts on runtime file churn during export (`backend/temp`/logs), causing `ERR_EMPTY_RESPONSE`.
- [x] Dev runner hardened: backend watch scope restricted to source/config inputs.
- [x] Standalone export runtime issue identified: exported tours fail under `file://` because bundled Pannellum only accepts XHR status `200`.
- [x] Standalone compatibility patch applied in bundled library: treat `file://` XHR status `0` + blob response as successful panorama load.
- [x] Standalone compatibility hardened with fallback: if `file://` XHR has no blob response, load panorama directly via image source.
- [x] Dual-package export implemented in backend ZIP builder: emits both `web_only/` and `standalone/` folders in a single export.
- [x] Standalone folder now embeds panorama assets as data URIs in generated resolution HTML files to avoid `file://` XHR/CORS restrictions.
- [x] Verified backend compilation after packaging changes (`cargo check`).

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
This troubleshooting task captures the current export-button contract before changing behavior. The trace should establish exactly which module receives the click and what preconditions are required for export to proceed. If context window fills, continue from this task by validating each hop in the export flow and marking checkboxes as evidence is collected.
