# 1489 - Enterprise Chunked Resumable Project Import (100MB-400MB)

## Purpose
Replace fragile single-request project ZIP import with a chunked resumable protocol that remains reliable under strict rate limiting and high-latency networks.

## Why This Task Exists
Large project files (100MB-400MB) currently rely on one multipart request to `/api/project/import`, which is brittle for:
- transient network instability,
- 429 cooldown windows,
- browser/proxy/request size constraints,
- interrupted uploads that must restart from byte 0.

## Scope
- Backend chunked upload session lifecycle (`init`, `chunk`, `status`, `complete`, `abort`).
- Frontend chunk orchestrator integrated into existing `ProjectSystem` import flow.
- Resumability based on backend-confirmed chunk indexes.
- Backpressure-friendly pacing to cooperate with current retry and queue systems.
- Regression coverage and verification for import reliability.

## Out of Scope
- Replacing media image upload pipeline.
- Changing save/export flow.
- Multi-node distributed upload coordination.

## API Contract (New)
### 1. `POST /api/project/import/init`
Request JSON:
- `filename: string`
- `sizeBytes: int`
- `chunkSizeBytes: option<int>`

Response JSON:
- `uploadId: string`
- `chunkSizeBytes: int`
- `totalChunks: int`
- `expiresAtEpochMs: int`

### 2. `POST /api/project/import/chunk`
Request multipart or binary body:
- `uploadId`
- `chunkIndex`
- `chunkByteLength`
- binary chunk

Response JSON:
- `accepted: bool`
- `nextExpectedChunk: int`
- `receivedCount: int`

### 3. `GET /api/project/import/status/{uploadId}`
Response JSON:
- `receivedChunks: array<int>` or compact range model
- `nextExpectedChunk: int`
- `expiresAtEpochMs: int`

### 4. `POST /api/project/import/complete`
Request JSON:
- `uploadId: string`
- `filename: string`
- `sizeBytes: int`
- `totalChunks: int`

Response JSON:
- existing import response contract (`sessionId`, `projectData`) from current `/api/project/import`.

### 5. `POST /api/project/import/abort`
Request JSON:
- `uploadId: string`

Response JSON:
- `aborted: bool`

## Backend Implementation Plan
- Add upload-session store with TTL cleanup (filesystem-backed temp dir + metadata manifest).
- Validate all IDs/indices/declared sizes and reject out-of-range or inconsistent chunks.
- Enforce per-chunk max size (default 5MB, hard cap 10MB).
- On `complete`, verify all chunks present, reassemble deterministic byte stream, then call existing project import logic.
- Keep legacy `/api/project/import` temporarily for compatibility, but return explicit guidance on oversized payload failure.
- Add structured tracing fields: `upload_id`, `chunk_index`, `chunk_count`, `bytes_received`, `elapsed_ms`.

## Frontend Implementation Plan
- Add `FileSlicer` utility to generate deterministic chunks.
- Add new `ProjectApi` methods for chunk init/chunk/status/complete/abort.
- Update `ProjectSystem.loadProjectZip` to use chunk flow while preserving current progress callbacks.
- Use retry with jitter for chunk upload; obey rate-limit backoff and abort signal.
- On retry or reload, query `status` and continue from missing chunk(s) only.

## Reliability and Security Requirements
- Upload sessions expire and are garbage-collected.
- Reject mismatched metadata (size/chunk count/filename anomalies).
- Prevent path traversal and unsafe filenames in all temp/project operations.
- Explicitly report whether failure is quota, rate limit, validation, or corruption.

## Testing Requirements
- Backend:
  - Unit tests for session validation, missing chunk detection, and reassembly integrity.
  - API tests for out-of-order chunks, duplicate chunks, invalid indices, and expiry.
- Frontend (Vitest):
  - Chunk orchestration success path.
  - Resume from partial chunk completion.
  - Abort behavior cleanup.
  - 429/backoff behavior does not restart already accepted chunks.
- E2E:
  - Import of large synthetic project through chunk endpoints.
  - Recovery after simulated interruption.

## Acceptance Criteria
- 100MB-400MB project imports complete via chunked flow without requiring relaxed global limits.
- Interrupted upload resumes from server-confirmed state, not from zero.
- `npm run build` passes.
- `npm run test:frontend` passes with updated tests.
- `cd backend && cargo test` passes for touched backend modules.

## Verification Commands
- `npm run res:build`
- `npm run test:frontend`
- `cd backend && cargo test`
- `npm run build`

## Risks
- Temporary disk growth from abandoned chunk sessions.
- Edge-case race conditions on concurrent chunk posts.
- UX confusion if progress and backend status diverge.

## Mitigations
- TTL cleanup + startup cleanup sweep.
- Per-upload lock or atomic append strategy.
- Progress driven by backend-confirmed chunk acknowledgements.
