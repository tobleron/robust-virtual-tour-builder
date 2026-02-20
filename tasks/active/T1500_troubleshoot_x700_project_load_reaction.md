# T1500 - Troubleshoot x700 project-load reaction and lifecycle/progress behavior

## Objective
Simulate loading `artifacts/x700.zip` under realistic conditions, observe frontend/backend behavior, and identify any regressions in operation lifecycle, progress visibility, cancellation, or load completion semantics.

## Hypothesis (Ordered Expected Solutions)
- [x] Project-load operation lifecycle events are emitted, but progress UI selection prioritization masks active load state when concurrent ambient operations start.
- [x] Chunked import path (`init/status/chunk/complete`) succeeds but UI phase mapping is inconsistent, causing perceived stalls or delayed completion signaling.
- [x] Operation correlation headers are present for some calls but missing in one or more import/export/save boundaries, reducing traceability and leading to misleading logs.
- [x] Thumbnail ambient generation overlaps project-load completion and causes user confusion even though functional load succeeds.
- [ ] Cancellation pathways are wired but not reflected consistently in Sidebar processing state under rapid interaction.

## Findings
- Root cause #1 (fixed): Backend CORS allow-list did not include `x-correlation-id`, causing browser-side `Failed to fetch` during project import in hardened request paths.
- Root cause #2 (fixed): Project file serving endpoint did not resolve `thumbnails/` storage path, producing `thumb-*.webp` 404s when those files existed.
- Validation behavior: `x700.zip` does not include thumbnail files; backend validation correctly clears stale `tinyFile` references and frontend ambient generation backfills thumbnails.
- Verification run (headless probe): `loaded=true`, `sceneCount=70`, `sceneOrderCount=70`, `hasSessionId=true`, `failedResponses=0`, `thumb404s=0`, `consoleErrors=0`.

## Activity Log
- [x] Read context docs (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`) and establish troubleshooting scope.
- [x] Reproduce with `artifacts/x700.zip` using deterministic simulation path.
- [x] Capture frontend console + backend logs for import lifecycle and progress transitions.
- [x] Validate operation lifecycle start/progress/complete/fail/cancel edges during run.
- [x] Implement targeted fixes if required.
- [x] Re-run simulation and verify behavior.
- [x] Record final findings and rollback status.

## Code Change Ledger
- [x] `tasks/active/T1500_troubleshoot_x700_project_load_reaction.md` - created troubleshooting scaffold and updated with findings/verification.
- [x] `backend/src/startup.rs` - added CORS allowed header `x-correlation-id` to match frontend authenticated request hardening.
- [x] `backend/src/api/media/serve.rs` - added `thumbnails/` path resolution and fallback logic for project file serving.
- [x] `tests/e2e/x700-load-troubleshoot.spec.ts` - added/iterated deterministic `x700` import probe test and fixed state access via `window.store.getFullState()`.

## Rollback Check
- [x] Confirmed CLEAN for this troubleshooting set (only validated fixes retained).

## Context Handoff
The `x700` import now completes with clean network behavior after CORS and thumbnail-serving fixes. If this task is resumed, focus next on cancellation semantics under rapid scene switches and whether ambient thumbnail generation should be batched/throttled for very large projects. Keep the deterministic probe path (`artifacts/x700.zip`) as the baseline regression check.
