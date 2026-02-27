# Task 1598: Export Streaming Phase C - Exporter Integration and Small-Tour Fallback

## Parent
Master task: `1592_export_streaming_multipart.md`

## Depends On
`1597_export_streaming_phase_b_frontend_chunk_sender_resume_checksum.md`

## Objective
Integrate chunked export into `Exporter.res` runtime path, while preserving existing single-request flow for small tours (<10 scenes).

## Scope
- Export orchestration and runtime path selection.
- No major observability redesign yet (Phase D handles deeper telemetry/reporting).

## Step-by-Step Implementation
1. Add strategy selection in `src/systems/Exporter.res`:
   - If export scene count < 10 -> keep legacy single-request upload.
   - Else -> use new chunked upload flow.
2. Ensure both paths share consistent error normalization and cancellation behavior.
3. Preserve existing packaging steps:
   - templates
   - libraries
   - scene processing
4. Ensure chunked path does not materialize giant FormData in memory.
5. Keep download flow unchanged once backend returns final zip blob.

## Acceptance Criteria
- [ ] Small tours (<10 scenes) still use legacy upload path
- [ ] Large tours use chunked path
- [ ] Export cancellation works in both paths
- [ ] Export completion still triggers download with correct naming/version

## Verification (Mandatory)
1. Build + tests:
   - `npm run build`
   - `npm run test:frontend`
2. E2E targeted checks:
   - small tour export success (legacy path)
   - large-ish tour export success (chunked path trigger)
   - cancel export mid-transfer
3. No-regression checks:
   - existing import/load/save/export baseline specs still pass

