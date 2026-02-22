# Task 1520: Backend MP4 Readiness Scaffold Using Motion Manifest

## Assignee
Jules (AI Agent)

## Capacity Class
B

## Objective
Prepare backend infrastructure for future deterministic MP4 rendering by adding a stable render-engine contract and validated motion-manifest ingestion, without enabling MP4 generation yet.

## Depends On
1517

## Boundary (Allowed Areas)
- `backend/src/api/media/video.rs`
- `backend/src/api/media/video_logic.rs`
- `backend/src/api/media/video_logic_support.rs`
- `backend/src/services/media/` (new teaser render scaffolding module if needed)
- `src/systems/ServerTeaser.res` (request contract fields only)
- `src/core/JsonParsers*.res` (request schema updates only)

## Owned Interfaces
- Teaser request schema fields:
  - `render_engine` (`frontend_webm` | `backend_mp4`)
  - `motion_spec` (`motion-spec-v1`)
- Backend request validation and structured error response contract
- Future backend renderer entrypoint abstraction

## No-Touch Zones
- Frontend deterministic renderer implementation internals
- Simulation/navigation runtime logic
- Export packaging and project ZIP architecture

## Scope
1. Add explicit `render_engine` contract in teaser request.
2. Parse and validate `motion-spec-v1` payload on backend with structured errors.
3. Introduce backend render-engine abstraction:
   - frontend path remains active behavior,
   - backend MP4 path returns structured `NotImplemented` response for now.
4. Add telemetry markers for requested engine and validation outcomes.
5. Add unit tests for request parsing and future-engine routing behavior.

## Out of Scope
1. Actual backend MP4 video rendering implementation.
2. FFmpeg pipeline redesign.
3. Any change to current deterministic frontend WebM output path.

## Acceptance Criteria
- [ ] Backend accepts and validates deterministic teaser manifest contract.
- [ ] `render_engine=frontend_webm` preserves current behavior.
- [ ] `render_engine=backend_mp4` returns deterministic structured not-ready response (not generic failure).
- [ ] Parser/routing unit tests cover valid and invalid contract variants.
- [ ] `cd backend && cargo check` passes.
- [ ] `cd backend && cargo test` passes for touched modules.

## Verification Evidence Required
1. Request/response examples for both `frontend_webm` and `backend_mp4`.
2. Test output summary for parser/route behavior.
3. Telemetry sample showing engine routing markers.
