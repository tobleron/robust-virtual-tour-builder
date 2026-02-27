# Task 1597: Export Streaming Phase B - Frontend Chunk Sender, Resume, Checksum

## Parent
Master task: `1592_export_streaming_multipart.md`

## Depends On
`1596_export_streaming_phase_a_backend_session_endpoints.md`

## Objective
Implement frontend chunked upload client for export payload with resume and per-chunk SHA-256 checksum.

## Scope
- Frontend uploader/protocol layer only.
- Do not switch main exporter execution path yet.

## Step-by-Step Implementation
1. Add export session client functions in `src/systems/Exporter/ExporterUpload.res`:
   - `initExportSession`
   - `uploadExportChunk`
   - `getExportSessionStatus`
   - `completeExportSession`
   - `abortExportSession`
2. Add chunk payload serializer:
   - Serialize export package payload into bytes/blob source suitable for slicing.
   - Slice into configurable chunk size (default 50MB).
3. Add checksum generation:
   - Compute SHA-256 for each chunk via Web Crypto API.
   - Send checksum with chunk metadata.
4. Add resume logic:
   - On retry or restart, call status endpoint.
   - Skip already acknowledged chunks.
5. Add robust retry behavior:
   - Network/timeouts retry chunk with bounded attempts.
   - Abort on unrecoverable server errors.
6. Keep operation cancellable via `AbortSignal`.

## Acceptance Criteria
- [ ] Frontend can upload chunked payload to new endpoints
- [ ] Resume skips acknowledged chunks
- [ ] Chunk checksum is sent and validated end-to-end
- [ ] Abort signal cancels in-flight upload and calls abort endpoint

## Verification (Mandatory)
1. Frontend compile/tests:
   - `npm run res:build`
   - `npm run test:frontend`
2. Add tests (unit/integration) for:
   - chunk slicing count/ordering
   - checksum generation wiring
   - resume from partial uploaded state
   - abort semantics
3. No-regression checks:
   - Legacy `uploadAndProcessRaw` single-request function still works
   - Existing export tests not using streaming continue passing

