# T1499 - Troubleshoot project-load thumbnail 404 and console error flood

## Objective
Eliminate repeated `404 (Not Found)` requests for `thumb-*.webp` during project load so scene thumbnails resolve correctly without console error flooding.

## Hypothesis (Ordered Expected Solutions)
- [x] Thumbnail URL references in loaded project metadata point to files that are not yet generated or no longer exist; add guarded fallback and deferred URL promotion only after file availability is confirmed.
- [ ] Backend project file-serving endpoint resolves only persisted files, while frontend patches thumbnail URL names optimistically; align naming/serving contract.
- [ ] Thumbnail generation sequence is racing with sidebar rendering; temporary unresolved URLs are rendered before patch completion.
- [ ] Thumbnail patch flow is repeatedly rewriting scene thumbnails with unstable IDs/paths, causing stale URL retries.

## Activity Log
- [x] Read task and architecture context (`TASKS.md`, `MAP.md`, `DATA_FLOW.md`, workflow docs).
- [x] Trace frontend thumbnail source selection on project load.
- [x] Trace thumbnail generation and patch dispatch lifecycle.
- [x] Trace backend `/api/project/:id/file/:filename` resolution for thumbnail files.
- [x] Implement fix and add/adjust tests where practical.
- [x] Verify with build/tests and targeted runtime checks.

## Code Change Ledger
- [x] `tasks/active/T1499_troubleshoot_project_load_thumbnail_404.md` - created troubleshooting scaffold with hypothesis, activity log, rollback, and handoff sections.
- [x] `backend/src/services/project/validate.rs` - added filename extraction helpers and archive presence checks; now clears missing `tinyFile` references during validation to prevent stale thumbnail URL hydration.
- [x] `backend/src/services/project/validate.rs` - unified filename parsing for scene file refs and expanded used-file collection to include `file`, `tinyFile`, and `originalFile`.
- [x] `backend/src/services/project/mod.rs` - added tests for clearing missing `tinyFile` references and preserving valid `tinyFile` references.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The console evidence indicates bulk thumbnail URLs are requested before corresponding files are guaranteed to exist, causing widespread 404s. The likely issue is a contract/race mismatch between frontend thumbnail URL promotion and backend file availability during project load hydration. Next session should continue from `ThumbnailProjectSystem` and project file-serving pipeline traces, validate the exact mismatch, and keep only a minimal deterministic fix.
