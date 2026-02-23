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
- [x] Implement byte-budgeted upload scaling in processing scheduler.
- [ ] Verify with realistic folder-level scenario and ensure resume behavior is correct.

## Code Change Ledger
- [x] `src/systems/Upload/UploadScanner.res`: Added size-aware `pickUploadConcurrency` to downshift processing concurrency for heavy folders / very large files; replaced hardcoded `6`.
- [x] `src/utils/Constants.res`: Added upload concurrency guardrail constants used by scanner policy.
- [x] Compile check: `npm run -s res:build` passed.
- [x] `src/systems/Api/AuthenticatedClientBase.res`: Added endpoint-aware timeout budget (180s) for heavy media/project import routes.
- [x] `src/systems/Api/AuthenticatedClientRequest.res`: Updated timeout resolver call to URL-aware signature.
- [x] `src/systems/Api/AuthenticatedClientRequest.res`: Stopped treating HTTP `429` as circuit-breaker failure (uses Retry-After backoff without opening breaker).
- [x] `src/systems/Api/AuthenticatedClient.res`: Disabled retries for `"Circuit breaker is open"` to prevent retry storms.
- [x] `src/systems/Upload/UploadItemProcessor.res`: Added per-item processing timeout guard to prevent worker slot deadlock.
- [x] `src/systems/Api/MediaApi.res`: Reduced `/api/media/process-full` retry amplification (single controlled retry with jittered backoff).
- [x] `src/components/Sidebar/SidebarLogicHandler.res`: Fixed completion semantics; all-failed batches now dispatch error instead of false success summary.
- [x] `src/utils/AsyncQueue.res`: Added `executeWeighted` queue mode with max-concurrency + max-in-flight-weight enforcement and weighted progress reporting.
- [x] `src/systems/Upload/UploadFinalizer.res`: Switched upload processing chain from `AsyncQueue.execute` to `AsyncQueue.executeWeighted` with per-file MB weights.
- [x] `src/utils/Constants.res`: Added upload in-flight budget constants (`uploadInFlightBudgetMbDefault`, `uploadInFlightBudgetMbHeavy`).
- [x] `src/utils/LoggerTelemetry.res`: Fixed telemetry transport to treat HTTP status codes correctly (including `429`), parse `Retry-After`, and suspend telemetry emission instead of flooding backend during throttling windows.
- [x] Compile check after telemetry 429/backoff hardening: `npm run -s res:build` passed.
- [x] `src/systems/Api/MediaApi.res`: Added endpoint-specific pacing gate for `/api/media/process-full` (serialized slot reservation + minimum spacing + rate-limit-aware backoff extension).
- [x] `src/systems/Upload/UploadScanner.res`: For heavy folders/very-large files, downshifted upload worker concurrency from `2` to `1` to avoid backend rate-limit storms.
- [x] Compile check after media pacing + heavy-folder serialization: `npm run -s res:build` passed.
- [x] `src/systems/Upload/UploadItemProcessor.res`: Added per-file rate-limit recovery (`RateLimited: N`) with `Retry-After` wait and up to 2 local retries before marking file failed.
- [x] Verification note: one-shot build command currently blocked by active ReScript watcher PID `44058`; change is intended for immediate hot-reload in current dev session.
- [x] `src/utils/Constants.res`: Changed telemetry defaults so development builds do NOT auto-enable telemetry transport or diagnostic mode unless explicitly requested by env.
- [x] `src/utils/LoggerTelemetry.res`: On telemetry suspension, drop queued telemetry payloads to avoid replay storms after 429 windows.
- [x] Verification note: one-shot build command currently blocked by active ReScript watcher PID `45230`; hot-reload path should apply changes in active dev session.
- [x] `backend/src/middleware/rate_limiter.rs`: Added dedicated limiter bucket `media_heavy`.
- [x] `backend/src/startup.rs`: Added production defaults for `media_heavy` limiter class.
- [x] `backend/src/api/mod.rs`: Split `/api/media` endpoint limiter wiring so `/process-full` uses dedicated `media_heavy` governor while other media routes remain on `write`.
- [x] Backend compile check after limiter split: `cargo check` passed.
- [x] `src/utils/Constants.res`: Added adaptive pacing constants for `/api/media/process-full` autotuning (bounds, step sizes, EMA/latency thresholds).
- [x] `src/systems/Api/MediaApi.res`: Implemented throughput autotuning loop for `process-full` pacing (dynamic spacing, EMA latency feedback, success-window step-down, and rate-limit/retry step-up logic).
- [x] Compile check after throughput autotuning integration: `npm run -s res:build` passed.
- [x] Direct API stress probe (curl, 2-way parallel) against `/api/media/process-full` on `X3_Layan_1007_Villa`: slow but responsive; observed requests returned `200` with large per-image latency.
- [x] E2E sanity run `tests/e2e/ingestion.spec.ts`: `5 passed`, `1 failed` (chromium expects `Start Building` button visibility in a path that no longer consistently presents it).
- [x] Compile check after weighted scheduler integration: `npm run -s res:build` passed.
- [x] Compile check after rate-limit and completion-semantics fixes: `npm run -s res:build` passed.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Pending.
