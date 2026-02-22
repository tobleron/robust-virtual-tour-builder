# 1513 - Teaser Simulation Headless Revamp

## Objective
Revamp teaser generation so it uses backend headless simulation capture (WebM-first), keeps builder UI stable during processing, and aligns simulation transition behavior with export-style crossfades.

## Scope
- Add teaser format selection dialog from Teaser button:
  - `WebM` enabled and default.
  - `MP4` visible but disabled (coming later).
- Route teaser generation through backend headless path for WebM.
- Show progress lifecycle in global progress bar only (uploading/processing/finalizing).
- Ensure teaser motion follows simulation journey behavior but **without intro pan to waypoint start**.
- Update simulation intro-pan behavior in builder:
  - No intro pan on project load.
  - Intro pan only after user starts simulation.
  - Intro pan only on the first scene of a simulation run.
  - Subsequent scenes rely on normal crossfade transition.

## Implementation Notes
- Frontend modules:
  - `src/components/Sidebar/SidebarActions.res`
  - `src/components/Sidebar.res`
  - `src/systems/TeaserLogic.res`
  - `src/systems/ServerTeaser.res`
  - `src/components/ViewerManager/ViewerManagerIntro.res`
- Backend modules:
  - `backend/src/api/media/video.rs`
  - `backend/src/api/media/video_logic.rs`
- Keep existing export transition behavior untouched.
- Keep MP4 transcode path available in backend code but not exposed in new dialog flow.

## Validation
- `npm run res:build`
- `cd backend && cargo test -q` (or at least `cargo check`)
- Manual:
  - Teaser dialog appears with WebM selected and MP4 disabled.
  - Starting teaser keeps viewport stable while progress bar updates.
  - Result downloads as `.webm`.
  - Simulation no longer auto-pans on initial project load.
  - Simulation pans to arrow start only once (first scene), later scenes crossfade only.
