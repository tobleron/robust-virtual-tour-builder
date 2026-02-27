# Task 1596: Export Streaming Phase A - Backend Session Endpoints

## Parent
Master task: `1592_export_streaming_multipart.md`

## Objective
Implement backend export-upload session endpoints (`init/chunk/status/complete/abort`) with durable chunk assembly, ownership checks, and checksum validation.

## Scope
- Backend only.
- No frontend protocol switching yet.

## Step-by-Step Implementation
1. Create export upload session manager under `backend/src/services/project/`:
   - Add dedicated module(s) analogous to import manager architecture.
   - Track session metadata: `upload_id`, `user_id`, `filename`, `size_bytes`, `chunk_size_bytes`, `total_chunks`, `received_chunks`, `expires_at`.
2. Add chunk persistence model:
   - Write chunks to per-session temp directory.
   - Enforce min/max chunk size bounds.
   - Reject out-of-range chunk indices.
3. Add checksum validation:
   - Require SHA-256 (hex) per chunk in chunk request payload.
   - Compute server-side hash and reject mismatch.
4. Add API handlers in `backend/src/api/project.rs` (or `project_export.rs` if split):
   - `POST /api/project/export/init`
   - `POST /api/project/export/chunk`
   - `GET /api/project/export/status/{upload_id}`
   - `POST /api/project/export/complete`
   - `POST /api/project/export/abort`
5. Wire routes in `backend/src/api/mod.rs` with same auth and rate-limit style as import endpoints.
6. On `complete`, assemble chunk stream into temp package payload file and invoke existing packaging flow (or staging handoff) without changing legacy endpoint behavior.
7. Implement cleanup:
   - Expired sessions
   - Abort path
   - Post-complete cleanup

## Acceptance Criteria
- [ ] All export session endpoints available and authenticated
- [ ] Chunk checksum mismatch returns clear error
- [ ] Status endpoint reports received/missing chunks accurately
- [ ] Complete rejects incomplete chunk sets
- [ ] Abort removes server-side temp files

## Verification (Mandatory)
1. Backend compile/tests:
   - `cd backend && cargo test`
2. Add/execute backend tests for:
   - session init
   - out-of-order chunk receipt
   - checksum mismatch
   - complete success path
   - abort cleanup
3. No-regression checks:
   - Existing `/api/project/create-tour-package` remains functional
   - Existing import chunk endpoints still pass tests

