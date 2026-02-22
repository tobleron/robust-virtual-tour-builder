# T1522 Troubleshoot Batch Upload Regression (Desktop JPEG Folder)

- Assignee: Codex
- Objective: Restore reliable full-folder batch upload behavior for large desktop JPEG sets (e.g., `X3_Layan_1007_Villa`) without journal deadlocks or broken resume loops.
- Scope: Frontend upload orchestration, backend multipart/chunk ingestion, operation journal recovery semantics.

## Hypothesis (Ordered Expected Solutions)
- [ ] H1: Upload chunk/batch concurrency changed and now exceeds backend throughput, causing request timeouts and partial-journal stuck states.
- [ ] H2: Journal operation completion/failure paths are missing for one or more error branches, causing endless resume prompts after restart.
- [ ] H3: Resume logic replays stale/invalid batch metadata and repeatedly re-enters failed states.
- [ ] H4: Backend upload endpoint limits (payload, timeout, or multipart parsing assumptions) reject mixed/large folders under current frontend pacing.

## Activity Log
- [x] Capture current upload configuration (batch size, concurrency, retry policy, timeout).
- [x] Trace upload lifecycle start→progress→complete/fail in frontend systems.
- [x] Inspect operation journal status transitions for upload operations.
- [x] Validate backend API behavior and error mapping to frontend notifications.
- [x] Apply minimal fix for the first confirmed root cause.
- [ ] Verify with realistic folder-level scenario and ensure resume behavior is correct.

## Code Change Ledger
- [x] `src/systems/Upload/UploadScanner.res`: Added size-aware `pickUploadConcurrency` to downshift processing concurrency for heavy folders / very large files; replaced hardcoded `6`.
- [x] `src/utils/Constants.res`: Added upload concurrency guardrail constants used by scanner policy.
- [x] Compile check: `npm run -s res:build` passed.
- [x] `src/systems/Api/AuthenticatedClientBase.res`: Added endpoint-aware timeout budget (180s) for heavy media/project import routes.
- [x] `src/systems/Api/AuthenticatedClientRequest.res`: Updated timeout resolver call to URL-aware signature.
- [x] `src/systems/Upload/UploadItemProcessor.res`: Added per-item processing timeout guard to prevent worker slot deadlock.
- [x] Direct API stress probe (curl, 2-way parallel) against `/api/media/process-full` on `X3_Layan_1007_Villa`: slow but responsive; observed requests returned `200` with large per-image latency.
- [x] E2E sanity run `tests/e2e/ingestion.spec.ts`: `5 passed`, `1 failed` (chromium expects `Start Building` button visibility in a path that no longer consistently presents it).

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Pending.
