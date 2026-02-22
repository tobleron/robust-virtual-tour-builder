# Task 1515 - Teaser CDP Migration Validation Notes

## Scope Completed
This update finalizes the backend CDP teaser capture path and closes the main engineering gaps for Task 1515:

1. CDP screencast is primary capture transport.
2. Polling screenshot path remains fallback.
3. Viewer-stage confinement is enforced for CDP by:
   - hiding sidebar and non-teaser UI during capture mode,
   - requesting screencast frames at resolved `#viewer-stage` dimensions.
4. Teaser frame pacing is now event-driven with timestamp-aware emission (instead of pure 60 Hz polling loop).
5. Structured telemetry now includes duplicate ratio, dropped frames, late frames, and duration drift.
6. Added unit-level tests for motion-profile parsing and teaser format parsing.

## Files Changed
- `backend/src/api/media/video_logic.rs`
- `backend/src/api/media/video.rs`

## Validation Executed
1. `cd backend && cargo check`
2. `cd backend && cargo test --lib video::tests -- --nocapture`
3. `cd backend && cargo test --lib teaser_output_format_parses_mp4_and_defaults_to_webm -- --nocapture`
4. `npm run build` (passes when no concurrent ReScript watch process is holding the build lock)

Backend checks/tests passed in this session.

## Runtime Telemetry to Inspect
`TEASER_CAPTURE_STATS` now reports:
- `capture_mode` (`cdp` or `polling`)
- `duration_s`
- `encoded_duration_s`
- `duration_drift_s`
- `emitted_frames`
- `captured_frames`
- `duplicated_frames`
- `dropped_frames`
- `late_frames`
- `duplicate_ratio`
- `emitted_fps`
- `captured_fps`

## Expected Quality Targets (Task 1515)
Use these thresholds during manual runs (`x445.zip`, then `x700.zip` subset):

1. `capture_mode` should be `cdp` in normal runs.
2. `captured_fps` should typically stay above ~45 on standard hardware.
3. `duplicate_ratio` should stay below ~0.20 in standard runs.
4. `duration_drift_s` should be within ~5% of simulation timeline.
5. Output should not show sidebar/utility/floor/pipeline overlays; logo should remain visible.

## Fast Manual Test Flow
1. Run app normally (`npm run dev`).
2. Load `x445.zip`.
3. Trigger teaser MP4 generation.
4. Confirm progress bar/cancel behavior in UI.
5. Inspect teaser output visually for:
   - smooth continuous motion,
   - proper crossfades,
   - no stuttery screenshot effect,
   - no non-logo builder overlays.
6. Check backend logs for `TEASER_CAPTURE_STATS`.
7. Repeat with a heavier path subset from `x700.zip`.

## Post-Migration Hardening (T1516)
Follow-up troubleshooting added two guardrails to avoid intermittent `500` failures:

1. First-frame grace:
   - CDP capture now waits for first frame readiness before interpreting autopilot inactive state.
   - Prevents early empty-stream termination that can make FFmpeg fail.
2. Resilient fallback:
   - Any CDP runtime failure now degrades to polling capture when time budget remains.
   - If CDP already emitted frames, fallback continues the same output stream with `capture_mode` marked as `cdp+polling`.

Additional hardening:
3. Session hydration reliability:
   - Headless hydration now prefers request-scoped session id and tries multiple URL candidates.
   - Prevents stale ZIP `project.sessionId` from breaking file hydration.
4. MP4 encoder safety:
   - Capture viewport is normalized to even dimensions.
   - MP4 FFmpeg path applies an even-dimension scale filter (`scale=trunc(iw/2)*2:trunc(ih/2)*2`) to avoid x264 odd-height failures.
5. Dev auth fallback:
   - In debug builds, missing request/env auth token falls back to `dev-token` for internal hydration routes.

## Operational Tuning Knobs
Current constants in `backend/src/api/media/video_logic.rs`:
- `TEASER_OUTPUT_FPS`
- `TEASER_CAPTURE_JPEG_QUALITY`
- `CDP_FRAME_TIMEOUT_MS`
- `CDP_FRAME_STALL_MS`
- `CDP_LATE_FRAME_FACTOR`

If runtime still shows stutter on specific hardware, tune in this order:
1. Lower `TEASER_CAPTURE_JPEG_QUALITY` modestly.
2. Increase `CDP_FRAME_STALL_MS` slightly.
3. Re-run and compare `captured_fps`, `duplicate_ratio`, `duration_drift_s`.
