# T1914 Troubleshoot Remote Builder Upload Stuck At Zero

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [x] The upload stack still uses a localhost-targeted backend URL or health probe, so LAN clients can sign in but upload requests never leave the browser correctly.
  - [x] Worker-based validation/fingerprinting stalls before the first backend upload request is issued, leaving the UI at `0%`.
  - [x] A worker crash or unhandled worker error strands pending promises because the pool never invalidates or resolves waiters.
  - [x] A later worker-backed metadata stage such as EXIF extraction hangs without timeout and blocks upload completion.
  - [ ] Upload image compression still lacks a timeout-backed fallback, so the frontend never reaches the first `/api/media/process-full` request.
  - [x] Stale service-worker assets on the Mac are still serving outdated frontend code after `rubox` rebuilds.
  - [x] The worker pool still crashes immediately on the successful path; capture the actual `onerror` / `onmessageerror` details and fix the root cause so uploads stop depending on fallback execution.
  - [x] The backend serves `/workers/image-worker.js` through the SPA fallback (`index.html`) instead of the actual worker file, so worker startup fails before any task can run.

- [ ] **Activity Log**
  - [x] Confirmed the LAN-served builder is reachable and healthy on `rubox`.
  - [x] Inspected frontend upload API/client code for hardcoded localhost or same-machine assumptions.
  - [x] Inspected remote backend logs and live requests while reproducing the stuck upload state.
  - [x] Confirmed no upload API requests were reaching the backend during the stuck `0%` state.
  - [x] Added worker timeouts and fallback logging for upload validation and fingerprinting.
  - [x] Added worker-pool invalidation so worker crashes resolve pending requests instead of hanging indefinitely.
  - [x] Added timeout-backed fallback for worker EXIF extraction.
  - [x] Rebuilt locally and redeployed the patched build to `rubox` for retest.
  - [x] Confirmed later failing runs reach `/api/media/extract-metadata` but never start `/api/media/process-full`, narrowing the break to frontend preprocessing.
  - [x] Fixed the service worker to use network-first fetch for non-immutable assets so rebuilt frontend bundles are not served stale forever.
  - [x] Added timeout-backed fallback for upload image compression and explicit upload-handoff logging before `/api/media/process-full`.
  - [x] Rebuild locally, redeploy the newest frontend to `rubox`, and re-verify upload progress remotely from the Mac.
  - [x] Polished the non-secure LAN fingerprint path so the app skips the doomed worker fingerprint attempt and emits one clear weak-fingerprint warning instead of spamming per-file fallback logs.

- [ ] **Code Change Ledger**
  - [x] `src/systems/ImageValidator.res` — add worker timeout and explicit validation fallback logging. Revert if the stall is proven backend-side instead.
  - [x] `src/systems/FingerprintService.res` — add worker timeout and checksum fallback logging. Revert if fingerprinting is not on the stuck path.
  - [x] `src/systems/ExifParser.res` — add timeout-backed EXIF worker fallback for later upload stages. Revert if worker EXIF is proven safe.
  - [x] `src/utils/ImageOptimizer.res` — add upload compression worker timeout so the main preprocessing step can fall back instead of stalling before `process-full`. Revert only if timeout false-positives on healthy uploads.
  - [x] `src/systems/Resizer/ResizerLogic.res` — log compression failure and `process-full` handoff/response so the next failure mode is observable. Revert if telemetry becomes too noisy after root cause is resolved.
  - [x] `src/utils/WorkerPool.res` — add timeout plumbing to worker request helpers. Revert surgically if request signatures destabilize call sites.
  - [x] `src/utils/WorkerPoolCore.res` — invalidate crashed worker pools and resolve pending waiters instead of hanging. Revert only if it causes false-positive pool resets.
  - [x] `src/utils/Constants.res` — add upload/EXIF/tiny/logo/upload-compression worker timeout constants. Revert only if timeout tuning proves too aggressive.
  - [x] `src/ServiceWorkerMain.res` — switch non-immutable cache handling to network-first with cache fallback so rebuilt local deployments do not stay stale in browser cache. Revert only if it causes unacceptable offline regressions.
  - [x] `src/utils/WorkerPoolCore.res` — capture richer worker crash details (`onerror` / `onmessageerror`) so the actual remote browser failure is visible instead of only pool invalidation. Revert if browser bindings prove incompatible.
  - [x] `backend/src/main.rs` — serve `/workers` from `../public/workers` instead of letting the SPA fallback return `index.html` for worker requests. Revert only if worker assets move into the dist root later.
  - [x] `src/systems/Resizer/ResizerUtils.res` / `src/systems/FingerprintService.res` / `src/systems/Resizer.res` — detect non-secure contexts up front, log the weak-fingerprint fallback once, and skip the guaranteed-to-fail worker fingerprint path on LAN HTTP.

- [ ] **Rollback Check**
  - [ ] Confirmed CLEAN or REVERTED non-working changes.

- [ ] **Context Handoff**
  - [x] `rubox` is serving the rebuilt builder on `http://192.168.1.186:8083/`, and sign-in from the Mac already works.
  - [x] Backend diagnostics now show `/api/media/extract-metadata` completing for large files, but still no `/api/media/process-full`, so the remaining failure is in frontend preprocessing or stale frontend assets.
  - [x] The latest local patch adds a timeout-backed fallback for upload compression plus explicit `BACKEND_PROCESS_FULL_UPLOAD_*` logs in the handoff path.
  - [x] The next session should rebuild locally, redeploy to `rubox`, restart on `8083`, then retest from the Mac after a service-worker unregister or hard refresh if stale assets are still suspected.
  - [x] Upload now succeeds on the remote path, but only through validation/fingerprint/compression fallbacks because the worker pool still invalidates immediately.
  - [x] The immediate worker invalidation root cause is now identified: `/workers/image-worker.js` was returning `index.html` with `text/html`, so the browser never started the worker script.
  - [x] The next session should capture the actual worker error payload on the successful path and then fix the root cause so the fast path works normally.
