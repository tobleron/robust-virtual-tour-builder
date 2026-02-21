# T1508 - Troubleshoot Export Stuck At 95%

## Objective
Identify and fix the regression where export progress stalls around 95% and does not complete.

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] H1: Backend packager is blocked waiting on a missing/invalid HTML field or path rewrite edge case after recent export topology changes.
  - [x] H2: Frontend export upload flow awaits a terminal response shape that is no longer produced by backend, leaving UI progress pinned at 95%.
  - [ ] H3: Mobile/web package asset write paths are valid individually but one failing write aborts silently and prevents final response.
  - [ ] H4: Cancellation/progress lifecycle integration leaves operation active even after backend completion due to missing completion dispatch.
  - [x] H5: Client timeout/retry policy is shorter than real x700 export processing time, causing abort+retry loops that look like a permanent 95% stall.
  - [x] H6: Exported tours opened via `file://` fail in browser due Pannellum XHR CORS restrictions, even when assets are present.

- [ ] **Activity Log**
  - [x] Read `MAP.md` for architecture context.
  - [x] Read `DATA_FLOW.md` export flow context.
  - [x] Read `tasks/TASKS.md` workflow constraints.
  - [x] Applied user-requested mobile export quality update (`50 -> 65`) while troubleshooting path remains active.
  - [x] Traced frontend export progress transitions and terminal conditions (`Exporter.res` + `ExporterUpload.res`).
  - [x] Traced backend export response lifecycle (`api/project.rs::create_tour_package` + package writer).
  - [x] Implemented targeted fix for XHR terminal-state robustness at 95% boundary.
  - [x] Verified with `npx vitest run tests/unit/Exporter_v.test.bs.js` and `cd backend && cargo check -q`.
  - [x] Reproduced with real x700 flow: first request aborted at ~306s with `net::ERR_ABORTED`, then auto-retry restarted export and pinned at 95% again.
  - [x] Implemented timeout/retry fix: increased client export timeout and disabled timeout-triggered retries.
  - [x] Optimized backend packaging: removed redundant second decode/resize pass for mobile HD artifacts (reuse HD resize output).
  - [x] Verified with real x700 export smoke test in UI automation:
    - single request (no retry loop),
    - HTTP 200,
    - download received,
    - request duration ~533.6s.
  - [x] Added adaptive export sizing + WebP passthrough path:
    - preserve aspect ratio,
    - avoid upscaling,
    - reuse source bytes when already WebP and already at target dimensions.
  - [x] Re-benchmarked with real x700 export after adaptive optimization:
    - single request (no retry loop),
    - HTTP 200,
    - download received,
    - request duration ~158.1s (down from ~533.6s).
  - [x] Reproduced user-reported export runtime failure with a minimal local file harness:
    - `file://` load triggers Pannellum XHR CORS block (`origin null`) and file-access popup.
  - [x] Verified direct `<img src=\"...\">` local file loading succeeds while `fetch`/XHR fail under `file://`, confirming protocol restriction rather than missing file assets.
  - [x] Tested a temporary local patch against vendored `pannellum.js` to bypass XHR under `file://`; reverted after confirming WebGL taint/security constraints still block reliable rendering.
  - [x] Implemented export runtime guard in generated tour HTML:
    - detects `file://`,
    - blocks Pannellum init,
    - shows explicit local-server instructions overlay instead of opaque runtime error.
  - [x] Updated root package launcher copy to state HTTP/HTTPS requirement explicitly.

- [ ] **Code Change Ledger**
  - [x] `backend/src/services/project/package.rs`: Set `MOBILE_HD_WEBP_QUALITY` to `65.0`; updated mobile index copy + inline comment from quality 50 to 65. Revert by restoring `50.0` and associated text.
  - [x] `backend/src/services/project/package.rs`: Optimized export processing by generating mobile HD bytes from the same decoded image + HD resize pass; removed separate `mobile_hd_assets` decode/resize traversal.
  - [x] `backend/src/services/project/package.rs`: Added `target_dimensions` adaptive sizing helper; switched export generation to aspect-preserving, no-upscale target dimensions; added passthrough for source WebP when target dimensions match source dimensions.
  - [x] `src/systems/Exporter/ExporterUpload.res`: Added guarded `emitProgress` callback, terminal `onloadend` fallback, and `onabort` handling to prevent unresolved promises when progress callbacks throw. Revert by restoring direct `onProgress(...)` calls and removing the new fallback handlers.
  - [x] `src/systems/Exporter/ExporterUpload.res`: Added `timeoutMs` parameter and switched XHR timeout to centralized constant.
  - [x] `src/systems/Exporter.res`: Wired `Constants.Exporter.uploadTimeoutMs` into upload call and blocked retries on timeout errors to avoid restart loops.
  - [x] `src/utils/Constants.res`: Added `Exporter.uploadTimeoutMs` (30s in test, 12m in dev/prod).
  - [x] `tests/unit/Exporter_v.test.res`: Added regression test `progress callback failure does not stall completion` to cover the 95%-boundary callback-failure case.
  - [x] `src/systems/TourTemplates.res`: Added `file://` runtime guard for exported tours that shows a local-server guidance overlay and skips viewer boot in unsupported protocol mode.
  - [x] `backend/src/services/project/package.rs`: Updated root export launcher copy to explicitly indicate HTTP/HTTPS-only runtime expectation.
  - [x] `public/libs/pannellum.js`: Temporary troubleshooting experiment to bypass `file://` XHR was reverted in the same session after validation (no net code change retained).

- [ ] **Rollback Check**
  - [ ] Confirmed CLEAN or REVERTED non-working troubleshooting edits.

- [ ] **Context Handoff**
  - [x] Added frontend export transport hardening so progress-callback exceptions cannot block XHR completion at the 95% transition.
  - [x] Mobile HD export profile updated to WebP quality 65 and backend compiles with this setting.
  - [x] Root cause for x700 “stuck at 95%” was confirmed as timeout mismatch + retry loop, not a deadlocked response handler.
  - [x] Real x700 end-to-end verification now succeeds with a single request and download completion; processing time is still long (~8m54s), so UX should continue to communicate long-running backend work clearly.
  - [x] After adaptive export optimization, real x700 completion improved to ~2m38s request time in local repro while still producing successful package output.
  - [x] Local file launch failures are caused by browser protocol security (`file://` + Pannellum XHR), so exported tours now display explicit local-server instructions instead of an opaque loader error.
