# Master Task 1592: Streaming Export with Chunked Transfer & Resume Capability

## Objective
Deliver chunked export upload with resume/checksum integrity, bounded browser memory usage, and safe fallback to the current single-request path for small tours.

## Orchestration Model
This is a master task split into four sequential child tasks:
- `1596_export_streaming_phase_a_backend_session_endpoints.md`
- `1597_export_streaming_phase_b_frontend_chunk_sender_resume_checksum.md`
- `1598_export_streaming_phase_c_exporter_integration_and_small_tour_fallback.md`
- `1599_export_streaming_phase_d_progress_observability_e2e_and_regression_gate.md`

Each phase has independent acceptance criteria and mandatory no-regression checks.

## Constraints
- Do not remove or break the existing `/api/project/create-tour-package` flow until Phase C fallback integration is complete.
- Keep auth/rate-limit middleware parity with existing project endpoints.
- Ensure resumed uploads are scoped to `user_id` and session ownership.
- Keep protocol deterministic and explicit (no hidden implicit server-side assumptions).

## Global Success Criteria
- [x] Large exports do not require full in-memory FormData assembly on frontend
- [x] Resume works after interrupted upload
- [x] Chunk checksum verification is enforced server-side
- [x] Operation lifecycle reflects chunk-level progress
- [x] Small tours continue using existing single-request path (<10 scenes)
- [x] E2E and unit checks show no regressions in existing export/import flows

## Execution Order
1. Complete Phase A (backend protocol).
2. Complete Phase B (frontend sender and resume/checksum contract).
3. Complete Phase C (runtime selection + fallback).
4. Complete Phase D (observability, tests, regression gate).

## Completion Rule
Master task can be archived only when all child tasks are completed and regression checks pass.
