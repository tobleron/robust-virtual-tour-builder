# Task 1515: Teaser CDP Screencast Migration and Motion Parity

## Objective
Replace screenshot-poll teaser capture with a Chrome DevTools Protocol screencast pipeline so teaser output is smooth, duration-accurate, and motion-consistent with simulation semantics.

## Problem Statement
Current backend teaser generation captures frames via `Page.captureScreenshot` polling. Even with 60 FPS output pacing, unique rendered frames can be much lower under headless load, creating stutter (duplicate-frame slideshow effect). This task migrates capture to CDP screencast streaming and enforces one canonical motion-spec contract across frontend and backend.

## Scope
1. Migrate backend frame ingestion from screenshot polling to CDP screencast events.
2. Preserve existing teaser UX contract:
   - MP4 generation path remains primary.
   - Builder UI remains hidden during capture except logo.
   - Progress lifecycle remains visible and cancellable.
3. Keep first teaser frame centered on waypoint-start (no intro pan capture).
4. Maintain simulation-equivalent scene progression and crossfade behavior.
5. Add hard telemetry for effective capture FPS, dropped/late frames, duplicate ratio, and duration drift.
6. Add fallback strategy if CDP screencast fails at runtime.

## Out of Scope
1. Building a custom direct panorama renderer.
2. Rewriting simulation navigation algorithm.
3. Replacing FFmpeg stack or export architecture.
4. Full WebM productization (MP4 remains primary output in this task).

## Architecture Decision
Use CDP screencast as the primary capture transport:
- `Page.startScreencast` emits frames from Chrome compositor.
- Backend consumes event stream, ACKs frames, and pipes directly to FFmpeg.
- Motion profile remains explicit payload (`motion_profile`) from frontend to backend.
- Screenshot polling retained as emergency fallback path only.

## Sequential Execution Plan
Every phase must pass its gate before starting the next phase.

### Phase 1: Capture Transport Refactor (CDP)
1. Implement screencast event listener and frame ACK loop.
2. Pipe incoming JPEG screencast frames to FFmpeg stdin without screenshot polling.
3. Keep viewport confinement to `#viewer-stage`.
4. Maintain teaser capture-mode CSS (hide all builder overlays, keep logo only).

Primary files:
- `backend/src/api/media/video_logic.rs`
- `backend/src/api/media/video_logic_support.rs`

Gate:
- Teaser generation works end-to-end with CDP enabled and returns MP4.

### Phase 2: Motion-Spec Contract Hardening
1. Formalize motion profile schema consumed by backend:
   - `skipAutoForward`
   - `startAtWaypoint`
   - `includeIntroPan`
2. Ensure backend-started teaser uses this profile and never hardcodes motion flags.
3. Verify first frame starts centered at waypoint start with no visible intro pan.
4. Verify scene-to-scene transitions match simulation semantics (crossfade + correct arrival framing).

Primary files:
- `src/systems/ServerTeaser.res`
- `src/systems/TeaserLogic.res`
- `backend/src/api/media/video.rs`
- `backend/src/api/media/video_logic_support.rs`

Gate:
- Motion path and sequencing are visually aligned with simulation rules for at least two real projects (`x445.zip`, `x700.zip` sample path subset).

### Phase 3: Timing and Encoder Parity
1. Lock output to 60 FPS timeline for MP4.
2. Ensure frame timestamps and emission preserve wall-clock simulation duration.
3. Eliminate unintended acceleration/compression (video too short) and macro stutter.
4. Ensure no arrows/waypoint overlays are visible in teaser output.

Primary files:
- `backend/src/api/media/video_logic.rs`
- `src/systems/Navigation/NavigationRenderer.res` (if overlay suppression path needs refinement)

Gate:
- Duration drift and smoothness criteria pass acceptance thresholds.

### Phase 4: Telemetry, Resilience, and Fallback
1. Emit structured telemetry per teaser run:
   - capture mode (`cdp` or fallback)
   - duration
   - emitted fps
   - effective unique fps
   - duplicate frame ratio
   - dropped frame count
2. Add runtime fallback:
   - If CDP stream fails to initialize or stalls, switch to screenshot path with warning telemetry.
3. Ensure cancellation (`ESC` / Cancel button) stops CDP and FFmpeg cleanly.

Primary files:
- `backend/src/api/media/video_logic.rs`
- `src/systems/TeaserLogic.res`
- `src/systems/OperationLifecycle.res`

Gate:
- No zombie FFmpeg/headless processes after cancel/fail/success.

### Phase 5: Validation, Testing, and Rollout
1. Add/update unit-level coverage for motion profile parsing and lifecycle edge cases.
2. Add integration test checklist for teaser generation:
   - short project (`x445`)
   - heavy project (subset path of `x700`)
3. Verify no regressions in simulation mode behavior in builder.
4. Document operational tuning knobs and expected telemetry ranges.

Primary files:
- `tests/` relevant suites
- `docs/_pending_integration/` rollout notes and telemetry interpretation

Gate:
- All acceptance criteria met and reproducible.

## Acceptance Criteria
1. Teaser MP4 output is visually smooth (no screenshot-style stutter under normal dev hardware).
2. Output timeline is 60 FPS and motion duration tracks simulation wall-clock behavior.
3. First frame starts at waypoint-start center without intro pan capture.
4. Crossfade transitions and arrival framing are consistent with simulation semantics.
5. Builder overlays (utility/floor/pipeline/hotspot lines/arrows) are not visible in teaser output; logo remains visible.
6. Progress lifecycle remains visible and cancellable through existing app behavior.
7. CDP capture path is primary; fallback path exists and is telemetry-visible.
8. No uncaught backend errors (`500`) for known-good projects in baseline scenarios.

## Quantitative Success Metrics
1. Effective unique capture FPS:
   - median >= 45 FPS on `x445.zip` standard teaser run
   - p95 frame interval <= 40ms
2. Duration drift:
   - teaser duration vs simulation run duration delta <= 5%
3. Duplicate frame ratio:
   - <= 20% on `x445.zip` baseline run
4. Cancel responsiveness:
   - capture stops and resources release within <= 2s after cancel.

## Risks and Mitigations
1. CDP event API instability in crate version:
   - Mitigation: implement robust fallback and explicit telemetry mode markers.
2. Hardware-dependent compositor throughput:
   - Mitigation: JPEG quality/viewport tuning and documented performance knobs.
3. Process leaks on failure:
   - Mitigation: strict teardown ordering and kill-on-drop guards.
4. Motion parity regressions:
   - Mitigation: side-by-side validation checklist against simulation traces.

## Deliverables
1. CDP screencast-based teaser capture implementation.
2. Hardened motion-profile contract and parser.
3. Telemetry instrumentation and fallback mode handling.
4. Validation report in `docs/_pending_integration/` with:
   - measured FPS stats
   - duration drift results
   - known residual limits and follow-up suggestions.
