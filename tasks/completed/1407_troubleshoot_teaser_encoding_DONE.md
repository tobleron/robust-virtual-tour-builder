# 1407: Troubleshoot Teaser Video Encoding Failure

## Problem
E2E tests for Teaser Workflow (Task 1323) fail with a 500 Internal Server Error when attempting to transcode recorded WebM chunks to MP4.
The browser log shows: `Backend Error {status: 500, message: Video Encoding Failed}`.
Investigation revealed that `ffmpeg` is missing from the environment, which the backend depends on for video processing.

## Current State
- Autopilot simulation is fully functional and passing.
- Teaser recording completes successfully (WebM chunks are collected).
- Finalization fails because `Sidebar.res` defaults to `mp4` format, triggering a backend call that requires `ffmpeg`.

## Proposed Solution
1. **Environment**: Install `ffmpeg` in the backend environment/container.
2. **Fallback**: Update `Sidebar.res` to use `webm` as the default format if `mp4` encoding is not available or desired for fast previews. WebM can be downloaded directly from the browser without backend transcoding.
3. **Verification**: Once `ffmpeg` is present, re-run `npx playwright test tests/e2e/simulation-teaser.spec.ts -g "teaser"`.

## Technical Details
- Backend code responsible: `backend/src/services/video_encoding.rs` (assumed path based on error).
- Frontend call: `Teaser.startAutoTeaser("fast", false, "mp4", false, ~getState, ~dispatch)` in `src/components/Sidebar.res`.
