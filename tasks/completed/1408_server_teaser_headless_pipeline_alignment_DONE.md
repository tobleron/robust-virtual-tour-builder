# 1408: Architecture/Performance - Server Teaser Headless Pipeline Alignment

## Objective
Stabilize headless teaser generation by removing hardcoded runtime assumptions and mismatched resource paths.

## Context
`backend/src/api/media/video_logic.rs` currently:
- navigates headless browser to hardcoded `http://localhost:8080`.
- injects a script that fetches `/api/session/{sessionId}/{sceneName}` resources.
- relies on ad-hoc in-page globals and polling.
These assumptions are brittle across environments and can fail silently under deployment differences.

## Suggested Action Plan
- [ ] Replace hardcoded base URL with configured server origin.
- [ ] Align resource hydration endpoint with actual authenticated project file route.
- [ ] Replace opaque script injection flow with a typed, minimal headless control protocol.
- [ ] Add explicit failure telemetry for hydration stage, frame capture stage, and ffmpeg stage.
- [ ] Add timeout/cleanup guarantees for all child process paths.

## Verification
- [ ] Integration test generates teaser successfully in non-localhost environment.
- [ ] Failure cases return actionable structured errors (no generic timeout-only outcomes).
- [ ] `cd backend && cargo test` includes teaser pipeline coverage for path/config validation.
