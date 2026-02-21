# T1514 - Troubleshoot teaser 500 and simulation transition framing

## Hypothesis (Ordered Expected Solutions)
- [x] Backend headless control is loading a page/bundle where `window.startCinematicTeaser` is unavailable or mismatched.
- [x] Backend headless route assumes local root HTML behavior that differs in dev (8080 vs 3000), causing runtime bootstrap failure.
- [x] Scene transition target yaw/pitch selection in simulation path uses non-centered waypoint target.
- [x] Crossfade transition type is not being dispatched for simulation scene switches due to transition payload defaults.

## Activity Log
- [x] Inspect backend teaser route and runtime logs/error handling for exact failure source.
- [x] Reproduce teaser call assumptions from code path and identify stale/dist bootstrap dependency.
- [x] Patch backend headless bootstrap to robustly detect and invoke available global teaser entrypoint.
- [x] Patch simulation transition framing to prioritize centered waypoint start target.
- [x] Reproduce with real artifact `artifacts/x445.zip` and capture concrete backend error body from `/api/media/generate-teaser`.
- [x] Fix teaser auth propagation to headless hydration flow (resolved `401` hydration failures).
- [x] Fix headless URL resolution to honor scene file URLs (`/api/project/.../file/...`) and avoid bad `scene.name` fallback (`404`).
- [x] Fix FFmpeg binary resolution to prefer healthy system ffmpeg over stale local bundled binary with missing dylibs.
- [x] Fix simulation arrival framing by loading scene with journey arrival yaw/pitch/hfov.
- [x] Fix simulation crossfade override by correcting DOM transition style binding to write `style.transition`.
- [x] Validate with `npm run res:build` and `cd backend && cargo check`.
- [x] Patch headless teaser capture to crop frames to `#viewer-stage` only (exclude sidebar/browser chrome).
- [x] Add headless capture UI mode to hide viewer overlays and keep logo visible during teaser recording.
- [x] Harden hydration URL normalization so absolute `/api/...` scene URLs resolve against backend origin.
- [x] Wire teaser generation into `OperationLifecycle` so sidebar progress/cancel UX is consistently visible.

## Code Change Ledger
- [x] `backend/src/api/media/video_logic_support.rs` - add robust headless loader fallback (`__VTB_LOAD_PROJECT__` or `window.store.loadProject`) and configurable `headless_app_origin`.
- [x] `backend/src/api/media/video_logic.rs` - navigate to configurable app origin with fallback; robust teaser-start function script fallback chain.
- [x] `src/App.res` - register production-safe global project loader `window.__VTB_LOAD_PROJECT__`.
- [x] `src/systems/TeaserLogic.res` - expose stable `window.__VTB_START_TEASER__` alias.
- [x] `src/systems/Navigation/NavigationGraph.res` - force simulation arrival target to centered passed yaw/pitch instead of intro-pan offset.
- [x] `src/systems/Scene/SceneTransition.res` - enforce visible 1s crossfade for simulation `Link` transitions.
- [x] `backend/src/api/media/video.rs` - extract incoming auth token/cookie from teaser request and forward it into headless generation.
- [x] `backend/src/api/media/video_logic.rs` - accept forwarded auth token and prefer it over env-only headless token.
- [x] `src/systems/Simulation/SimulationMainLogic.res` - compute simulation arrival framing from target-scene waypoint start (not source-scene fallback).
- [x] `src/systems/Scene/SceneTransition.res` - broaden simulation crossfade override to all non-cut transitions (not only `Link` tag).
- [x] `src/systems/ServerTeaser.res` - send `Authorization` header (with debug fallback token) and sync auth cookie during teaser request.
- [x] `backend/src/api/media/video_logic_support.rs` - resolve hydration URLs from `scene.file/originalFile/tinyFile` before fallback name path.
- [x] `backend/src/api/media/video_logic_support.rs` - prefer system `ffmpeg` (or `FFMPEG_PATH`) before local bundled binary.
- [x] `src/systems/SceneLoaderLogic.res` - inject journey arrival yaw/pitch/hfov into scene config so simulation lands centered.
- [x] `src/bindings/DomBindings.res` - fix `setTransition` / `setBackgroundImage` bindings to target `style.*`.
- [x] `backend/src/api/media/video_logic.rs` - enforce capture mode (logo-only HUD) and crop screenshots to `#viewer-stage` viewport.
- [x] `backend/src/api/media/video_logic_support.rs` - normalize absolute API URLs to backend origin before hydration fetch.
- [x] `src/systems/OperationLifecycle.res` - add `Teaser` operation type with visibility threshold.
- [x] `src/components/Sidebar/UseSidebarProcessing.res` - mark `Teaser` as critical progress type for processing panel visibility.
- [x] `src/systems/TeaserLogic.res` - register teaser lifecycle operation, progress, completion/failure/cancel wiring.
- [x] `src/components/Sidebar.res` - pass teaser cancel callback through to headless teaser logic.

## Rollback Check
- [x] Confirmed non-working iterations were replaced by validated working fixes (no extra debug artifacts kept).

## Context Handoff
Teaser 500 root cause chain was reproduced with `x445.zip`: missing auth header (`401`), then incorrect file URL fallback (`404`), then stale local ffmpeg binary dependency failure. All three were patched and teaser now returns `200` in the same `x445.zip` flow. Simulation now loads each scene at computed arrival yaw/pitch and applies a 1s opacity crossfade via corrected DOM style binding.
